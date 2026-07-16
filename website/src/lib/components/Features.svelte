<script lang="ts">
  import ScrollReveal from "./ScrollReveal.svelte";
  import AppleIcon from "~icons/simple-icons/apple";
  import GooglePlayIcon from "~icons/simple-icons/googleplay";
  import LinuxIcon from "~icons/devicon-plain/linux";
  import AniListIcon from "~icons/simple-icons/anilist";
  import MyAnimeListIcon from "~icons/simple-icons/myanimelist";
  import SimklIcon from "~icons/simple-icons/simkl";
  import TraktIcon from "~icons/simple-icons/trakt";
  import WindowsIcon from "./WindowsIcon.svelte";
  import ArrowDownTrayIcon from "~icons/heroicons/arrow-down-tray-solid";
  import PlayIcon from "~icons/heroicons/play-solid";
  import UserIcon from "~icons/heroicons/user-solid";
</script>

<section id="features" class="features-section">
  <ScrollReveal>
    <p class="section-label">Features</p>
    <h2 class="section-heading">Everything you need to stream</h2>
    <p class="section-description">
      Built for people who care about quality as much as convenience.
    </p>
  </ScrollReveal>

  <div class="bento-grid">
    <!-- HERO: Wide Codec Support — 2col × 2row -->
    <ScrollReveal class="bento-codec">
      <div class="flat-card feature-card codec-card">
        <div class="card-content">
          <h3 class="card-title large">Wide Codec Support</h3>
          <p class="card-copy codec-copy">
            Play without transcoding. Your server does less work — you get better quality.
          </p>
        </div>
        <div class="codec-scatter" aria-hidden="true">
          <span class="featured" style="--x: 2%; --y: 2%; --r: -5deg;">HEVC</span>
          <span class="bright" style="--x: 27%; --y: 0%; --r: 4deg;">AV1</span>
          <span style="--x: 50%; --y: 2%; --r: -2deg;">H.264</span>
          <span style="--x: 79%; --y: 1%; --r: 3deg;">VP9</span>
          <span class="featured" style="--x: 0%; --y: 30%; --r: -3deg;">TrueHD</span>
          <span style="--x: 21%; --y: 29%; --r: 2deg;">EAC3</span>
          <span style="--x: 39%; --y: 30%; --r: -4deg;">DTS</span>
          <span style="--x: 54%; --y: 29%; --r: 3deg;">FLAC</span>
          <span style="--x: 69%; --y: 31%; --r: -2deg;">OPUS</span>
          <span style="--x: 86%; --y: 30%; --r: 4deg;">AAC</span>
          <span class="bright" style="--x: 5%; --y: 59%; --r: -3deg;">MPEG-4</span>
          <span style="--x: 33%; --y: 58%; --r: 2deg;">ALAC</span>
          <span style="--x: 53%; --y: 60%; --r: -4deg;">MPEG-2</span>
          <span style="--x: 82%; --y: 59%; --r: 3deg;">VC-1</span>
          <span style="--x: 1%; --y: 88%; --r: -2deg;">AC3</span>
          <span style="--x: 18%; --y: 87%; --r: 4deg;">PCM</span>
          <span style="--x: 34%; --y: 89%; --r: -3deg;">Vorbis</span>
          <span style="--x: 57%; --y: 87%; --r: 2deg;">MP3</span>
          <span style="--x: 72%; --y: 89%; --r: -4deg;">WMA</span>
          <span style="--x: 87%; --y: 87%; --r: 3deg;">VP8</span>
        </div>
      </div>
    </ScrollReveal>

    <!-- HDR -->
    <ScrollReveal delay={50} class="bento-hdr">
      <div class="flat-card feature-card hdr-card">
        <div class="hdr-orb" aria-hidden="true"></div>
        <p class="card-eyebrow">Display</p>
        <div class="card-bottom">
          <p class="hdr-title">
            HDR10+
          </p>
          <p class="hdr-subtitle">Dolby Vision</p>
        </div>
      </div>
    </ScrollReveal>

    <!-- Advanced Subtitles -->
    <ScrollReveal delay={100} class="bento-sub">
      <div class="flat-card feature-card sub-card">
        <!-- Fake subtitle lines -->
        <div class="subtitle-lines" aria-hidden="true">
          <div class="subtitle-line wide"></div>
          <div class="subtitle-line short"></div>
        </div>
        <div>
          <p class="card-title">Subtitles</p>
          <p class="card-caption">SSA/ASS &middot; SRT &middot; PGS</p>
        </div>
      </div>
    </ScrollReveal>

    <!-- Cross-Platform — 1col × 2row tall -->
    <ScrollReveal delay={80} class="bento-cross">
      <div class="flat-card feature-card cross-card">
        <p class="card-title with-gap">Cross-Platform</p>
        <div class="platform-list">
          <div class="platform-row">
            <div class="platform-icon-box">
              <AppleIcon />
            </div>
            <span>iOS &middot; macOS &middot; tvOS</span>
          </div>
          <div class="platform-row">
            <div class="platform-icon-box">
              <GooglePlayIcon />
            </div>
            <span>Android</span>
          </div>
          <div class="platform-row">
            <div class="platform-icon-box">
              <WindowsIcon />
            </div>
            <span>Windows</span>
          </div>
          <div class="platform-row">
            <div class="platform-icon-box">
              <LinuxIcon />
            </div>
            <span>Linux</span>
          </div>
        </div>
      </div>
    </ScrollReveal>

    <!-- Offline Downloads -->
    <ScrollReveal delay={150} class="bento-offline">
      <div class="flat-card feature-card offline-card">
        <div>
          <p class="card-title">Offline</p>
          <p class="card-caption">Download &amp; watch anywhere</p>
        </div>
        <div class="offline-ready" aria-hidden="true">
          <span class="offline-progress"><span></span></span>
          <div class="offline-download-icon">
            <ArrowDownTrayIcon />
          </div>
        </div>
      </div>
    </ScrollReveal>

    <!-- Watch Together -->
    <ScrollReveal delay={180} class="bento-watch">
      <div class="flat-card feature-card watch-card">
        <div>
          <p class="card-title">Watch Together</p>
          <p class="card-caption">Perfectly synced playback</p>
        </div>
        <div class="watch-sync" aria-hidden="true">
          <div class="sync-stage">
            <div class="sync-avatars">
              <span class="sync-avatar avatar-a"><UserIcon /></span>
              <span class="sync-avatar avatar-b"><UserIcon /></span>
              <span class="sync-avatar avatar-c"><UserIcon /></span>
            </div>
            <div class="sync-timelines">
              <span class="sync-track"><span></span></span>
              <span class="sync-track"><span></span></span>
              <span class="sync-track"><span></span></span>
              <span class="sync-cursor"><PlayIcon /></span>
            </div>
          </div>
        </div>
      </div>
    </ScrollReveal>

    <!-- Tracker Sync -->
    <ScrollReveal delay={210} class="bento-trackers">
      <div class="flat-card feature-card tracker-card">
        <div class="tracker-copy">
          <p class="card-title">Tracker Sync</p>
          <p class="card-caption">Progress, ratings, and watch history</p>
        </div>
        <div class="tracker-grid" aria-label="Supported trackers">
          <div class="tracker-pill trakt">
            <TraktIcon />
            <span>Trakt</span>
          </div>
          <div class="tracker-pill mal">
            <MyAnimeListIcon />
            <span>MAL</span>
          </div>
          <div class="tracker-pill anilist">
            <AniListIcon />
            <span>AniList</span>
          </div>
          <div class="tracker-pill simkl">
            <SimklIcon />
            <span>Simkl</span>
          </div>
        </div>
      </div>
    </ScrollReveal>

    <!-- Much More — full width banner -->
    <ScrollReveal delay={270} class="bento-more">
      <div class="flat-card feature-card more-card">
        <div>
          <p class="card-title">& much more</p>
          <p class="more-description">
            Skip intros, chapter support, gestures, and new features added regularly.
          </p>
        </div>
        <div class="dot-row" aria-hidden="true">
          <div class="dot strong"></div>
          <div class="dot medium"></div>
          <div class="dot faint"></div>
        </div>
      </div>
    </ScrollReveal>
  </div>
