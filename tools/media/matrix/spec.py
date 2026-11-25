"""What the playback matrix contains: one entry per file, each exercising one feature on top of the baseline
(H.264 8-bit 1080p SDR video with AAC 2.0 audio), plus one REMUX-style file with many tracks.

The build turns these entries into files, checks every file against its entry with ffprobe and writes the entries
(with sizes and hashes) to tools/media/matrix.json, which is what the engine slices read.
"""

from __future__ import annotations

import dataclasses

FPS_NUM, FPS_DEN = 24000, 1001

# Every generated clip marks each whole second with a 125 ms 1 kHz beep (the white "A/V sync" square in the picture
# lights for the same 125 ms). Tones identify the channels: one sine per channel, LFE at 55 Hz without the beep.
BEEP_HZ = 1000.0


@dataclasses.dataclass(frozen=True)
class Download:
    """A pinned third-party input: fetched once into the work directory and checked against sha256."""

    url: str
    sha256: str
    size: int
    origin: str
    terms: str


@dataclasses.dataclass(frozen=True)
class Audio:
    codec: str  # FFmpeg codec name: aac | truehd | ac3 | dts
    profile: str | None  # ffprobe's profile string, e.g. "LC", "DTS-HD MA"; None when ffprobe reports none
    layout: str  # FFmpeg channel layout: stereo | 5.1(side) | 7.1
    channels: int
    sample_rate: int
    bits: int | None  # bits_per_raw_sample for lossless codecs
    language: str  # BCP 47, what mpv reports as the track's `lang`
    language_legacy: str  # ISO 639-2 (Matroska `Language`), what FFmpeg reports
    title: str
    default: bool
    tones: tuple[float, ...] | None = None  # per channel, in layout order; None for a downloaded track
    bitrate: str | None = None  # for lossy encoders
    commentary: bool = False
    original: bool = False
    download: Download | None = None
    trim_seconds: float | None = None  # downloaded tracks: keep only the start (drops a truncated final frame)


@dataclasses.dataclass(frozen=True)
class Subtitle:
    codec: str  # FFmpeg codec name: ass | subrip | hdmv_pgs_subtitle
    source: str  # file under tools/media/matrix/subs/ (SRT for PGS; rendered by pgs.py)
    language: str
    language_legacy: str
    title: str
    default: bool
    forced: bool = False
    hearing_impaired: bool = False
    events: int = 0  # cues (PGS: display sets that show something)


@dataclasses.dataclass(frozen=True)
class Video:
    codec: str  # h264 | hevc | av1 | mpeg2video
    profile: str  # ffprobe's profile string
    signal: str  # pattern.Signal kind: sdr | hdr10 | dvp5
    width: int
    height: int
    bit_depth: int
    dovi: str | None = None  # "5" | "8.1"
    lines: tuple[str, ...] = ()
    chapter_label: bool = False  # the picture names the chapter playing (top right): screenshots show where it is
    grain: int = 0  # FFmpeg `noise` strength over the pattern, new every frame: film grain the encoder can't predict
    bitrate: str | None = None  # the encoder's target bitrate instead of its constant quality (with grain: a heavy file)

    @property
    def dynamic_range(self) -> str:
        if self.dovi:
            return "DOLBY_VISION"
        return "HDR10" if self.signal == "hdr10" else "SDR"


@dataclasses.dataclass(frozen=True)
class Clip:
    id: str
    exercises: str
    frames: int
    video: Video
    audio: tuple[Audio, ...]
    subtitles: tuple[Subtitle, ...] = ()
    chapters: tuple[tuple[float, str], ...] = ()

    @property
    def file(self) -> str:
        return f"{self.id}.mkv"

    @property
    def seconds(self) -> float:
        return self.frames * FPS_DEN / FPS_NUM


# Mastering display of every HDR clip: Display P3 primaries, D65, 1000 / 0.0001 cd/m² (the common HDR10 grade).
MASTERING = {
    "primaries": "P3-D65",
    "red": (0.680, 0.320),
    "green": (0.265, 0.690),
    "blue": (0.150, 0.060),
    "white": (0.3127, 0.3290),
    "maxLuminance": 1000.0,
    "minLuminance": 0.0001,
}

