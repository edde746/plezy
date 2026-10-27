#!/usr/bin/env python3
# /// script
# requires-python = ">=3.12,<3.14"
# dependencies = ["numpy==2.5.4", "scikit-learn==1.9.1", "scipy==1.18.1"]
# ///
"""Train the chapter intro/credits classifier behind PlaybackExtras.withChapterFallback.

The classifier marks at most one intro and one credits chapter per item from the chapter list alone: titles plus
start/end times. No audio, video, server markers, or sibling episodes. It is a boosted-tree ensemble over 48
per-chapter features (timing, title shape, the neighbours' title keywords, and a 24-number title embedding).
lib/media/chapter_marker_classifier.dart reimplements the features and the tree walk; keep the two in sync.

Outputs (both committed; do not edit by hand):
  assets/chapter_marker_model.bin              the trained model: the raw bytes `serialize` writes
  test/media/chapter_marker_model_cases.dart   synthetic inputs with this script's probabilities, so the Dart port
                                                is checked against the reference implementation

Training data is a JSON list of items, one per episode/movie, with every chapter Plex or Jellyfin reports:
  {"show": "Show or movie title", "type": "episode" | "movie", "chapters": [{"t": title, "s": start_ms, "e": end_ms}]}
Library data is not committed; fetch it from your own servers:

  PLEX_TOKEN=... uv run scripts/codegen/train_chapter_marker_model.py fetch --plex http://host:32400 -o plex.json
  JELLYFIN_USER=... JELLYFIN_PASSWORD=... uv run scripts/codegen/train_chapter_marker_model.py fetch \\
      --jellyfin http://host:8096 -o jellyfin.json
  uv run scripts/codegen/train_chapter_marker_model.py evaluate plex.json jellyfin.json
  uv run scripts/codegen/train_chapter_marker_model.py train plex.json jellyfin.json

Labels come from chapter titles (a curated vocabulary plus two release-group context rules), so only items with at
least one non-generic title are trained on. During training some items are repeated with every title replaced by
"Chapter N"/empty, or with the intro/credits titles replaced by random strings, which teaches the model to use
timing when titles say nothing.

`evaluate` holds out whole shows (5-fold) and scores every (item, marker type) slot: +1 right (the right chapter,
or correctly no marker), 0 missed, -1 a wrong chapter marked. Score = 100 x mean, floored at 0. Columns: real
titles, the same items with generic titles, intro/credits titles renamed to random strings, and "overall" (real and
generic mixed in the dataset's share of generic-titled items).
"""

import argparse
import functools
import json
import math
import os
import random
import re
import struct
import subprocess
import sys
import time
import unicodedata
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

import numpy as np
import scipy.sparse as sp
from sklearn.decomposition import TruncatedSVD
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.model_selection import GroupKFold

ROOT = Path(__file__).resolve().parents[2]
MODEL_OUT = ROOT / "assets/chapter_marker_model.bin"
CASES_OUT = ROOT / "test/media/chapter_marker_model_cases.dart"

OTHER, INTRO, CREDITS = 0, 1, 2
SEED = 0

# ---------------------------------------------------------------------------------------------------------------
# Features. Mirrored by lib/media/chapter_marker_classifier.dart; any change here needs the same change there.
# ---------------------------------------------------------------------------------------------------------------

BUCKETS = 4096  # title n-gram hash buckets
EMBED_DIM = 24  # title embedding size
FEATURE_COUNT = 24 + EMBED_DIM

# Explicit lists so Python and Dart agree on what is whitespace and what is a digit.
_WHITESPACE = re.compile("[\t\n\v\f\r \u0085\u00a0\u1680\u2000-\u200a\u2028\u2029\u202f\u205f\u3000]+")
_FULLWIDTH = {c: c - 0xFEE0 for c in range(0xFF01, 0xFF5F)}
_DIGIT = re.compile("[0-9]")

