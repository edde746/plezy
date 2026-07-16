<script lang="ts">
  import DownloadButtons from "./DownloadButtons.svelte";
  import Logo from "./Logo.svelte";
  import homeImage from '$lib/assets/screenshots/phone-home.png?enhanced';
  import libraryImage from '$lib/assets/screenshots/phone-library.png?enhanced';
</script>

<section id="home" class="hero-section">
  <div class="hero-shell">
    <div class="hero-grid">
      <div class="hero-copy">
        <div class="brand-row fade-in">
          <span class="brand-logo"><Logo /></span>
          <span>Plezy</span>
        </div>

        <h1 class="hero-title fade-in" style="animation-delay: 60ms;">
          A beautiful client for <span>Plex &amp; Jellyfin</span>
        </h1>
        <p class="hero-description fade-in" style="animation-delay: 120ms;">
          Stream your media library with HDR, Dolby Vision, offline downloads, and an experience built for every
          screen.
        </p>

        <div id="download" class="download-area fade-in" style="animation-delay: 180ms;">
          <DownloadButtons />
        </div>
      </div>

      <div class="hero-visual fade-in" style="animation-delay: 240ms;">
        <div class="shape-field" aria-hidden="true">
          <svg
            class="hero-shape arch-shape"
            viewBox="0 0 1 1"
            preserveAspectRatio="none"
            data-material-shape="Arch"
          >
            <path
              d="M0.146447 0.146447C0.236929 0.055964 0.361929 0 0.5 0C0.776142 0 1 0.223858 1 0.5C1 0.619526 1 0.739052 1 0.858579C1 0.936684 0.936683 1 0.858579 1C0.619526 1 0.380474 1 0.141421 1C0.063317 1 0 0.936683 0 0.858579C0 0.739052 0 0.619526 0 0.5C0 0.361929 0.055964 0.236929 0.146447 0.146447Z"
            />
          </svg>
          <svg
            class="hero-shape cookie-shape"
            viewBox="0 0 1 1"
            data-material-shape="Cookie6Sided"
          >
            <path
              d="M0.716525 0.8729C0.699648 0.882624 0.683956 0.894405 0.669829 0.908026C0.669329 0.908507 0.66883 0.908989 0.66833 0.90947C0.574432 1 0.425694 0.999869 0.331956 0.909174C0.303749 0.881883 0.269272 0.861938 0.231554 0.851089C0.230887 0.850897 0.23022 0.850705 0.229553 0.850514C0.104204 0.81446 0.029948 0.685584 0.061623 0.559056C0.071154 0.520984 0.071189 0.481153 0.061725 0.443063C0.061558 0.44239 0.06139 0.441717 0.061223 0.441043C0.029771 0.31446 0.104254 0.185715 0.229667 0.149882C0.267404 0.1391 0.301917 0.119215 0.330171 0.091974C0.330671 0.091493 0.33117 0.091011 0.331669 0.09053C0.425568 0 0.574306 0.000131 0.668044 0.090826C0.696251 0.118116 0.730728 0.138062 0.768446 0.148911C0.769113 0.149103 0.76978 0.149294 0.770446 0.149486C0.895796 0.18554 0.970052 0.314416 0.938377 0.440944C0.928846 0.479016 0.928811 0.518847 0.938275 0.556937C0.938442 0.55761 0.93861 0.558283 0.938777 0.558957C0.970229 0.685539 0.895746 0.814285 0.770333 0.850118C0.751464 0.855509 0.733402 0.863176 0.716525 0.8729Z"
            />
          </svg>
          <svg
            class="hero-shape diamond-shape"
            viewBox="0 0 1 1"
            data-material-shape="Diamond"
          >
            <path
              d="M0.5 1C0.472713 1 0.445426 0.992561 0.421304 0.977684C0.398028 0.963329 0.371729 0.929255 0.319131 0.861106C0.252 0.774128 0.184869 0.68715 0.117738 0.600171C0.073881 0.543348 0.073881 0.46409 0.117738 0.407267C0.184869 0.320289 0.252 0.233311 0.319131 0.146333C0.371729 0.078184 0.398028 0.044109 0.421304 0.029754C0.469549 0 0.530451 0 0.578696 0.029754C0.601972 0.044109 0.628271 0.078184 0.680869 0.146333C0.748 0.233311 0.815131 0.320289 0.882262 0.407267C0.926119 0.46409 0.926119 0.543348 0.882262 0.600171C0.815131 0.68715 0.748 0.774128 0.680869 0.861106C0.628271 0.929255 0.601972 0.963329 0.578696 0.977684C0.554573 0.992561 0.527287 1 0.5 1Z"
            />
          </svg>
        </div>
        <div class="phone secondary-phone">
          <enhanced:img
            src={libraryImage}
            alt="Plezy library screen on phone"
            class="phone-image"
            loading="eager"
            sizes="(min-width: 1024px) 250px, (min-width: 640px) 34vw, 42vw"
          />
        </div>
        <div class="phone primary-phone">
          <enhanced:img
            src={homeImage}
            alt="Plezy home screen on phone"
            class="phone-image"
            fetchpriority="high"
            sizes="(min-width: 1024px) 280px, (min-width: 640px) 38vw, 48vw"
          />
        </div>
      </div>
    </div>
  </div>
