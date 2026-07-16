<script lang="ts">
  import AppleIcon from "~icons/simple-icons/apple";
  import GooglePlayIcon from "~icons/simple-icons/googleplay";
  import LinuxIcon from "~icons/devicon-plain/linux";
  import AmazonIcon from "~icons/cib/amazon";
  import ChevronDownIcon from "~icons/heroicons/chevron-down-solid";
  import WindowsIcon from "./WindowsIcon.svelte";

  const linuxArchitectures = [
    {
      label: "x64 (Intel/AMD)",
      formats: [
        { label: ".deb (Debian/Ubuntu)", url: "https://github.com/edde746/plezy/releases/latest/download/plezy-linux-x64.deb" },
        { label: ".rpm (Fedora/RHEL)", url: "https://github.com/edde746/plezy/releases/latest/download/plezy-linux-x64.rpm" },
        { label: ".pkg.tar.zst (Arch)", url: "https://github.com/edde746/plezy/releases/latest/download/plezy-linux-x64.pkg.tar.zst" },
        { label: ".tar.gz (Portable)", url: "https://github.com/edde746/plezy/releases/latest/download/plezy-linux-x64.tar.gz" },
      ],
    },
    {
      label: "ARM64",
      formats: [
        { label: ".deb (Debian/Ubuntu)", url: "https://github.com/edde746/plezy/releases/latest/download/plezy-linux-arm64.deb" },
        { label: ".rpm (Fedora/RHEL)", url: "https://github.com/edde746/plezy/releases/latest/download/plezy-linux-arm64.rpm" },
        { label: ".pkg.tar.zst (Arch)", url: "https://github.com/edde746/plezy/releases/latest/download/plezy-linux-arm64.pkg.tar.zst" },
        { label: ".tar.gz (Portable)", url: "https://github.com/edde746/plezy/releases/latest/download/plezy-linux-arm64.tar.gz" },
      ],
    },
  ];

  let linuxOpen = $state(false);
  let hovered = $state(false);
  let showDropdown = $derived(linuxOpen || hovered);
</script>

<svelte:window onclick={() => { linuxOpen = false; }} />

<div class="download-buttons">
  <!-- Primary row -->
  <div class="store-buttons">
    <a
      href="https://apps.apple.com/us/app/id6754315964"
      target="_blank"
      rel="noopener noreferrer"
      class="store-button"
    >
      <AppleIcon />
      App Store
    </a>

    <a
      href="https://play.google.com/store/apps/details?id=com.edde746.plezy"
      target="_blank"
      rel="noopener noreferrer"
      class="store-button"
    >
      <GooglePlayIcon />
      Google Play
    </a>

    <a
      href="https://www.amazon.com/gp/product/B0GK65CVS1"
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
      href="https://github.com/edde746/plezy/releases/latest/download/plezy-windows-installer.exe"
      class="desktop-button"
    >
      <WindowsIcon />
      Windows
    </a>

    <a
      href="https://github.com/edde746/plezy/releases/latest/download/plezy-macos.dmg"
      class="desktop-button"
    >
      <AppleIcon />
      macOS
    </a>

    <!-- Linux dropdown -->
    <div
      class="linux-control"
      role="group"
      onpointerenter={(e) => { if (e.pointerType === 'mouse') hovered = true; }}
      onpointerleave={(e) => { if (e.pointerType === 'mouse') hovered = false; }}
    >
      <button
        type="button"
        onclick={(e) => { e.stopPropagation(); linuxOpen = !linuxOpen; }}
        aria-expanded={showDropdown}
        aria-haspopup="true"
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
        role="menu"
        class="linux-menu"
        class:open={showDropdown}
      >
        {#each linuxArchitectures as arch, i}
          {#if i > 0}
            <div class="linux-separator"></div>
          {/if}
          <div class="linux-arch-label">{arch.label}</div>
          {#each arch.formats as format}
            <a href={format.url} role="menuitem" onclick={() => { linuxOpen = false; }} class="linux-menu-item">
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
    outline: none;
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
    outline: none;
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
    outline: none;
  }

  @media (max-width: 460px) {
    .store-button,
    .desktop-button {
      flex: 1 1 auto;
    }
  }
</style>