# Today's default chapter-title patterns, rewritten for cleaned titles (lowercase, single spaces). re.A gives \b
# the ASCII semantics of Dart's RegExp.
INTRO_WORDS = re.compile(r"(?:^|\b)(?:intro(?:duction)?|opening)(?:\b|$)|^op(?: ?[0-9]+)?$", re.A)
CREDITS_WORDS = re.compile(r"(?:^|\b)(?:outro|credits?|ending)(?:\b|$)|^ed(?: ?[0-9]+)?$", re.A)
_GW = r"(?:(?:chapter|chapitre|kapitel|cap[ií]tulo|capitolo|hoofdstuk|глава|チャプター|scene|part) ?[#\-_.]? ?)?"
GENERIC_TITLE = re.compile(
    r"^" + _GW + r"[0-9]+(?: " + _GW + r"[0-9]+)*$"
    r"|^(?:\([0-9]+\))? ?[0-9]{1,2}:[0-9]{2}(?::[0-9]{2})?(?:[.,:][0-9]+)?$"
    r"|^\(unnamed scene\)$|^(?:chapter)?$",
    re.A,
)

LOG_HOUR = math.log(3600)
LOG_4_HOURS = math.log(4 * 3600)


def clean_title(title):
    """Fullwidth ASCII to ASCII, whitespace runs to one space, trimmed, lowercase."""
    t = (title or "").translate(_FULLWIDTH)
    return _WHITESPACE.sub(" ", t).strip(" ").lower()


def fnv1a(text):
    h = 0x811C9DC5
    for b in text.encode("utf-8", "replace"):
        h = ((h ^ b) * 0x01000193) & 0xFFFFFFFF
    return h


@functools.lru_cache(maxsize=None)
def title_buckets(cleaned):
    """Counts of hashed 1-3 character n-grams of each space-padded word, digits folded to 0."""
    counts = {}
    for word in _DIGIT.sub("0", cleaned).split(" "):
        if not word:
            continue
        padded = " " + word + " "
        for n in (1, 2, 3):
            for i in range(len(padded) - n + 1):
                b = fnv1a(padded[i : i + n]) % BUCKETS
                counts[b] = counts.get(b, 0) + 1
    return counts


@functools.lru_cache(maxsize=None)
def title_keywords(cleaned):
    return (float(bool(INTRO_WORDS.search(cleaned))), float(bool(CREDITS_WORDS.search(cleaned))))


class Embedding:
    """Title n-gram counts -> idf weights -> L2 normalize -> int8-quantized SVD projection."""

    def __init__(self, idf, scale, table):
        self.idf, self.scale, self.table = idf, scale, table  # (B,) f32-exact f64, (E,) f64, (B, E) int8
        self.projection = table.astype(np.float64) * scale

    @staticmethod
    def fit(cleaned_titles):
        counts = count_matrix(cleaned_titles)
        df = np.asarray((counts > 0).sum(axis=0)).ravel()
        idf = (np.log((1 + counts.shape[0]) / (1 + df)) + 1).astype(np.float32).astype(np.float64)
        svd = TruncatedSVD(EMBED_DIM, random_state=SEED).fit(_weighted(counts, idf))
        components = svd.components_.T
        scale = np.abs(components).max(axis=0) / 127
        table = np.clip(np.round(components / scale), -127, 127).astype(np.int8)
        return Embedding(idf, scale, table)

    def transform(self, cleaned_titles):
        return np.asarray(_weighted(count_matrix(cleaned_titles), self.idf) @ self.projection)


def count_matrix(cleaned_titles):
    rows, cols, vals = [], [], []
    for r, t in enumerate(cleaned_titles):
        for b, c in title_buckets(t).items():
            rows.append(r); cols.append(b); vals.append(c)
    return sp.csr_matrix((vals, (rows, cols)), shape=(len(cleaned_titles), BUCKETS), dtype=np.float64)


def _weighted(counts, idf):
    w = sp.csr_matrix(counts.multiply(idf.reshape(1, -1)))
    norms = np.sqrt(np.asarray(w.multiply(w).sum(axis=1)).ravel())
    norms[norms == 0] = 1
    return sp.csr_matrix(sp.diags(1 / norms) @ w)