TONES_STEREO = (440.0, 660.0)
TONES_51 = (440.0, 554.37, 659.26, 55.0, 739.99, 880.0)  # FL FR FC LFE SL SR
TONES_51_LOW = (220.0, 277.18, 329.63, 55.0, 369.99, 440.0)
TONES_COMMENTARY = (300.0, 350.0)


def stereo(title="AAC 2.0 - tones L 440 Hz, R 660 Hz", language="en", legacy="eng", default=True,
           tones=TONES_STEREO, **kw) -> Audio:
    return Audio("aac", "LC", "stereo", 2, 48000, None, language, legacy, title, default, tones, "192k", **kw)


SDR_1080 = dict(codec="h264", profile="High", signal="sdr", width=1920, height=1080, bit_depth=8)

DTS_HD_MA_71 = Download(
    url="https://samples.ffmpeg.org/A-codecs/DTS/dts/Master%20Audio%207.1.dts",
    sha256="08b6289cceedadfd2e9e7be833e60bb8afd751564cf5e6543fecbc6a3a22f8d9",
    size=5_242_880,
    origin="FFmpeg samples archive (samples.ffmpeg.org, A-codecs/DTS/dts/), md5 2d19c669d727be1dcff8e02fa255ab4e "
    "as listed in its md5sum file. The file ends in a truncated frame, hence the trim.",
    terms="Published by the FFmpeg project for multimedia decoder testing; no explicit licence. Downloaded at build "
    "time, never committed; served on the local network for testing only.",
)

