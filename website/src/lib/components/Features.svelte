<script lang="ts">
  import ScrollReveal from "./ScrollReveal.svelte";
  import AppleIcon from "~icons/simple-icons/apple";
  import GooglePlayIcon from "~icons/simple-icons/googleplay";
  import LinuxIcon from "~icons/simple-icons/linux";
  import AniListIcon from "~icons/simple-icons/anilist";
  import MyAnimeListIcon from "~icons/simple-icons/myanimelist";
  import SimklIcon from "~icons/simple-icons/simkl";
  import TraktIcon from "~icons/simple-icons/trakt";
  import WindowsIcon from "./WindowsIcon.svelte";
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
      <div class="glass-card feature-card codec-card">
        <div class="card-content">
          <h3 class="card-title large">Wide Codec Support</h3>
          <p class="card-copy codec-copy">
            Play without transcoding. Your server does less work — you get better quality.
          </p>
        </div>
        <!-- Codec wall with accent highlights on key codecs -->
        <div class="codec-wall" aria-hidden="true">
          <span class="codec-accent">HEVC</span>
          <span class="codec-accent-80">AV1</span>
          <span class="codec-text-70">H.264</span>
          <span class="codec-text-70">VP9</span>
          <span class="codec-accent-60">AAC</span>
          <span class="codec-text-50">FLAC</span>
          <span class="codec-text-50">OPUS</span>
          <span class="codec-text-50">EAC3</span>
          <span class="codec-text-40">DTS</span>
          <span class="codec-text-40">MPEG-4</span>
          <span class="codec-text-30">VP8</span>
          <span class="codec-text-30">ALAC</span>
          <span class="codec-text-30">TrueHD</span>
          <span class="codec-text-20">MPEG-2</span>
          <span class="codec-text-20">VC-1</span>
          <span class="codec-text-20">AC3</span>
          <span class="codec-text-15">PCM</span>
          <span class="codec-text-10">Vorbis</span>
          <span class="codec-text-10">MP3</span>
          <span class="codec-text-10">WMA</span>
        </div>
        <div class="codec-fade"></div>
      </div>
    </ScrollReveal>

    <!-- HDR -->
    <ScrollReveal delay={50} class="bento-hdr">
      <div class="glass-card feature-card hdr-card">
        <!-- Subtle warm glow -->
        <div class="hdr-glow"></div>
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
      <div class="glass-card feature-card sub-card">
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
      <div class="glass-card feature-card cross-card">
        <p class="card-title with-gap">Cross-Platform</p>
        <div class="platform-list">
          <div class="platform-row">
            <div class="platform-icon-box">
              <AppleIcon />
            </div>
            <span>iOS &middot; macOS</span>
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
      <div class="glass-card feature-card offline-card">
        <p class="card-title">Offline</p>
        <!-- Download progress visual -->
        <div class="progress-block" aria-hidden="true">
          <div class="progress-track">
            <div class="progress-fill"></div>
          </div>
          <p class="progress-caption">Download &amp; watch anywhere</p>
        </div>
      </div>
    </ScrollReveal>

    <!-- Watch Together -->
    <ScrollReveal delay={180} class="bento-watch">
      <div class="glass-card feature-card watch-card">
        <p class="card-title">Watch Together</p>
        <!-- Avatar circles -->
        <div class="avatar-row" aria-hidden="true">
          <div class="avatar avatar-a">
            A
          </div>
          <div class="avatar avatar-b">
            B
          </div>
          <div class="avatar avatar-c">
            C
          </div>
          <span class="sync-label">Synced</span>
        </div>
      </div>
    </ScrollReveal>

    <!-- Tracker Sync -->
    <ScrollReveal delay={210} class="bento-trackers">
      <div class="glass-card feature-card tracker-card">
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
      <div class="glass-card feature-card more-card">
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
    max-width: 64rem;
    margin-inline: auto;
    padding: 4rem 1.5rem;
  }

  .section-label {
    margin-bottom: 0.75rem;
    color: var(--color-accent);
    font-size: 0.875rem;
    font-weight: 500;
    letter-spacing: 0.025em;
    line-height: 1.25rem;
    text-transform: uppercase;
  }

  .section-heading {
    margin-bottom: 1rem;
    font-size: 2.25rem;
    font-weight: 700;
    line-height: 2.5rem;
  }

  .section-description {
    max-width: 32rem;
    margin-bottom: 2.5rem;
    color: var(--color-text-muted);
    font-size: 1.125rem;
    line-height: 1.75rem;
  }

  .feature-card {
    height: 100%;
    border-radius: 1rem;
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
    padding: 2rem;
  }

  .hdr-card,
  .sub-card,
  .cross-card,
  .offline-card,
  .watch-card,
  .tracker-card {
    padding: 1.5rem;
  }

  .cross-card {
    display: flex;
    flex-direction: column;
  }

  .tracker-card {
    gap: 1rem;
  }

  .card-content {
    position: relative;
    z-index: 10;
  }

  .card-title {
    font-size: 1rem;
    font-weight: 600;
    line-height: 1.5rem;
  }

  .card-title.large {
    margin-bottom: 0.5rem;
    font-size: 1.25rem;
    line-height: 1.75rem;
  }

  .card-title.with-gap {
    margin-bottom: 1.25rem;
  }

  .card-copy {
    color: var(--color-text-muted);
    font-size: 0.875rem;
    line-height: 1.625;
  }

  .codec-copy {
    max-width: 17.5rem;
  }

  .card-eyebrow {
    color: var(--color-text-muted);
    font-size: 0.75rem;
    line-height: 1rem;
    letter-spacing: 0.05em;
    text-transform: uppercase;
  }

  .card-bottom,
  .platform-list {
    margin-top: auto;
  }

  .hdr-glow {
    position: absolute;
    top: -2rem;
    right: -2rem;
    width: 6rem;
    height: 6rem;
    border-radius: 9999px;
    background: color-mix(in srgb, var(--color-accent) 15%, transparent);
    filter: blur(40px);
    pointer-events: none;
  }

  .hdr-title {
    color: transparent;
    background: linear-gradient(to right, var(--color-accent-dim), var(--color-accent));
    -webkit-background-clip: text;
    background-clip: text;
    font-size: 1.875rem;
    font-weight: 700;
    line-height: 1.25;
  }

  .hdr-subtitle {
    margin-top: 0.25rem;
    color: color-mix(in srgb, var(--color-text-muted) 80%, transparent);
    font-size: 0.875rem;
    line-height: 1.25rem;
  }

  .subtitle-lines,
  .progress-block {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
    margin-bottom: 1rem;
  }

  .subtitle-line {
    height: 0.375rem;
    border-radius: 9999px;
  }

  .subtitle-line.wide {
    width: 75%;
    background: rgb(255 255 255 / 0.08);
  }

  .subtitle-line.short {
    width: 50%;
    background: rgb(255 255 255 / 0.05);
  }

  .card-caption {
    margin-top: 0.25rem;
    color: var(--color-text-muted);
    font-size: 0.75rem;
    line-height: 1rem;
  }

  .platform-list {
    display: flex;
    flex-direction: column;
    gap: 0.75rem;
  }

  .platform-row {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    color: var(--color-text-muted);
    font-size: 0.875rem;
    line-height: 1.25rem;
  }

  .platform-icon-box {
    display: flex;
    width: 2rem;
    height: 2rem;
    flex-shrink: 0;
    align-items: center;
    justify-content: center;
    border-radius: 0.5rem;
  }

  .platform-icon-box {
    background: rgb(255 255 255 / 0.05);
  }

  .platform-icon-box :global(svg) {
    width: 1rem;
    height: 1rem;
  }

  .progress-block {
    margin-top: 1rem;
    margin-bottom: 0;
  }

  .progress-track {
    height: 0.25rem;
    overflow: hidden;
    border-radius: 9999px;
    background: rgb(255 255 255 / 0.1);
  }

  .progress-fill {
    width: 75%;
    height: 100%;
    border-radius: 9999px;
    background: color-mix(in srgb, var(--color-accent) 60%, transparent);
  }

  .progress-caption {
    color: color-mix(in srgb, var(--color-text-muted) 60%, transparent);
    font-size: 0.625rem;
    line-height: 1;
  }

  .avatar-row {
    display: flex;
    align-items: center;
    margin-top: 1rem;
  }

  .avatar {
    display: flex;
    width: 2rem;
    height: 2rem;
    align-items: center;
    justify-content: center;
    border: 2px solid var(--color-surface);
    border-radius: 9999px;
    font-size: 0.625rem;
    font-weight: 700;
    line-height: 1;
  }

  .avatar + .avatar {
    margin-left: -0.5rem;
  }

  .avatar-a {
    color: var(--color-accent);
    background: color-mix(in srgb, var(--color-accent) 20%, transparent);
  }

  .avatar-b {
    color: #60a5fa;
    background: rgb(59 130 246 / 0.2);
  }

  .avatar-c {
    color: #34d399;
    background: rgb(16 185 129 / 0.2);
  }

  .sync-label {
    margin-left: 0.5rem;
    color: var(--color-text-muted);
    font-size: 0.75rem;
    line-height: 1rem;
  }

  .tracker-grid {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 0.5rem;
  }

  .tracker-pill {
    display: flex;
    min-width: 0;
    align-items: center;
    gap: 0.375rem;
    border-radius: 0.625rem;
    padding: 0.5rem;
    color: color-mix(in srgb, var(--color-text-muted) 90%, transparent);
    background: rgb(255 255 255 / 0.05);
    font-size: 0.6875rem;
    font-weight: 600;
    line-height: 1;
  }

  .tracker-pill :global(svg) {
    width: 0.875rem;
    height: 0.875rem;
    flex-shrink: 0;
  }

  .tracker-pill.trakt {
    color: #ed1c24;
    background: color-mix(in srgb, #ed1c24 12%, transparent);
  }

  .tracker-pill.mal {
    color: #2e51a2;
    background: color-mix(in srgb, #2e51a2 18%, transparent);
  }

  .tracker-pill.anilist {
    color: #02a9ff;
    background: color-mix(in srgb, #02a9ff 14%, transparent);
  }

  .tracker-pill.simkl {
    color: #dbdbe0;
    background: color-mix(in srgb, #dbdbe0 8%, transparent);
  }

  .more-card {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 1.5rem 2rem;
  }

  .more-description {
    margin-top: 0.125rem;
    color: var(--color-text-muted);
    font-size: 0.75rem;
    line-height: 1rem;
  }

  .dot-row {
    display: flex;
    gap: 0.375rem;
  }

  .dot {
    width: 0.375rem;
    height: 0.375rem;
    border-radius: 9999px;
  }

  .dot.strong {
    background: color-mix(in srgb, var(--color-accent) 60%, transparent);
  }

  .dot.medium {
    background: color-mix(in srgb, var(--color-accent) 40%, transparent);
  }

  .dot.faint {
    background: color-mix(in srgb, var(--color-accent) 20%, transparent);
  }

  .codec-wall {
    display: flex;
    flex-wrap: wrap;
    gap: 0.5rem 0.75rem;
    margin-top: 1rem;
    font-family: ui-monospace, SFMono-Regular, "SF Mono", Menlo, monospace;
    font-size: 0.8125rem;
    font-weight: 500;
    line-height: 1.8;
  }

  .codec-accent {
    color: var(--color-accent);
  }

  .codec-accent-80 {
    color: color-mix(in srgb, var(--color-accent) 80%, transparent);
  }

  .codec-accent-60 {
    color: color-mix(in srgb, var(--color-accent) 60%, transparent);
  }

  .codec-text-70 {
    color: color-mix(in srgb, var(--color-text) 70%, transparent);
  }

  .codec-text-50 {
    color: color-mix(in srgb, var(--color-text) 50%, transparent);
  }

  .codec-text-40 {
    color: color-mix(in srgb, var(--color-text) 40%, transparent);
  }

  .codec-text-30 {
    color: color-mix(in srgb, var(--color-text) 30%, transparent);
  }

  .codec-text-20 {
    color: color-mix(in srgb, var(--color-text) 20%, transparent);
  }

  .codec-text-15 {
    color: color-mix(in srgb, var(--color-text) 15%, transparent);
  }

  .codec-text-10 {
    color: color-mix(in srgb, var(--color-text) 10%, transparent);
  }

  .codec-fade {
    position: absolute;
    inset-inline: 0;
    bottom: 0;
    z-index: 1;
    height: 4rem;
    background: linear-gradient(to top, var(--color-surface), transparent);
    pointer-events: none;
  }

  .bento-grid {
    display: grid;
    grid-template-columns: repeat(4, minmax(0, 1fr));
    grid-template-rows: auto auto auto auto;
    gap: 1rem;
  }

  /* Named areas for precise placement — :global because classes are on child components */
  .bento-grid :global(.bento-codec) {
    grid-column: 1 / 3;
    grid-row: 1 / 3;
  }
  .bento-grid :global(.bento-hdr) {
    grid-column: 3 / 4;
    grid-row: 1 / 2;
  }
  .bento-grid :global(.bento-sub) {
    grid-column: 3 / 4;
    grid-row: 2 / 3;
  }
  .bento-grid :global(.bento-cross) {
    grid-column: 4 / 5;
    grid-row: 1 / 3;
  }
  .bento-grid :global(.bento-trackers) {
    grid-column: 3 / 5;
    grid-row: 3 / 4;
  }
  .bento-grid :global(.bento-offline) {
    grid-column: 1 / 2;
    grid-row: 3 / 4;
  }
  .bento-grid :global(.bento-watch) {
    grid-column: 2 / 3;
    grid-row: 3 / 4;
  }
  .bento-grid :global(.bento-more) {
    grid-column: 1 / 5;
    grid-row: 4 / 5;
  }

  /* Mobile: single column stack with HDR + Subtitles paired */
  @media (max-width: 639px) {
    .bento-grid {
      grid-template-columns: repeat(2, 1fr);
      grid-template-rows: auto;
    }
    .bento-grid :global(.bento-codec),
    .bento-grid :global(.bento-cross),
    .bento-grid :global(.bento-offline),
    .bento-grid :global(.bento-watch),
    .bento-grid :global(.bento-trackers),
    .bento-grid :global(.bento-more) {
      grid-column: 1 / -1;
      grid-row: auto;
    }
    .bento-grid :global(.bento-hdr) {
      grid-column: 1 / 2;
      grid-row: auto;
    }
    .bento-grid :global(.bento-sub) {
      grid-column: 2 / 3;
      grid-row: auto;
    }
  }

  @media (min-width: 640px) {
    .features-section {
      padding-block: 6rem;
    }

    .section-description {
      margin-bottom: 4rem;
    }

    .tracker-card {
      flex-direction: row;
      align-items: center;
    }

    .tracker-copy {
      flex-shrink: 0;
    }

    .tracker-grid {
      flex: 1;
    }
  }

  @media (min-width: 768px) {
    .features-section {
      padding-block: 8rem;
    }

    .section-heading {
      font-size: 3rem;
      line-height: 1;
    }
  }
</style>