def features(chapters, embedding):
    """chapters: [(title, start_ms, end_ms)] with end >= start. Returns (n, FEATURE_COUNT), float32 values.

    Frequent titles and durations repeat exactly, so split thresholds can sit exactly on a feature value. Rounding
    to float32 absorbs the last-bit differences between NumPy's and Dart's arithmetic (and between platforms' log)
    that would otherwise send such a value down the other branch.
    """
    n = len(chapters)
    runtime = max(max(e for _, _, e in chapters), 1)
    titles = [clean_title(t) for t, _, _ in chapters]
    keywords = [title_keywords(t) for t in titles]
    emb = embedding.transform(titles)
    durations = [(e - s) / 1000 for _, s, e in chapters]
    out = np.empty((n, FEATURE_COUNT))
    for i, (_, s, e) in enumerate(chapters):
        d, t = durations[i], titles[i]
        out[i, :24] = [
            s / runtime,
            e / runtime,
            (e - s) / runtime,
            math.log(1 + d) / LOG_HOUR,
            min(s / 1000, 900) / 900,
            min((runtime - e) / 1000, 900) / 900,
            min(abs(d - 90), 300) / 300,
            i / max(n - 1, 1),
            float(i == 0),
            float(i == n - 1),
            min(n, 40) / 40,
            math.log(1 + runtime / 1000) / LOG_4_HOURS,
            float(84 <= d <= 96),
            min(durations[i - 1], 900) / 900 if i > 0 else -1.0,
            min(durations[i + 1], 900) / 900 if i + 1 < n else -1.0,
            float(bool(GENERIC_TITLE.match(t))),
            float(t == ""),
            *keywords[i],
            *(keywords[i - 1] if i > 0 else (-1.0, -1.0)),
            *(keywords[i + 1] if i + 1 < n else (-1.0, -1.0)),
            len(t) / 40,
        ]
        out[i, 24:] = emb[i]
    return out.astype(np.float32).astype(np.float64)


# Product rules shared by the labels and the picker: a marker under 5 s is noise, and an "intro" chapter over
# 3 minutes is picture (a movie's "Opening Credits" scene, #2235).
MIN_MARKER_MS = 5_000
MAX_INTRO_MS = 180_000
THRESHOLD = 0.8


def pick(probs, chapters):
    """At most one intro and one credits chapter: the most probable one per type, if it clears THRESHOLD."""
    p = probs.copy()
    for i, (_, s, e) in enumerate(chapters):
        if e - s < MIN_MARKER_MS:
            p[i, 1:] = 0
        elif e - s > MAX_INTRO_MS:
            p[i, INTRO] = 0
    picks = [OTHER] * len(chapters)
    for cls in (INTRO, CREDITS):
        i = int(np.argmax(p[:, cls]))
        if p[i, cls] >= THRESHOLD and picks[i] == OTHER:
            picks[i] = cls
    return picks


def shipped_picks(probs, chapters):
    """pick() plus PlaybackExtras' rule for every chapter-derived credits marker: start in the last quarter (#2734)."""
    runtime = max(e for _, _, e in chapters)
    return [OTHER if p == CREDITS and chapters[i][1] < 0.75 * runtime else p for i, p in enumerate(pick(probs, chapters))]


# ---------------------------------------------------------------------------------------------------------------
# Labels (training only): curated title vocabulary plus release-group context rules.
# ---------------------------------------------------------------------------------------------------------------

_N = r"(?:\s*\d+)?"
LABEL_INTRO = re.compile(
    r"^(?:op|opening|intro|introduction|nf intro|series intro|title sequence|opening credits|opencreditstart|doep"
    r"|theme song)" + _N + r"$"
    r"|^opening\s*[:(（\-]|^op\s*[:(（\-](?!\s*insert)|^abertura\b|^op\s*\+\s*(?:cast|scene)$",
    re.I,
)
LABEL_CREDITS = re.compile(
    r"^(?:ed|ending|credits?|outro|end credits|closing credits|nf credits|credits start|edeer|staff roll)" + _N + r"$"
    r"|^ending\s*[:(（\-]|^ed\s*[:(（\-]|^encerramento\b|^ed\s*\+\s*(?:cast|scene|extra)$|^\d+\s*:\s*credits$",
    re.I,
)
GENERIC_INTRO_WORD = re.compile(r"^(?:intro|introduction|nf intro|series intro)$", re.I)
EXPLICIT_OP = re.compile(r"^(?:op|opening)(?:\s*\d+)?$|^opening\s*[:(（\-]|^op\s*\+", re.I)
EXPLICIT_ED = re.compile(r"^(?:ed|ending)(?:\s*\d+)?$|^ending\s*[:(（\-]|^ed\s*\+", re.I)


