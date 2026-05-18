<script lang="ts">
  import DownloadButtons from "./DownloadButtons.svelte";
  import Logo from "./Logo.svelte";
  import homeImage from '$lib/assets/screenshots/phone-home.png?enhanced';
  import libraryImage from '$lib/assets/screenshots/phone-library.png?enhanced';
</script>

<section id="home" class="hero-section">
  <!-- Giant background logo watermark -->
  <div class="hero-watermark" aria-hidden="true">
    <Logo gradient={false} />
  </div>

  <!-- Ambient glow -->
  <div class="ambient-glow"></div>

  <!-- Content: two-column on desktop -->
  <div class="hero-content">
    <!-- Left: text + buttons -->
    <div class="hero-copy">
      <div class="brand-row fade-in" style="animation-delay: 0ms;">
        <span class="brand-logo"><Logo /></span>
        <span class="brand-name">Plezy</span>
      </div>

      <h1
        class="hero-title fade-in"
        style="animation-delay: 100ms;"
      >
        <span class="title-line">A beautiful client for</span>
        <span class="title-line gradient-text">Plex &amp; Jellyfin</span>
      </h1>

      <p
        class="hero-description fade-in"
        style="animation-delay: 200ms;"
      >
        Stream your media library with HDR, Dolby Vision, offline downloads, and a gorgeous experience across all your
        devices.
      </p>

      <div class="fade-in" style="animation-delay: 300ms;">
        <DownloadButtons />
      </div>
    </div>

    <!-- Right: stacked phone mockup -->
    <div class="phone-stage fade-in" style="animation-delay: 400ms;">
      <div class="phone-stack">
        <!-- Shadow phone behind -->
        <div class="shadow-phone">
          <enhanced:img
            src={libraryImage}
            alt=""
            class="phone-image"
            loading="lazy"
            sizes="(min-width: 768px) 300px, (min-width: 640px) 280px, 224px"
          />
        </div>
        <!-- Main phone -->
        <div class="main-phone">
          <enhanced:img
            src={homeImage}
            alt="Plezy home screen"
            class="phone-image"
            fetchpriority="high"
            sizes="(min-width: 768px) 300px, (min-width: 640px) 280px, 224px"
          />
        </div>
      </div>
    </div>
  </div>
</section>

<style>
  .hero-section {
    position: relative;
    display: flex;
    min-height: 100dvh;
    align-items: center;
    overflow: hidden;
  }

  .hero-watermark {
    position: absolute;
    top: 50%;
    right: -5rem;
    width: 37.5rem;
    transform: translateY(-50%);
    opacity: 0.04;
    pointer-events: none;
    user-select: none;
  }

  .hero-watermark :global(svg) {
    width: 100%;
    height: auto;
  }

  .ambient-glow {
    position: absolute;
    top: 33.3333%;
    right: 25%;
    width: 31.25rem;
    height: 31.25rem;
    border-radius: 9999px;
    background: color-mix(in srgb, var(--color-accent) 10%, transparent);
    filter: blur(120px);
    animation: pulse-glow 3s ease-in-out infinite;
    pointer-events: none;
  }

  .hero-content {
    position: relative;
    display: grid;
    width: 100%;
    max-width: 80rem;
    margin-inline: auto;
    padding: 4rem 1.5rem;
    gap: 3rem;
    align-items: center;
  }

  .hero-copy {
    max-width: 36rem;
  }

  .fade-in {
    animation: fade-in-up 0.6s ease-out both;
  }

  .brand-row {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    margin-bottom: 1.25rem;
  }

  .brand-logo :global(svg) {
    width: 2.5rem;
    height: 2.5rem;
  }

  .brand-name {
    color: var(--color-text-muted);
    font-size: 1.25rem;
    font-weight: 600;
  }

  .hero-title {
    font-size: 2.25rem;
    line-height: 1.05;
    font-weight: 700;
    letter-spacing: -0.025em;
  }

  .title-line {
    display: block;
    white-space: nowrap;
  }

  .gradient-text {
    color: transparent;
    background: linear-gradient(to right, var(--color-accent-dim), var(--color-accent));
    -webkit-background-clip: text;
    background-clip: text;
  }

  .hero-description {
    max-width: 28rem;
    margin-top: 1rem;
    margin-bottom: 2rem;
    color: var(--color-text-muted);
    font-size: 1rem;
    line-height: 1.625;
  }

  .phone-stage {
    position: relative;
    display: flex;
    justify-content: center;
  }

  .phone-stack {
    position: relative;
    width: 14rem;
  }

  .shadow-phone {
    position: absolute;
    top: 0.75rem;
    left: -2rem;
    width: 100%;
    overflow: hidden;
    border: 1px solid color-mix(in srgb, var(--color-border) 30%, transparent);
    border-radius: 2.5rem;
    opacity: 0.4;
    filter: blur(1px);
    transform: rotate(-4deg);
  }

  .main-phone {
    position: relative;
    overflow: hidden;
    border: 2px solid color-mix(in srgb, var(--color-border) 60%, transparent);
    border-radius: 2.5rem;
    box-shadow: 0 0 80px -20px color-mix(in srgb, var(--color-accent) 20%, transparent);
  }

  .phone-image {
    display: block;
    width: 100%;
    height: auto;
  }

  @media (min-width: 640px) {
    .hero-content {
      padding-block: 6rem;
    }

    .brand-row {
      margin-bottom: 2rem;
    }

    .hero-title {
      font-size: 3rem;
    }

    .hero-description {
      margin-top: 1.5rem;
      margin-bottom: 2.5rem;
      font-size: 1.125rem;
    }

    .phone-stack {
      width: 17.5rem;
    }
  }

  @media (min-width: 768px) {
    .hero-watermark {
      width: 50rem;
    }

    .hero-title {
      font-size: 3.75rem;
    }

    .phone-stack {
      width: 18.75rem;
    }
  }

  @media (min-width: 1024px) {
    .hero-watermark {
      width: 62.5rem;
    }

    .hero-content {
      grid-template-columns: repeat(2, minmax(0, 1fr));
      padding-inline: 3rem;
      gap: 6rem;
    }

    .phone-stage {
      justify-content: flex-end;
    }
  }
</style>
