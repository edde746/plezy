<script lang="ts">
  import { browser } from "$app/environment";
  import Logo from "$lib/components/Logo.svelte";
  import AppleIcon from "~icons/simple-icons/apple";
  import GooglePlayIcon from "~icons/simple-icons/googleplay";

  type Platform = "ios" | "android" | "unknown";

  let platform: Platform = $state("unknown");

  if (browser) {
    const ua = navigator.userAgent.toLowerCase();
    if (/iphone|ipad|ipod/.test(ua)) {
      platform = "ios";
    } else if (/android/.test(ua)) {
      platform = "android";
    }
  }
</script>

<svelte:head>
  <title>Open in Plezy</title>
  <meta name="description" content="Open this QR code with the Plezy app." />
  <meta name="robots" content="noindex, nofollow" />
  <link rel="canonical" href="https://plezy.app/scan" />

  <meta property="og:type" content="website" />
  <meta property="og:site_name" content="Plezy" />
  <meta property="og:title" content="Open in Plezy" />
  <meta property="og:description" content="Open this QR code with the Plezy app." />
  <meta property="og:url" content="https://plezy.app/scan" />
  <meta property="og:image" content="https://plezy.app/og/plezy-social.png" />

  <meta name="twitter:card" content="summary_large_image" />
  <meta name="twitter:title" content="Open in Plezy" />
  <meta name="twitter:description" content="Open this QR code with the Plezy app." />
  <meta name="twitter:image" content="https://plezy.app/og/plezy-social.png" />
</svelte:head>

<div class="scan-page">
  <div class="scan-card">
    <span class="scan-logo"><Logo /></span>

    <h1 class="scan-heading">Scan in Plezy</h1>
    <p class="scan-description">To use this feature, scan this QR code with the Plezy app.</p>

    <div class="store-buttons">
      {#if platform !== "android"}
        <a
          href="https://apps.apple.com/us/app/id6754315964"
          target="_blank"
          rel="noopener noreferrer"
          class="store-button"
        >
          <AppleIcon />
          App Store
        </a>
      {/if}

      {#if platform !== "ios"}
        <a
          href="https://play.google.com/store/apps/details?id=com.edde746.plezy"
          target="_blank"
          rel="noopener noreferrer"
          class="store-button"
        >
          <GooglePlayIcon />
          Google Play
        </a>
      {/if}
    </div>
  </div>
</div>

<style>
  .scan-page {
    display: flex;
    min-height: 100dvh;
    align-items: center;
    justify-content: center;
    padding: var(--page-gutter);
  }

  .scan-card {
    display: flex;
    width: min(100%, 32rem);
    flex-direction: column;
    align-items: center;
    border-radius: var(--radius-xl);
    padding: clamp(2rem, 8vw, 4rem);
    background: var(--color-surface);
    text-align: center;
  }

  .scan-logo {
    display: flex;
    width: 5rem;
    height: 5rem;
    align-items: center;
    justify-content: center;
    margin-bottom: 2rem;
    border-radius: var(--radius-lg);
    background: var(--color-surface-highest);
  }

  .scan-logo :global(svg) {
    width: 2.5rem;
    height: 2.5rem;
  }

  .scan-heading {
    margin-bottom: 0.75rem;
    font-family: var(--font-display);
    font-size: clamp(2rem, 8vw, 3.25rem);
    font-weight: 700;
    letter-spacing: -0.045em;
    line-height: 1;
  }

  .scan-description {
    max-width: 24rem;
    margin-bottom: 2rem;
    color: var(--color-text-muted);
    line-height: 1.65;
  }

  .store-buttons {
    display: flex;
    flex-wrap: wrap;
    justify-content: center;
    gap: 0.5rem;
  }

  .store-button {
    display: inline-flex;
    min-height: 3rem;
    align-items: center;
    gap: 0.625rem;
    border-radius: var(--radius-pill);
    padding-inline: 1.25rem;
    color: var(--color-on-primary);
    background: var(--color-text);
    font-size: 0.8125rem;
    font-weight: 700;
    transition:
      border-radius var(--motion-expressive) var(--ease-standard),
      background-color var(--motion-fast) var(--ease-standard);
  }

  .store-button:hover,
  .store-button:focus-visible {
    border-radius: var(--radius-md);
    background: #fff;
    outline: none;
  }

  .store-button :global(svg) {
    width: 1.125rem;
    height: 1.125rem;
  }
</style>