def labels(chapters):
    low = [unicodedata.normalize("NFKC", t or "").strip().lower() for t, _, _ in chapters]
    lab = [INTRO if LABEL_INTRO.search(t) else CREDITS if LABEL_CREDITS.search(t) else OTHER for t in low]
    for i, t in enumerate(low):
        # Release groups that call the cold open "Intro" put an explicit OP after it.
        if lab[i] == INTRO and GENERIC_INTRO_WORD.match(t) and any(EXPLICIT_OP.search(u) for u in low[i + 1 :]):
            lab[i] = OTHER
        # The same groups call the post-ED epilogue "Outro".
        if lab[i] == CREDITS and t == "outro" and any(EXPLICIT_ED.search(u) for u in low[:i]):
            lab[i] = OTHER
    for i, (_, s, e) in enumerate(chapters):
        if e - s < MIN_MARKER_MS:
            lab[i] = OTHER
        elif lab[i] == INTRO and e - s > MAX_INTRO_MS:
            lab[i] = OTHER
    return lab


# ---------------------------------------------------------------------------------------------------------------
# Dataset
# ---------------------------------------------------------------------------------------------------------------


def show_key(show):
    return re.sub(r"[^\w]+", "", unicodedata.normalize("NFKC", show or "").lower())


def load(paths):
    items = []
    for path in paths:
        for row in json.loads(Path(path).read_text(encoding="utf-8")):
            chapters = [
                (c.get("t"), int(c["s"]), int(c["e"]))
                for c in row["chapters"]
                if c.get("s") is not None and c.get("e") is not None and c["e"] >= c["s"]
            ]
            if not chapters:
                continue
            named = not all(GENERIC_TITLE.match(clean_title(t)) for t, _, _ in chapters)
            items.append({
                **row,
                "chapters": chapters,
                "group": show_key(row["show"]),
                "named": named,
                "gold": labels(chapters) if named else None,
            })
    return items


def _synthetic_title(rng):
    """An unfamiliar title standing in for per-show OP/ED names (song titles, puns, other languages)."""
    word = lambda: "".join(rng.choice("abcdefghijklmnopqrstuvwxyz") for _ in range(rng.randint(3, 9)))
    k = rng.randrange(4)
    if k == 0:
        return word().capitalize()
    if k == 1:
        return f"{word().capitalize()} - 「{word()} {word()}」"
    if k == 2:
        return "".join(chr(rng.randint(0x30A1, 0x30F6)) for _ in range(rng.randint(2, 6)))
    return f"{word().capitalize()} {word()}"


SYNTHETIC_TITLES = [_synthetic_title(random.Random(i)) for i in range(20_000)]


def retitled(item, variant):
    """variant: None (real titles) | ("mask", style) | ("rename", seed) intro/credits titles | ("random", seed)."""
    if variant is None:
        return item["chapters"]
    kind, arg = variant
    if kind == "mask":
        title = lambda i: f"Chapter {i + 1}" if arg == 0 else f"Chapter {i + 1:02d}" if arg == 1 else ""
        return [(title(i), s, e) for i, (_, s, e) in enumerate(item["chapters"])]
    rng = random.Random(arg)
    draw = lambda: SYNTHETIC_TITLES[rng.randrange(len(SYNTHETIC_TITLES))]
    if kind == "rename":
        return [(draw() if g else t, s, e) for (t, s, e), g in zip(item["chapters"], item["gold"])]
    return [(draw(), s, e) for _, s, e in item["chapters"]]


def training_variant(rng):
    r = rng.random()
    if r < 0.3:
        return ("mask", rng.randrange(3))
    if r < 0.45:
        return ("rename", rng.getrandbits(32))
    if r < 0.5:
        return ("random", rng.getrandbits(32))
    return None


# ---------------------------------------------------------------------------------------------------------------
# Model
# ---------------------------------------------------------------------------------------------------------------

TREE_PARAMS = dict(max_iter=400, learning_rate=0.06, max_leaf_nodes=31)


