<script lang="ts">
  import { onMount } from "svelte";
  import Logo from "$lib/components/Logo.svelte";
  import PageMetadata from "$lib/components/PageMetadata.svelte";
  import AppleIcon from "~icons/simple-icons/apple";
  import GooglePlayIcon from "~icons/simple-icons/googleplay";
  import {
    detectMobileStorePlatform,
    storeOptionsForPlatform,
    type MobileStorePlatform,
  } from "$lib/content/downloads";

  let platform: MobileStorePlatform = $state("unknown");
  let availableStores = $derived(storeOptionsForPlatform(platform));

  onMount(() => {
    platform = detectMobileStorePlatform({
      userAgent: navigator.userAgent,
      platform: navigator.platform,
      maxTouchPoints: navigator.maxTouchPoints,
    });
  });
</script>

<PageMetadata title="Open in Plezy" description="Open this QR code with the Plezy app." url="https://plezy.app/scan" noindex />

<div class="centered-page">
  <div class="centered-card">
    <span class="card-logo"><Logo /></span>

    <h1 class="scan-heading">Scan in Plezy</h1>
    <p class="scan-description">To use this feature, scan this QR code with the Plezy app.</p>

    <div class="store-buttons" role="group" aria-label="Download Plezy">
      {#each availableStores as store}
        <a
          href={store.url}
          target="_blank"
          rel="noopener noreferrer"
          class="btn-pill btn-pill--icon"
        >
          {#if store.id === "app-store"}
            <AppleIcon />
          {:else}
            <GooglePlayIcon />
          {/if}
          {store.label}
        </a>
      {/each}
    </div>
  </div>
</div>

<style>
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
</style>