CLIPS: tuple[Clip, ...] = (
    Clip(
        id="h264-sdr",
        exercises="Baseline: H.264 High 8-bit 1080p SDR (BT.709) with AAC 2.0",
        frames=480,
        video=Video(**SDR_1080, lines=(
            "H.264 High, 8-bit, 1920x1080, 23.976 fps, SDR (BT.709)",
            "Audio: AAC 2.0. A beep at every whole second, with the white A/V sync square",
        )),
        audio=(stereo(),),
    ),
    Clip(
        id="hevc-hdr10",
        exercises="HEVC Main 10 2160p HDR10 with SMPTE ST 2086 mastering display and CTA-861.3 MaxCLL/MaxFALL",
        frames=480,
        video=Video("hevc", "Main 10", "hdr10", 3840, 2160, 10, lines=(
            "HEVC Main 10, 3840x2160, 23.976 fps, HDR10 (PQ, BT.2020)",
            "Mastering display P3-D65, 1000 / 0.0001 cd/m2; graphics white 203 cd/m2",
            "Audio: AAC 2.0",
        )),
        audio=(stereo(),),
    ),
    Clip(
        id="av1-hdr10",
        exercises="AV1 Main 10-bit 1080p HDR10 with mastering display and light level metadata OBUs",
        frames=480,
        video=Video("av1", "Main", "hdr10", 1920, 1080, 10, lines=(
            "AV1 Main, 10-bit, 1920x1080, 23.976 fps, HDR10 (PQ, BT.2020)",
            "Mastering display P3-D65, 1000 / 0.0001 cd/m2; graphics white 203 cd/m2",
            "Audio: AAC 2.0",
        )),
        audio=(stereo(),),
    ),
    Clip(
        id="av1-grain",
        exercises="AV1 Main 8-bit 1080p SDR at about 30 Mb/s of film grain: a hardware decoder at its real-time limit",
        frames=720,
        video=Video("av1", "Main", "sdr", 1920, 1080, 8, grain=24, bitrate="30M", lines=(
            "AV1 Main, 8-bit, 1920x1080, 23.976 fps, SDR (BT.709), about 30 Mb/s",
            "Heavy film grain over the whole picture, new in every frame",
            "Audio: AAC 2.0",
        )),
        audio=(stereo(),),
    ),
    Clip(
        id="mpeg2",
        exercises="MPEG-2 Main profile 1080p SDR, as broadcast HD and DVD remuxes carry it",
        frames=480,
        video=Video("mpeg2video", "Main", "sdr", 1920, 1080, 8, lines=(
            "MPEG-2 Main, 8-bit, 1920x1080, 23.976 fps, SDR (BT.709)",
            "Audio: AAC 2.0",
        )),
        audio=(stereo(),),
    ),
    Clip(
        id="dv-p5",
        exercises="Dolby Vision profile 5 (HEVC, IPTPQc2 base layer without HDR10 fallback, RPU in every frame)",
        frames=480,
        video=Video("hevc", "Main 10", "dvp5", 3840, 2160, 10, dovi="5", lines=(
            "HEVC Main 10, 3840x2160, 23.976 fps, Dolby Vision profile 5 (IPTPQc2)",
            "Correct only if every bar matches its label: the base layer is not Y'CbCr",
            "Audio: AAC 2.0",
        )),
        audio=(stereo(),),
    ),
    Clip(
        id="dv-p81",
        exercises="Dolby Vision profile 8.1 (HEVC, HDR10-compatible base layer, RPU in every frame)",
        frames=480,
        video=Video("hevc", "Main 10", "hdr10", 3840, 2160, 10, dovi="8.1", lines=(
            "HEVC Main 10, 3840x2160, 23.976 fps, Dolby Vision profile 8.1",
            "HDR10 base layer: players without Dolby Vision show it as HDR10",
            "Audio: AAC 2.0",
        )),
        audio=(stereo(),),
    ),
    Clip(
        id="dts-hdma",
        exercises="DTS-HD Master Audio 7.1 (24-bit, 48 kHz, lossless XLL with a DTS core)",
        frames=240,
        video=Video(**SDR_1080, lines=(
            "H.264 High, 8-bit, 1920x1080, 23.976 fps, SDR",
            "Audio: DTS-HD Master Audio 7.1, 24-bit 48 kHz (first 10 s of FFmpeg's",
            "'Master Audio 7.1.dts' sample)",
        )),
        audio=(Audio("dts", "DTS-HD MA", "7.1", 8, 48000, 24, "en", "eng", "DTS-HD MA 7.1", True,
                     download=DTS_HD_MA_71, trim_seconds=240 * FPS_DEN / FPS_NUM),),
    ),
    Clip(
        id="truehd",
        exercises="Dolby TrueHD 5.1 (24-bit, 48 kHz, lossless MLP)",
        frames=480,
        video=Video(**SDR_1080, lines=(
            "H.264 High, 8-bit, 1920x1080, 23.976 fps, SDR",
            "Audio: Dolby TrueHD 5.1, 24-bit 48 kHz",
            "Tones: L 440, R 554, C 659, LFE 55, Ls 740, Rs 880 Hz; beeps on all but LFE",
        )),
        audio=(Audio("truehd", None, "5.1(side)", 6, 48000, 24, "en", "eng", "TrueHD 5.1", True, TONES_51),),
    ),
    Clip(
        id="ass",
        exercises="ASS subtitles: styles, positioning, rotation, opaque box, move/fade, karaoke, blur, overlap",
        frames=480,
        video=Video(**SDR_1080, lines=(
            "H.264 High, 8-bit, 1920x1080, 23.976 fps, SDR; audio AAC 2.0",
            "Subtitles: ASS, 7 events from 00:01 to 00:19.5 (libass rendering)",
        )),
        audio=(stereo(),),
        subtitles=(Subtitle("ass", "styled.en.ass", "en", "eng", "English (ASS, styled)", True, events=7),),
    ),
    Clip(
        id="pgs",
        exercises="PGS (Blu-ray HDMV bitmap) subtitles on a 1920x1080 canvas",
        frames=480,
        video=Video(**SDR_1080, lines=(
            "H.264 High, 8-bit, 1920x1080, 23.976 fps, SDR; audio AAC 2.0",
            "Subtitles: PGS (bitmap), 5 cues from 00:01 to 00:19.5, bottom and top",
        )),
        audio=(stereo(),),
        subtitles=(Subtitle("hdmv_pgs_subtitle", "pgs.en.srt", "en", "eng", "English (PGS)", True, events=5),),
    ),
    Clip(
        id="h264-4x3",
        exercises="A 4:3 picture (H.264 1440x1080): the player's fit modes and zoom differ visibly on any wide screen; "
        "an English SRT line on screen throughout",
        frames=480,
        video=Video("h264", "High", "sdr", 1440, 1080, 8, lines=(
            "H.264 High, 8-bit, 1440x1080 (4:3), 23.976 fps, SDR",
            "Letterbox shows it whole, Fill screen crops it, Stretch widens it",
            "Audio: AAC 2.0. Subtitles: SRT en, 4 cues covering the clip",
        )),
        audio=(stereo(),),
        subtitles=(Subtitle("subrip", "h264-4x3.en.srt", "en", "eng", "English", True, events=4),),
    ),
    Clip(
        id="h264-portrait",
        exercises="A picture taller than wide (H.264 720x1280, a phone's upright video): the iPhone's player releases "
        "its landscape lock for it and follows the device",
        frames=480,
        video=Video("h264", "High", "sdr", 720, 1280, 8, lines=(
            "H.264 High, 8-bit, 720x1280 (9:16),",
            "23.976 fps, SDR. Audio: AAC 2.0",
        )),
        audio=(stereo(),),
    ),
    Clip(
        id="scripts",
        exercises="Subtitle text in every script a subtitle can use: Japanese, Chinese, Korean, Arabic, Hebrew, Thai, "
        "Devanagari, Cyrillic and Greek, in one SRT cue on screen throughout, drawn with the player's own subtitle font "
        "(a script libass finds no font for comes out as boxes); the track is forced and in the audio's language "
        "(Japanese), so a session without subtitle languages shows it with no menu pick",
        frames=480,
        video=Video(**SDR_1080, lines=(
            "H.264 High, 8-bit, 1920x1080, 23.976 fps, SDR; audio AAC 2.0 (ja)",
            "Subtitles: SRT ja (forced), 1 cue from 00:00.5 to 00:19.9 in nine scripts:",
            "Japanese, Chinese, Korean / Arabic, Hebrew, Thai, Devanagari / Cyrillic, Greek, Latin",
        )),
        audio=(stereo(language="ja", legacy="jpn"),),
        subtitles=(Subtitle("subrip", "scripts.ja.srt", "ja", "jpn", "Every script", True, forced=True, events=1),),
    ),
    Clip(
        id="chapters",
        exercises="Named chapters for intro, recap and credits skipping: Recap, Opening, Episode, Ending, Preview "
        "(an episode: recap and intro early, credits then a preview to the end)",
        frames=1439,
        video=Video(**SDR_1080, chapter_label=True, lines=(
            "H.264 High, 8-bit, 1920x1080, 23.976 fps, SDR; audio AAC 2.0; 60 s",
            "Chapters: Recap 00:00, Opening 00:04, Episode 00:12, Ending 00:44, Preview 00:54",
            "Top right: the chapter playing, its number and its span",
        )),
        audio=(stereo(),),
        chapters=((0.0, "Recap"), (4.0, "Opening"), (12.0, "Episode"), (44.0, "Ending"), (54.0, "Preview")),
    ),
    Clip(
        id="chapters-postcredits",
        exercises="Named chapters with a post-credits scene: Opening Credits, Story, End Credits, Post-credits Scene "
        "(credits followed by content end where it starts)",
        frames=1439,
        video=Video(**SDR_1080, chapter_label=True, lines=(
            "H.264 High, 8-bit, 1920x1080, 23.976 fps, SDR; audio AAC 2.0; 60 s",
            "Chapters: Opening Credits 00:00, Story 00:08, End Credits 00:40, Post-credits Scene 00:52",
            "Top right: the chapter playing, its number and its span",
        )),
        audio=(stereo(),),
        chapters=((0.0, "Opening Credits"), (8.0, "Story"), (40.0, "End Credits"), (52.0, "Post-credits Scene")),
    ),
    Clip(
        id="chapters-numbered",
        exercises="Numbered chapters only, no title naming an intro or credits: Chapter 1 to Chapter 4 (an episode "
        "whose intro and credits the chapter classifier finds by their times: a 90 s intro after a cold open, 90 s "
        "credits at the end)",
        frames=10070,
        video=Video(**SDR_1080, chapter_label=True, lines=(
            "H.264 High, 8-bit, 1920x1080, 23.976 fps, SDR; audio AAC 2.0; 7 min",
            "Chapters: Chapter 1 00:00, Chapter 2 00:30, Chapter 3 02:00, Chapter 4 05:30",
            "Top right: the chapter playing, its number and its span",
        )),
        audio=(stereo(),),
        chapters=((0.0, "Chapter 1"), (30.0, "Chapter 2"), (120.0, "Chapter 3"), (330.0, "Chapter 4")),
    ),
    Clip(
        id="remux",
        exercises="A typical high-bitrate REMUX: HEVC Main 10 2160p HDR10, TrueHD 5.1 + AC-3 5.1 + AAC commentary, "
        "forced/full/SDH PGS, ASS and SRT subtitles in three languages, chapters",
        frames=720,
        video=Video("hevc", "Main 10", "hdr10", 3840, 2160, 10, lines=(
            "HEVC Main 10, 3840x2160, HDR10; 30 s in 3 chapters (00:00, 00:10, 00:20)",
            "Audio: TrueHD 5.1 en (default), AC-3 5.1 de, AAC 2.0 en commentary",
            "Subtitles: PGS en forced (default), PGS en, PGS en SDH, ASS es, SRT fr",
        )),
        audio=(
            Audio("truehd", None, "5.1(side)", 6, 48000, 24, "en", "eng", "English - TrueHD 5.1", True, TONES_51,
                  original=True),
            Audio("ac3", None, "5.1(side)", 6, 48000, None, "de", "ger", "Deutsch - AC-3 5.1", False, TONES_51_LOW,
                  bitrate="640k"),
            stereo(title="Commentary - AAC 2.0 - tones L 300 Hz, R 350 Hz", default=False, tones=TONES_COMMENTARY,
                   commentary=True),
        ),
        subtitles=(
            Subtitle("hdmv_pgs_subtitle", "remux.en.forced.srt", "en", "eng", "English (forced)", True, forced=True,
                     events=2),
            Subtitle("hdmv_pgs_subtitle", "remux.en.srt", "en", "eng", "English", False, events=6),
            Subtitle("hdmv_pgs_subtitle", "remux.en.sdh.srt", "en", "eng", "English (SDH)", False,
                     hearing_impaired=True, events=6),
            Subtitle("ass", "remux.es.ass", "es", "spa", "Español", False, events=6),
            Subtitle("subrip", "remux.fr.srt", "fr", "fre", "Français", False, events=6),
        ),
        chapters=((0.0, "Opening"), (10.0, "Audio tracks"), (20.0, "Subtitle tracks")),
    ),
    Clip(
        id="tracks-next",
        exercises="The episode after remux.mkv in the test addon's tracks series: the remux's languages in another "
        "order and other codecs, so a track picked in the remux carries over by language, class and title, not by "
        "its number",
        frames=720,
        video=Video(**SDR_1080, lines=(
            "H.264 High, 8-bit, 1920x1080, 23.976 fps, SDR; 30 s: episode 2 of the tracks series",
            "Audio: AAC 2.0 en (default), AAC 2.0 en commentary, AAC 2.0 de",
            "Subtitles: SRT fr, SRT en SDH, SRT en, SRT en forced (default), ASS es",
        )),
        audio=(
            stereo(title="English - AAC 2.0 - tones L 440 Hz, R 660 Hz", original=True),
            stereo(title="Commentary - AAC 2.0 - tones L 300 Hz, R 350 Hz", default=False, tones=TONES_COMMENTARY,
                   commentary=True),
            stereo(title="Deutsch - AAC 2.0 - tones L 220 Hz, R 330 Hz", language="de", legacy="ger", default=False,
                   tones=(220.0, 330.0)),
        ),
        subtitles=(
            Subtitle("subrip", "tracks-next.fr.srt", "fr", "fre", "Français", False, events=6),
            Subtitle("subrip", "tracks-next.en.sdh.srt", "en", "eng", "English (SDH)", False, hearing_impaired=True,
                     events=6),
            Subtitle("subrip", "tracks-next.en.srt", "en", "eng", "English", False, events=6),
            Subtitle("subrip", "tracks-next.en.forced.srt", "en", "eng", "English (forced)", True, forced=True,
                     events=2),
            Subtitle("ass", "tracks-next.es.ass", "es", "spa", "Español", False, events=6),
        ),
    ),
)