class Model:
    def __init__(self, embedding, trees):
        self.embedding, self.trees = embedding, trees

    @staticmethod
    def fit(items):
        embedding = Embedding.fit([clean_title(t) for it in items for t, _, _ in it["chapters"]])
        rng = random.Random(SEED)
        xs, ys = [], []
        for it in items:
            for variant in {None, training_variant(rng)}:
                xs.append(features(retitled(it, variant), embedding))
                ys.append(it["gold"])
        trees = HistGradientBoostingClassifier(**TREE_PARAMS, random_state=SEED)
        trees.fit(np.vstack(xs), np.concatenate(ys))
        return Model(embedding, trees)

    def probabilities(self, chapters):
        return self.trees.predict_proba(features(chapters, self.embedding))


class ExportedTrees:
    """The ensemble as serialized: f64 thresholds, f32 leaves, pre-order nodes. Evaluates like the Dart port."""

    def __init__(self, trees):
        self.classes = trees.n_trees_per_iteration_
        self.baseline = np.asarray(trees._baseline_prediction, dtype=np.float64).ravel()
        thresholds = [set() for _ in range(FEATURE_COUNT)]
        for iteration in trees._predictors:
            for predictor in iteration:
                for node in predictor.nodes:
                    if not node["is_leaf"]:
                        thresholds[node["feature_idx"]].add(float(node["num_threshold"]))
        self.thresholds = [sorted(t) for t in thresholds]
        assert all(len(t) < 256 for t in self.thresholds)
        self.trees = [self._flatten(p.nodes) for iteration in trees._predictors for p in iteration]

    def _flatten(self, nodes):
        out = []  # (feature or 255, threshold index, right child index, leaf value)

        def visit(i):
            node = nodes[i]
            if node["is_leaf"]:
                out.append((255, 0, 0, float(np.float32(node["value"]))))
                return
            assert not node["is_categorical"]
            at = len(out)
            out.append(None)
            visit(node["left"])
            right = len(out)
            visit(node["right"])
            feature = int(node["feature_idx"])
            out[at] = (feature, self.thresholds[feature].index(float(node["num_threshold"])), right, 0.0)

        visit(0)
        assert len(out) < 65536
        return out

    def node_count(self):
        return sum(len(t) for t in self.trees)

    def raw(self, x):
        """x: (n, FEATURE_COUNT). Vectorized tree walk, summed in tree order like the Dart loop."""
        raw = np.tile(self.baseline, (len(x), 1))
        rows = np.arange(len(x))
        for t, nodes in enumerate(self.trees):
            feature = np.array([n[0] for n in nodes])
            threshold = np.array([self.thresholds[n[0]][n[1]] if n[0] != 255 else 0.0 for n in nodes])
            right = np.array([n[2] for n in nodes])
            value = np.array([n[3] for n in nodes])
            at = np.zeros(len(x), dtype=np.int64)
            while True:
                f = feature[at]
                split = f != 255
                if not split.any():
                    break
                left = x[rows, np.where(split, f, 0)] <= threshold[at]
                at = np.where(split, np.where(left, at + 1, right[at]), at)
            raw[:, t % self.classes] += value[at]
        return raw

    def probabilities(self, x):
        raw = self.raw(x)
        e = np.exp(raw - raw.max(axis=1, keepdims=True))
        return e / e.sum(axis=1, keepdims=True)


def serialize(embedding, exported):
    """Little-endian layout read by ChapterMarkerClassifier.decode."""
    b = bytearray(b"PCM2")
    b += struct.pack("<HIBB", FEATURE_COUNT, BUCKETS, EMBED_DIM, exported.classes)
    b += struct.pack(f"<{exported.classes}d", *exported.baseline)
    b += struct.pack(f"<{EMBED_DIM}d", *embedding.scale)
    b += embedding.idf.astype("<f4").tobytes()
    # Most buckets' projection rows quantize to all zeros (or never occur in training titles), and a zero row adds
    # nothing to the embedding: a bitmap of the non-zero rows, then just those rows, bucket-major. The idf stays
    # dense, because every bucket in a title counts towards its L2 norm.
    table = embedding.table.astype(np.int8)
    present = table.any(axis=1)
    b += np.packbits(present, bitorder="little").tobytes()
    b += table[present].tobytes()
    for t in exported.thresholds:
        b += struct.pack(f"<B{len(t)}d", len(t), *t)
    b += struct.pack("<HI", len(exported.trees), exported.node_count())
    for nodes in exported.trees:
        b += struct.pack("<H", len(nodes))
        for feature, threshold, right, value in nodes:
            b += struct.pack("<Bf", 255, value) if feature == 255 else struct.pack("<BBH", feature, threshold, right)
    return bytes(b)


