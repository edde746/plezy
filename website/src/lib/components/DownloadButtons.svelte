<script lang="ts">
  import AppleIcon from "~icons/simple-icons/apple";
  import GooglePlayIcon from "~icons/simple-icons/googleplay";
  import LinuxIcon from "~icons/devicon-plain/linux";
  import AmazonIcon from "~icons/cib/amazon";
  import ChevronDownIcon from "~icons/heroicons/chevron-down-solid";
  import WindowsIcon from "./WindowsIcon.svelte";
  import { AMAZON_URL, linuxArchitectures, releaseAsset, storeOptions } from "$lib/content/downloads";

  const componentId = $props.id();
  const linuxPanelId = `${componentId}-linux-downloads`;
  let linuxOpen = $state(false);
  let hovered = $state(false);
  let showDropdown = $derived(linuxOpen || hovered);

  function hoverDisclosure(node: HTMLElement) {
    const update = (event: PointerEvent) => {
      if (event.pointerType === 'mouse') hovered = event.type === 'pointerenter';
    };
    node.addEventListener('pointerenter', update);
    node.addEventListener('pointerleave', update);
    return {
      destroy() {
        node.removeEventListener('pointerenter', update);
        node.removeEventListener('pointerleave', update);
      },
    };
  }
</script>

<svelte:window onclick={() => { linuxOpen = false; }} />

<div class="download-buttons">
  <!-- Primary row -->
  <div class="store-buttons">
    <a
      href={storeOptions.ios.url}
      target="_blank"
      rel="noopener noreferrer"
      class="store-button"
    >
      <AppleIcon />
      App Store
    </a>

    <a
      href={storeOptions.android.url}
      target="_blank"
      rel="noopener noreferrer"
      class="store-button"
    >
      <GooglePlayIcon />
      Google Play
    </a>

    <a
      href={AMAZON_URL}
      target="_blank"
      rel="noopener noreferrer"
      class="store-button"
    >
      <AmazonIcon />
      Fire TV
    </a>
  </div>

  <!-- Desktop row -->
  <div class="desktop-buttons">
    <a
      href={releaseAsset("plezy-windows-installer.exe")}
      class="desktop-button"
    >
      <WindowsIcon />
      Windows
    </a>

    <a
      href={releaseAsset("plezy-macos.dmg")}
      class="desktop-button"
    >
      <AppleIcon />
      macOS
    </a>

    <!-- Linux dropdown -->
    <div class="linux-control" use:hoverDisclosure>
      <button
        type="button"
        onclick={(e) => { e.stopPropagation(); linuxOpen = !linuxOpen; }}
        aria-expanded={showDropdown}
        aria-controls={linuxPanelId}
        class="desktop-button linux-button"
        class:active={showDropdown}
      >
        <LinuxIcon />
        Linux
        <span class="chevron" class:open={showDropdown}>
          <ChevronDownIcon />
        </span>
      </button>

      <div
        id={linuxPanelId}
        class="linux-menu"
        class:open={showDropdown}
        aria-hidden={!showDropdown}
        inert={!showDropdown}
      >
        {#each linuxArchitectures as arch, i}
          {#if i > 0}
            <div class="linux-separator" aria-hidden="true"></div>
          {/if}
          <div class="linux-arch-label">{arch.label}</div>
          {#each arch.formats as format}
            <a href={format.url} onclick={() => { linuxOpen = false; }} class="linux-menu-item">
              {format.label}
            </a>
          {/each}
        {/each}
      </div>
    </div>
  </div>
</div>

<style>
  .download-buttons {
    display: flex;
    flex-direction: column;
    gap: 0.75rem;
  }

  .store-buttons,
  .desktop-buttons {
    display: flex;
    flex-wrap: wrap;
    gap: 0.5rem;
  }

  .store-button,
  .desktop-button {
    display: inline-flex;
    min-height: 2.875rem;
    align-items: center;
    justify-content: center;
    gap: 0.625rem;
    border-radius: var(--radius-pill);
    padding-inline: 1rem;
    font-size: 0.8125rem;
    font-weight: 700;
    line-height: 1;
    transition:
      border-radius var(--motion-expressive) var(--ease-standard),
      color var(--motion-fast) var(--ease-standard),
      background-color var(--motion-fast) var(--ease-standard);
  }

  .store-button {
    color: var(--color-on-primary);
    background: var(--color-text);
  }

  .store-button:hover,
  .store-button:focus-visible {
    border-radius: var(--radius-md);
    background: #fff;
  }

  .store-button :global(svg) {
    width: 1.125rem;
    height: 1.125rem;
  }

  .desktop-button {
    color: var(--color-text-muted);
    background: var(--color-surface-highest);
  }

  .desktop-button:hover,
  .desktop-button:focus-visible,
  .linux-button.active {
    color: var(--color-text);
    background: var(--color-surface-hover);
  }

  .desktop-button:hover,
  .desktop-button:focus-visible {
    border-radius: var(--radius-md);
  }

  .desktop-button :global(svg) {
    width: 0.9375rem;
    height: 0.9375rem;
  }

  .linux-control {
    position: relative;
  }

  .chevron {
    width: 0.75rem;
    height: 0.75rem;
    transition: transform var(--motion-normal) var(--ease-standard);
  }

  .chevron.open {
    transform: rotate(180deg);
  }

  .chevron :global(svg) {
    width: 0.75rem;
    height: 0.75rem;
  }

  .linux-menu {
    position: absolute;
    bottom: calc(100% + 0.5rem);
    right: 0;
    z-index: 10;
    width: min(16rem, calc(100vw - 2rem));
    overflow: hidden;
    border-radius: var(--radius-lg);
    padding: 0.375rem;
    background: var(--color-surface-highest);
    opacity: 0;
    visibility: hidden;
    transform: translateY(0.5rem);
    transition:
      opacity var(--motion-normal) var(--ease-standard),
      transform var(--motion-normal) var(--ease-standard),
      visibility var(--motion-normal) var(--ease-standard);
  }

  .linux-menu.open {
    opacity: 1;
    visibility: visible;
    transform: translateY(0);
  }

  .linux-separator {
    height: var(--group-gap);
    margin-block: 0.375rem;
    background: var(--color-border);
  }

  .linux-arch-label {
    padding: 0.625rem 0.75rem 0.375rem;
    color: var(--color-text-subtle);
    font-family: var(--font-utility);
    font-size: 0.6875rem;
    font-weight: 700;
    letter-spacing: 0.04em;
    text-transform: uppercase;
  }

  .linux-menu-item {
    display: block;
    border-radius: var(--radius-md);
    padding: 0.625rem 0.75rem;
    color: var(--color-text-muted);
    font-size: 0.8125rem;
    font-weight: 600;
    line-height: 1.25rem;
    transition:
      color var(--motion-fast) var(--ease-standard),
      background-color var(--motion-fast) var(--ease-standard);
  }

  .linux-menu-item:hover,
  .linux-menu-item:focus-visible {
    color: var(--color-text);
    background: rgb(237 237 237 / 0.12);
  }

  @media (max-width: 460px) {
    .store-button,
    .desktop-button {
      flex: 1 1 auto;
    }
  }
</style>
