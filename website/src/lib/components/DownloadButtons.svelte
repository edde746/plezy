<script lang="ts">
  import AppleIcon from "~icons/simple-icons/apple";
  import GooglePlayIcon from "~icons/simple-icons/googleplay";
  import LinuxIcon from "~icons/simple-icons/linux";
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
    gap: 1rem;
  }

  .store-buttons,
  .desktop-buttons {
    display: flex;
    flex-wrap: wrap;
  }

  .store-buttons {
    gap: 0.75rem;
  }

  .desktop-buttons {
    gap: 0.625rem;
  }

  .store-button,
  .desktop-button {
    display: inline-flex;
    align-items: center;
    border-radius: 9999px;
    font-size: 0.875rem;
    line-height: 1.25rem;
    transition: background-color 150ms ease, color 150ms ease;
  }

  .store-button {
    gap: 0.625rem;
    padding: 0.75rem 1.25rem;
    color: #111827;
    background: #fff;
    font-weight: 600;
  }

  .store-button:hover {
    background: #f3f4f6;
  }

  .store-button :global(svg) {
    width: 1.25rem;
    height: 1.25rem;
  }

  .desktop-button {
    gap: 0.5rem;
    padding: 0.5rem 1rem;
    border: 1px solid var(--color-border);
    background: color-mix(in srgb, var(--color-surface) 80%, transparent);
  }

  .desktop-button:hover,
  .linux-button.active {
    background: var(--color-surface-hover);
  }

  .desktop-button :global(svg) {
    width: 0.875rem;
    height: 0.875rem;
    opacity: 0.7;
  }

  .linux-control {
    position: relative;
  }

  .linux-button {
    cursor: default;
  }

  .chevron {
    width: 0.75rem;
    height: 0.75rem;
    transition: transform 300ms ease;
  }

  .chevron.open {
    transform: rotate(180deg);
  }

  .chevron :global(svg) {
    width: 0.75rem;
    height: 0.75rem;
    opacity: 1;
  }

  .linux-menu {
    position: absolute;
    bottom: 100%;
    left: 0;
    z-index: 10;
    width: 14rem;
    margin-bottom: 0.5rem;
    overflow: hidden;
    border: 1px solid var(--color-border);
    border-radius: 1rem;
    background: var(--color-surface);
    box-shadow:
      0 20px 25px -5px rgb(0 0 0 / 0.1),
      0 8px 10px -6px rgb(0 0 0 / 0.1);
    opacity: 0;
    visibility: hidden;
    transition: opacity 150ms ease, visibility 150ms ease;
  }

  .linux-menu.open {
    opacity: 1;
    visibility: visible;
  }

  .linux-separator {
    border-top: 1px solid var(--color-border);
  }

  .linux-arch-label {
    padding: 0.625rem 1rem 0.25rem;
    color: var(--color-text-muted);
    font-size: 0.75rem;
    font-weight: 600;
    letter-spacing: 0.025em;
    text-transform: uppercase;
  }

  .linux-menu-item {
    display: block;
    padding: 0.5rem 1rem;
    font-size: 0.875rem;
    line-height: 1.25rem;
    transition: background-color 150ms ease;
  }

  .linux-menu-item:hover {
    background: var(--color-surface-hover);
  }
</style>