# ---------------------------------------------------------------------------------------------------------------
# Evaluation
# ---------------------------------------------------------------------------------------------------------------


def slot_scores(picks, gold):
    out = []
    for cls in (INTRO, CREDITS):
        p = {i for i, x in enumerate(picks) if x == cls}
        g = {i for i, x in enumerate(gold) if x == cls}
        out.append(1 if (p and p <= g) or (not p and not g) else 0 if not p else -1)
    return out


VIEWS = ("real", "generic", "renamed")


def cross_validate(items):
    """Yields (item, view, chapters, probabilities) for every titled item, predicted with its show held out."""
    named = [it for it in items if it["named"]]
    groups = np.array([it["group"] for it in named])
    t0 = time.time()
    for fold, (train, test) in enumerate(GroupKFold(n_splits=5).split(named, groups=groups)):
        model = Model.fit([named[i] for i in train])
        cases = []
        for j, i in enumerate(test):
            variants = (None, ("mask", j % 3), ("rename", 10_000 * fold + j))
            cases += [(named[i], view, retitled(named[i], v)) for view, v in zip(VIEWS, variants)]
        x = [features(chapters, model.embedding) for _, _, chapters in cases]
        probs = np.split(model.trees.predict_proba(np.vstack(x)), np.cumsum([len(f) for f in x])[:-1])
        for (it, view, chapters), p in zip(cases, probs):
            yield it, view, chapters, p
        print(f"fold {fold} done {time.time() - t0:.0f}s", flush=True)


def evaluate(items):
    totals = {view: [0, 0] for view in VIEWS}
    for it, view, chapters, probs in cross_validate(items):
        for s in slot_scores(shipped_picks(probs, chapters), it["gold"]):
            totals[view][0] += s
            totals[view][1] += 1
    named = [it for it in items if it["named"]]
    generic_share = 1 - len(named) / len(items)
    score = {v: max(0.0, 100 * s / n) for v, (s, n) in totals.items()}
    score["overall"] = (1 - generic_share) * score["real"] + generic_share * score["generic"]
    shows = len({it["group"] for it in named})
    print(f"{len(items)} items, {len(named)} with titles, {shows} shows, generic share {generic_share:.3f}")
    print("  ".join(f"{k} {v:.1f}" for k, v in score.items()))
    return score


# ---------------------------------------------------------------------------------------------------------------
# Generated files
# ---------------------------------------------------------------------------------------------------------------

_CASE_TITLES = [
    "OP", "Opening", "ED", "Ending", "Intro", "Outro", "Credits", "End Credits", "Prologue", "Avant", "Part A",
    "Part B", "Episode", "Preview", "Next Episode", "Recap", "Eyecatch", "Chapter 1", "Chapter 07", "", "  ",
    "Opening Credits", "Title Sequence", "ＯＰ", "Ｅｎｄｉｎｇ", "オープニング", "エンディング", "Глава 3",
    "Capítulo 2", "Abertura - 「Saraba」", "OP2", "ED 1", "Opening: \"Sansan Days\"", "00:01:30.000", "(01)00:00:00",
    "(Unnamed Scene)", "The Gang Goes to the Jersey Shore", "Part 1", "Scene 4", "Ending\u00a0Theme", "OP\tTheme",
    "Post-Credits", "Introduction", "Staff Roll", "🎬 Opening 🎵", "Closing Day", "Main Episode", "Part C / Ending",
]


def _case_chapters(rng):
    n = rng.randint(1, 9)
    starts = sorted(rng.sample(range(1, 1_500_000), n - 1)) if n > 1 else []
    bounds = [0] + starts + [1_500_000 + rng.randint(0, 1_500_000)]
    if rng.random() < 0.5 and n >= 4:  # an anime-like layout with 90 s songs
        bounds = [0, 60_000, 150_000, 700_000, 1_300_000, 1_390_000, 1_420_000][: n + 1]
        n = len(bounds) - 1
    return [(rng.choice(_CASE_TITLES), bounds[i], bounds[i + 1]) for i in range(n)]