</section>

<style>
  .hero-section {
    overflow-x: clip;
    padding-inline: var(--page-gutter);
  }

  .hero-shell {
    width: min(100%, var(--page-width));
    margin-inline: auto;
    padding-block: clamp(3rem, 8vw, 7rem) clamp(5rem, 10vw, 9rem);
  }

  .hero-grid {
    display: grid;
    align-items: center;
    gap: clamp(4rem, 9vw, 8rem);
  }

  .hero-copy {
    min-width: 0;
  }

  .brand-row {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    margin-bottom: clamp(2rem, 5vw, 3rem);
    font-family: var(--font-display);
    font-size: 1.125rem;
    font-weight: 700;
  }

  .brand-logo :global(svg) {
    width: 2.25rem;
    height: 2.25rem;
  }

  .hero-title {
    max-width: 10ch;
    font-family: var(--font-display);
    font-size: clamp(3rem, 10vw, 5.75rem);
    font-weight: 700;
    letter-spacing: -0.055em;
    line-height: 0.98;
    text-wrap: balance;
  }

  .hero-title span {
    color: var(--color-text-muted);
  }

  .hero-description {
    max-width: 31rem;
    margin-top: 1.5rem;
    color: var(--color-text-muted);
    font-size: clamp(1rem, 2vw, 1.125rem);
    line-height: 1.65;
  }

  .download-area {
    margin-top: 2rem;
    scroll-margin-top: 2rem;
  }

  .hero-visual {
    position: relative;
    isolation: isolate;
    display: flex;
    width: min(100%, 35rem);
    align-items: flex-start;
    justify-content: center;
    gap: clamp(0.5rem, 2vw, 1.25rem);
    margin-inline: auto;
    padding: 0.5rem 0 2.5rem;
  }

  .shape-field {
    position: absolute;
    z-index: 0;
    inset: -1.5rem -1.5rem -1rem;
    pointer-events: none;
  }

  .hero-shape {
    position: absolute;
    display: block;
    fill: currentColor;
    opacity: 0.82;
  }

  .arch-shape {
    top: -4%;
    right: -12%;
    width: 78%;
    height: 96%;
    color: var(--color-surface-high);
    transform: rotate(4deg);
  }

  .cookie-shape {
    top: 6%;
    left: -10%;
    width: clamp(11rem, 32vw, 17rem);
    color: color-mix(in srgb, var(--color-brand) 10%, var(--color-surface-high));
    transform: rotate(-10deg);
  }

  .diamond-shape {
    bottom: -8%;
    left: -10%;
    width: clamp(10rem, 28vw, 15rem);
    aspect-ratio: 1;
    color: var(--color-surface-highest);
    transform: rotate(-18deg);
  }


  .phone {
    position: relative;
    z-index: 1;
    min-width: 0;
    overflow: hidden;
    border-radius: clamp(1.75rem, 4vw, 2.75rem);
    background: #000;
  }

  .secondary-phone {
    width: 44%;
    margin-top: clamp(3rem, 8vw, 6rem);
    transform: rotate(-2.5deg);
  }

  .primary-phone {
    width: 50%;
    transform: rotate(2deg);
  }

  .phone :global(picture),
  .phone-image {
    display: block;
    width: 100%;
    height: auto;
  }

  .fade-in {
    animation: fade-in-up var(--motion-expressive) var(--ease-standard) both;
  }

  @media (min-width: 960px) {
    .hero-grid {
      grid-template-columns: minmax(28rem, 1fr) minmax(28rem, 0.9fr);
    }

    .hero-visual {
      justify-self: end;
    }
  }
</style>
