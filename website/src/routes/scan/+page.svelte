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
    min-height: 100vh;
    align-items: center;
    justify-content: center;
    padding: 4rem 1.5rem;
  }

  .scan-card {
    display: flex;
    max-width: 24rem;
    flex-direction: column;
    align-items: center;
    text-align: center;
  }

  .scan-logo {
    margin-bottom: 1.5rem;
  }

  .scan-logo :global(svg) {
    width: 4rem;
    height: 4rem;
  }

  .scan-heading {
    margin-bottom: 0.5rem;
    font-size: 1.5rem;
    font-weight: 700;
    line-height: 2rem;
  }

  .scan-description {
    margin-bottom: 2rem;
    color: var(--color-text-muted);
  }

  .store-buttons {
    display: flex;
    flex-wrap: wrap;
    justify-content: center;
    gap: 0.75rem;
  }

  .store-button {
    display: inline-flex;
    align-items: center;
    gap: 0.625rem;
    padding: 0.75rem 1.25rem;
    border-radius: 9999px;
    background: #fff;
    color: #111827;
    font-size: 0.875rem;
    font-weight: 600;
    line-height: 1.25rem;
    transition: background-color 150ms ease;
  }

  .store-button:hover {
    background: #f3f4f6;
  }

  .store-button :global(svg) {
    width: 1.25rem;
    height: 1.25rem;
  }
</style>