def write_outputs(model, items):
    exported = ExportedTrees(model.trees)
    data = serialize(model.embedding, exported)

    # The serialized ensemble must reproduce scikit-learn on everything it was trained on.
    checked = [retitled(it, variant) for it in items for variant in (None, ("mask", 0))]
    x = [features(chapters, model.embedding) for chapters in checked]
    ours, theirs = exported.probabilities(np.vstack(x)), model.trees.predict_proba(np.vstack(x))
    worst = float(np.abs(ours - theirs).max())
    bounds = np.cumsum([len(f) for f in x])[:-1]
    flips = sum(
        pick(o, chapters) != pick(t, chapters)
        for chapters, o, t in zip(checked, np.split(ours, bounds), np.split(theirs, bounds))
    )
    assert worst < 1e-5 and flips == 0, (worst, flips)

    named = [it for it in items if it["named"]]
    summary = (
        f"{len(named)} titled items from {len({it['group'] for it in named})} shows; {len(exported.trees)} trees, "
        f"{exported.node_count()} nodes, {len(data)} bytes"
    )
    MODEL_OUT.write_bytes(data)

    rng = random.Random(SEED)
    cases = [_case_chapters(rng) for _ in range(60)]
    cases.append([("Intro", 0, 4_000), ("Opening", 4_000, 94_000), ("Part A", 94_000, 1_200_000)])
    cases.append([("Opening Credits", 0, 480_000), ("Chapter 2", 480_000, 7_200_000)])
    body = []
    for chapters in cases:
        probs = exported.probabilities(features(chapters, model.embedding))
        spans = ", ".join(f"(title: {_dart_string(t)}, startMs: {s}, endMs: {e})" for t, s, e in chapters)
        rows = ", ".join("[" + ", ".join(repr(float(v)) for v in row) + "]" for row in probs)
        picks = pick(probs, chapters)
        intro = picks.index(INTRO) if INTRO in picks else None
        credits = picks.index(CREDITS) if CREDITS in picks else None
        body.append(
            f"  (spans: [{spans}], probabilities: [{rows}], intro: {_dart_value(intro)}, credits: {_dart_value(credits)}),"
        )
    CASES_OUT.write_text(
        "// Generated by scripts/codegen/train_chapter_marker_model.py; do not edit by hand.\n"
        "// Synthetic chapter lists with the reference implementation's probabilities and picks for\n"
        f"// assets/chapter_marker_model.bin: {summary}.\n\n"
        "import 'package:plezy/media/chapter_marker_classifier.dart';\n\n"
        "typedef ChapterMarkerModelCase = ({\n"
        "  List<ChapterSpan> spans,\n  List<List<double>> probabilities,\n  int? intro,\n  int? credits,\n});\n\n"
        "const chapterMarkerModelCases = <ChapterMarkerModelCase>[\n" + "\n".join(body) + "\n];\n",
        encoding="utf-8",
    )
    subprocess.run(["dart", "format", "--line-length", "120", str(CASES_OUT)], check=True)
    print(f"{summary}; max |p - sklearn| {worst:.1e}")


def _dart_string(s):
    if s is None:
        return "null"
    out = "".join(
        ch if 0x20 <= ord(ch) < 0x7F and ch not in "'\\$" else
        f"\\{ch}" if ch in "'\\$" else
        f"\\u{{{ord(ch):x}}}"
        for ch in s
    )
    return f"'{out}'"


def _dart_value(v):
    return "null" if v is None else str(v)


# ---------------------------------------------------------------------------------------------------------------
# Fetching chapter lists from your own servers
# ---------------------------------------------------------------------------------------------------------------


def _get_json(url, headers, data=None):
    req = urllib.request.Request(url, data=data, headers={"Accept": "application/json", **headers})
    with urllib.request.urlopen(req, timeout=60) as r:
        body = r.read()
    return json.loads(body) if body else None