</section>

<style>
  .features-section {
    width: min(100%, var(--page-width));
    margin-inline: auto;
    padding: clamp(4rem, 9vw, 8rem) var(--page-gutter);
  }

  .section-label {
    width: fit-content;
    margin-bottom: 1rem;
    border-radius: var(--radius-full);
    padding: 0.5rem 0.875rem;
    color: var(--color-text-muted);
    background: var(--color-surface);
    font-size: 0.75rem;
    font-weight: 700;
    letter-spacing: 0.03em;
  }

  .section-heading {
    max-width: 13ch;
    margin-bottom: 1rem;
    font-family: var(--font-display);
    font-size: clamp(2.5rem, 7vw, 4.75rem);
    font-weight: 700;
    letter-spacing: -0.045em;
    line-height: 1;
    text-wrap: balance;
  }

  .section-description {
    max-width: 34rem;
    margin-bottom: clamp(2.5rem, 6vw, 4.5rem);
    color: var(--color-text-muted);
    font-size: clamp(1rem, 2vw, 1.125rem);
    line-height: 1.7;
  }

  .bento-grid {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: var(--group-gap);
  }

  .bento-grid :global(.scroll-reveal) {
    height: 100%;
  }

  .feature-card {
    height: 100%;
    border-radius: var(--radius-xs);
    background: var(--color-surface);
  }

  .codec-card,
  .hdr-card,
  .tracker-card {
    position: relative;
    overflow: hidden;
  }

  .codec-card,
  .hdr-card,
  .sub-card,
  .offline-card,
  .watch-card,
  .tracker-card {
    display: flex;
    flex-direction: column;
    justify-content: space-between;
  }

  .codec-card {
    min-height: 20.5rem;
    padding: clamp(1.5rem, 4vw, 1.75rem);
    isolation: isolate;
  }

  .hdr-card,
  .sub-card,
  .cross-card,
  .offline-card,
  .watch-card,
  .tracker-card {
    min-height: 10rem;
    padding: clamp(1.25rem, 3vw, 1.75rem);
  }
  .offline-card,
  .watch-card {
    padding: 1.25rem;
  }

  .hdr-card,
  .cross-card,
  .watch-card {
    background: var(--color-surface-high);
  }

  .sub-card,
  .offline-card {
    background: var(--color-surface-highest);
  }

  .cross-card {
    display: flex;
    flex-direction: column;
    min-height: 20.5rem;
  }

  .tracker-card {
    gap: 1.5rem;
  }

  .card-content {
    position: relative;
    z-index: 1;
  }

  .card-title {
    font-family: var(--font-display);
    font-size: 1.0625rem;
    font-weight: 700;
    letter-spacing: -0.015em;
    line-height: 1.35;
  }

  .card-title.large {
    max-width: 10ch;
    margin-bottom: 0.75rem;
    font-size: clamp(1.75rem, 4vw, 2.75rem);
    line-height: 1;
  }

  .card-title.with-gap {
    margin-bottom: 1.5rem;
  }

  .card-copy {
    color: var(--color-text-muted);
    font-size: 0.875rem;
    line-height: 1.65;
  }

  .codec-copy {
    max-width: 19rem;
  }

  .card-eyebrow {
    position: relative;
    z-index: 1;
    color: var(--color-text-subtle);
    font-family: var(--font-utility);
    font-size: 0.6875rem;
    font-weight: 700;
    letter-spacing: 0.05em;
    text-transform: uppercase;
  }

  .card-bottom,
  .platform-list {
    margin-top: auto;
  }

  .hdr-orb {
    position: absolute;
    top: -2rem;
    right: -1.5rem;
    width: 8rem;
    height: 8rem;
    border-radius: 45% 55% 52% 48%;
    background: rgb(237 237 237 / 0.08);
    transform: rotate(20deg);
  }

  .hdr-title {
    position: relative;
    font-family: var(--font-display);
    font-size: clamp(2rem, 5vw, 3rem);
    font-weight: 700;
    letter-spacing: -0.04em;
    line-height: 1;
  }

  .hdr-subtitle {
    position: relative;
    margin-top: 0.375rem;
    color: var(--color-text-muted);
    font-size: 0.8125rem;
  }

  .subtitle-lines {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
    margin-bottom: 1rem;
  }

  .subtitle-line {
    height: 0.5rem;
    border-radius: var(--radius-full);
    background: rgb(237 237 237 / 0.16);
  }

  .subtitle-line.wide {
    width: 78%;
  }

  .subtitle-line.short {
    width: 52%;
    opacity: 0.65;
  }

  .card-caption {
    margin-top: 0.375rem;
    color: var(--color-text-muted);
    font-size: 0.75rem;
    line-height: 1.35;
  }

  .platform-list {
    display: flex;
    flex-direction: column;
    gap: var(--group-gap);
  }

  .platform-row {
    display: flex;
    min-height: 3.25rem;
    align-items: center;
    gap: 0.75rem;
    border-radius: var(--radius-xs);
    padding: 0.5rem 0.75rem;
    color: var(--color-text-muted);
    background: rgb(237 237 237 / 0.07);
    font-size: 0.8125rem;
    font-weight: 600;
  }

  .platform-row:first-child {
    border-radius: var(--radius-md) var(--radius-md) var(--radius-xs) var(--radius-xs);
  }

  .platform-row:last-child {
    border-radius: var(--radius-xs) var(--radius-xs) var(--radius-md) var(--radius-md);
  }

  .platform-icon-box {
    display: flex;
    width: 2rem;
    height: 2rem;
    flex-shrink: 0;
    align-items: center;
    justify-content: center;
    border-radius: var(--radius-full);
    color: var(--color-text);
    background: rgb(237 237 237 / 0.1);
  }

  .platform-icon-box :global(svg) {
    width: 0.9375rem;
    height: 0.9375rem;
  }

  .offline-ready {
    display: flex;
    min-width: 0;
    align-items: center;
    gap: 0.75rem;
    margin-top: 0.75rem;
  }

  .offline-progress {
    height: 0.625rem;
    flex: 1 1 auto;
    overflow: hidden;
    border-radius: var(--radius-full);
    background: rgb(237 237 237 / 0.12);
  }

  .offline-progress > span {
    display: block;
    width: 76%;
    height: 100%;
    border-radius: inherit;
    background: var(--color-brand);
  }

  .offline-download-icon {
    display: flex;
    width: 2.75rem;
    height: 2.75rem;
    flex: 0 0 auto;
    align-items: center;
    justify-content: center;
    border-radius: var(--radius-full);
    color: var(--color-bg);
    background: var(--color-text);
  }

  .offline-download-icon :global(svg) {
    width: 1.1rem;
    height: 1.1rem;
  }

  .watch-card .card-caption {
    white-space: nowrap;
  }

  .watch-sync {
    margin-top: 0.75rem;
  }

  .sync-stage {
    display: grid;
    grid-template-columns: 1.1rem minmax(0, 1fr);
    gap: 0.45rem;
  }

  .sync-avatars,
  .sync-timelines {
    display: flex;
    flex-direction: column;
    gap: 0.2rem;
  }

  .sync-timelines {
    position: relative;
  }

  .sync-avatar {
    display: flex;
    width: 1.1rem;
    height: 1.1rem;
    align-items: center;
    justify-content: center;
    border-radius: var(--radius-full);
    font-size: 0.5rem;
    font-weight: 800;
  }
  .sync-avatar :global(svg) {
    width: 0.6rem;
    height: 0.6rem;
  }

  .avatar-a {
    color: #ffb39d;
    background: #633326;
  }

  .avatar-b {
    color: #b9d8ff;
    background: #293d59;
  }

  .avatar-c {
    color: #b5e6c8;
    background: #294638;
  }

  .sync-track {
    position: relative;
    height: 1.1rem;
  }

  .sync-track::before,
  .sync-track > span {
    position: absolute;
    top: 50%;
    left: 0;
    height: 0.25rem;
    border-radius: var(--radius-full);
    content: "";
    transform: translateY(-50%);
  }

  .sync-track::before {
    width: 100%;
    background: rgb(237 237 237 / 0.12);
  }

  .sync-track > span {
    width: 63%;
    background: color-mix(in srgb, var(--color-brand) 62%, var(--color-text-muted));
  }

  .sync-cursor {
    position: absolute;
    top: -0.15rem;
    bottom: -0.15rem;
    left: 63%;
    width: 1px;
    background: var(--color-brand);
  }

  .sync-cursor :global(svg) {
    position: absolute;
    top: 50%;
    left: 50%;
    box-sizing: border-box;
    width: 1.1rem;
    height: 1.1rem;
    border-radius: var(--radius-full);
    padding: 0.3rem;
    color: var(--color-bg);
    background: var(--color-brand);
    transform: translate(-50%, -50%);
  }


  .tracker-grid {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: var(--group-gap);
  }

  .tracker-pill {
    display: flex;
    min-width: 0;
    min-height: 2.75rem;
    align-items: center;
    gap: 0.5rem;
    border-radius: var(--radius-xs);
    padding: 0.625rem 0.75rem;
    background: rgb(237 237 237 / 0.07);
    font-size: 0.75rem;
    font-weight: 700;
  }

  .tracker-pill:nth-child(1) {
    border-radius: var(--radius-md) var(--radius-xs) var(--radius-xs) var(--radius-xs);
  }

  .tracker-pill:nth-child(2) {
    border-radius: var(--radius-xs) var(--radius-md) var(--radius-xs) var(--radius-xs);
  }

  .tracker-pill:nth-child(3) {
    border-radius: var(--radius-xs) var(--radius-xs) var(--radius-xs) var(--radius-md);
  }

  .tracker-pill:nth-child(4) {
    border-radius: var(--radius-xs) var(--radius-xs) var(--radius-md) var(--radius-xs);
  }

  .tracker-pill :global(svg) {
    width: 1rem;
    height: 1rem;
    flex-shrink: 0;
  }

  .tracker-pill.trakt {
    color: #ff6b70;
  }

  .tracker-pill.mal {
    color: #8caeff;
  }

  .tracker-pill.anilist {
    color: #6bcbff;
  }

  .tracker-pill.simkl {
    color: var(--color-text);
  }

  .more-card {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 1.5rem;
    min-height: 7rem;
    padding: 1.5rem clamp(1.5rem, 4vw, 2.5rem);
  }

  .more-description {
    max-width: 34rem;
    margin-top: 0.375rem;
    color: var(--color-text-muted);
    font-size: 0.75rem;
    line-height: 1.45;
  }

  .dot-row {
    display: flex;
    gap: 0.375rem;
  }

  .dot {
    width: 0.5rem;
    height: 0.5rem;
    border-radius: var(--radius-full);
    background: var(--color-text);
  }

  .dot.medium {
    opacity: 0.55;
  }

  .dot.faint {
    opacity: 0.25;
  }

  .codec-card::after {
    position: absolute;
    right: -5rem;
    bottom: -7rem;
    z-index: -1;
    width: 16rem;
    height: 16rem;
    border-radius: var(--radius-full);
    background: var(--color-surface-high);
    content: "";
  }

  .codec-scatter {
    position: relative;
    z-index: 1;
    height: 7rem;
    margin-top: 0.75rem;
  }

  .codec-scatter > span {
    position: absolute;
    top: var(--y);
    left: var(--x);
    display: flex;
    min-height: 1.5rem;
    align-items: center;
    justify-content: center;
    border-radius: var(--radius-full);
    padding: 0.25rem 0.65rem;
    color: var(--color-text-muted);
    background: var(--color-surface-high);
    font-family: var(--font-utility);
    font-size: clamp(0.5625rem, 1.5vw, 0.6875rem);
    font-weight: 750;
    letter-spacing: 0.015em;
    transform: rotate(var(--r));
  }

  .codec-scatter > .featured {
    color: var(--color-brand);
    background: color-mix(in srgb, var(--color-brand) 11%, var(--color-surface-highest));
    font-weight: 800;
  }

  .codec-scatter > .bright {
    color: var(--color-text);
    background: var(--color-surface-highest);
    font-weight: 800;
  }

  .bento-grid :global(.bento-codec),
  .bento-grid :global(.bento-cross),
  .bento-grid :global(.bento-offline),
  .bento-grid :global(.bento-watch),
  .bento-grid :global(.bento-trackers),
  .bento-grid :global(.bento-more) {
    grid-column: 1 / -1;
  }

  .bento-grid :global(.bento-hdr) {
    grid-column: 1;
  }

  .bento-grid :global(.bento-sub) {
    grid-column: 2;
  }

  :global(.bento-codec) .feature-card {
    border-radius: var(--radius-xl) var(--radius-xl) var(--radius-xs) var(--radius-xs);
  }

  :global(.bento-more) .feature-card {
    border-radius: var(--radius-xs) var(--radius-xs) var(--radius-xl) var(--radius-xl);
  }

  @media (max-width: 719px) {
    .offline-card,
    .watch-card {
      height: 10rem;
      min-height: 10rem;
    }
  }

  @media (min-width: 720px) {
    .bento-grid {
      grid-template-columns: repeat(4, minmax(0, 1fr));
    }

    .bento-grid :global(.bento-codec) {
      grid-column: 1 / 3;
      grid-row: 1 / 3;
    }

    .bento-grid :global(.bento-hdr) {
      grid-column: 3;
      grid-row: 1;
    }

    .bento-grid :global(.bento-sub) {
      grid-column: 3;
      grid-row: 2;
    }

    .bento-grid :global(.bento-cross) {
      grid-column: 4;
      grid-row: 1 / 3;
    }

    .bento-grid :global(.bento-offline) {
      grid-column: 1;
      grid-row: 3;
    }

    .bento-grid :global(.bento-watch) {
      grid-column: 2;
      grid-row: 3;
    }

    .bento-grid :global(.bento-trackers) {
      grid-column: 3 / 5;
      grid-row: 3;
    }

    .bento-grid :global(.bento-more) {
      grid-column: 1 / 5;
      grid-row: 4;
    }

    :global(.bento-codec) .feature-card {
      border-radius: var(--radius-xl) var(--radius-xs) var(--radius-xs) var(--radius-xs);
    }

    :global(.bento-hdr) .feature-card,
    :global(.bento-sub) .feature-card {
      border-radius: var(--radius-xs);
    }

    :global(.bento-cross) .feature-card {
      border-radius: var(--radius-xs) var(--radius-xl) var(--radius-xs) var(--radius-xs);
    }

    :global(.bento-offline) .feature-card {
      border-radius: var(--radius-xs);
    }

    :global(.bento-watch) .feature-card {
      border-radius: var(--radius-xs);
    }

    :global(.bento-trackers) .feature-card {
      border-radius: var(--radius-xs);
    }

    .tracker-card {
      flex-direction: row;
      align-items: center;
    }

    .tracker-copy {
      flex: 1 1 40%;
    }

    .tracker-grid {
      flex: 1 1 60%;
    }
  }
</style>