def fetch_plex(base, token):
    headers = {"X-Plex-Token": token, "X-Plex-Client-Identifier": "plezy-chapter-model", "X-Plex-Product": "Plezy"}
    sections = _get_json(f"{base}/library/sections", headers)["MediaContainer"].get("Directory", [])
    keys = []
    for section in sections:
        kind = {"show": 4, "movie": 1}.get(section["type"])
        if kind is None:
            continue
        start = 0
        while True:
            q = f"type={kind}&X-Plex-Container-Start={start}&X-Plex-Container-Size=1000"
            mc = _get_json(f"{base}/library/sections/{section['key']}/all?{q}", headers)["MediaContainer"]
            keys += [m["ratingKey"] for m in mc.get("Metadata", [])]
            start += 1000
            if start >= mc.get("totalSize", 0):
                break

    def one(key):
        m = _get_json(f"{base}/library/metadata/{key}?includeChapters=1", headers)["MediaContainer"]["Metadata"][0]
        return {
            "show": m.get("grandparentTitle") if m["type"] == "episode" else m.get("title"),
            "type": "episode" if m["type"] == "episode" else "movie",
            "chapters": [
                {"t": c.get("tag"), "s": c.get("startTimeOffset"), "e": c.get("endTimeOffset")}
                for c in m.get("Chapter", [])
            ],
        }

    with ThreadPoolExecutor(6) as pool:  # gentle on the server
        return [r for r in pool.map(one, keys) if r["chapters"]]


def fetch_jellyfin(base, user, password):
    auth = 'MediaBrowser Client="Plezy", Device="chapter-model", DeviceId="plezy-chapter-model", Version="1"'
    login = _get_json(
        f"{base}/Users/AuthenticateByName",
        {"Content-Type": "application/json", "X-Emby-Authorization": auth},
        json.dumps({"Username": user, "Pw": password}).encode(),
    )
    headers = {"X-Emby-Authorization": f'{auth}, Token="{login["AccessToken"]}"'}
    try:
        q = urllib.parse.urlencode({
            "IncludeItemTypes": "Episode,Movie", "Recursive": "true", "Fields": "Chapters", "Limit": 100000,
        })
        items = _get_json(f"{base}/Users/{login['User']['Id']}/Items?{q}", headers)["Items"]
    finally:
        _get_json(f"{base}/Sessions/Logout", headers, b"")
    out = []
    for it in items:
        runtime = it.get("RunTimeTicks")
        starts = [(c.get("Name"), c["StartPositionTicks"] // 10_000) for c in it.get("Chapters") or []]
        ends = [s for _, s in starts[1:]] + [runtime // 10_000 if runtime else None]
        if starts:
            out.append({
                "show": it.get("SeriesName") if it["Type"] == "Episode" else it.get("Name"),
                "type": "episode" if it["Type"] == "Episode" else "movie",
                "chapters": [{"t": t, "s": s, "e": e} for (t, s), e in zip(starts, ends)],
            })
    return out


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    sub = parser.add_subparsers(dest="command", required=True)
    fetch = sub.add_parser("fetch", help="download chapter lists (PLEX_TOKEN / JELLYFIN_USER, JELLYFIN_PASSWORD)")
    fetch.add_argument("--plex", metavar="URL")
    fetch.add_argument("--jellyfin", metavar="URL", help="Jellyfin or Emby")
    fetch.add_argument("-o", "--output", required=True)
    for name in ("evaluate", "train"):
        sub.add_parser(name).add_argument("data", nargs="+", help="JSON files written by fetch")
    args = parser.parse_args()

    if args.command == "fetch":
        rows = []
        if args.plex:
            rows += fetch_plex(args.plex.rstrip("/"), os.environ["PLEX_TOKEN"])
        if args.jellyfin:
            rows += fetch_jellyfin(args.jellyfin.rstrip("/"), os.environ["JELLYFIN_USER"], os.environ["JELLYFIN_PASSWORD"])
        Path(args.output).write_text(json.dumps(rows, ensure_ascii=False), encoding="utf-8")
        print(f"{len(rows)} items with chapters -> {args.output}")
        return

    items = load(args.data)
    if args.command == "evaluate":
        evaluate(items)
    else:
        named = [it for it in items if it["named"]]
        write_outputs(Model.fit(named), named)


if __name__ == "__main__":
    sys.exit(main())
