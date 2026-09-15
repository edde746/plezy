<script lang="ts">
  import SectionHeader from './SectionHeader.svelte';
  import DevicePhoneIcon from '~icons/heroicons/device-phone-mobile-solid';
  import DeviceTabletIcon from '~icons/heroicons/device-tablet-solid';
  import DesktopIcon from '~icons/heroicons/computer-desktop-solid';
  import TvIcon from '~icons/heroicons/tv-solid';
  import ChevronLeftIcon from '~icons/heroicons/chevron-left-solid';
  import ChevronRightIcon from '~icons/heroicons/chevron-right-solid';

  import phoneHomeImage from '$lib/assets/screenshots/phone-home.png?enhanced';
  import phoneLibraryImage from '$lib/assets/screenshots/phone-library.png?enhanced';
  import phoneMdImage from '$lib/assets/screenshots/phone-md.png?enhanced';
  import phoneSearchImage from '$lib/assets/screenshots/phone-search.png?enhanced';
  import tabletHomeImage from '$lib/assets/screenshots/tablet-home.png?enhanced';
  import tabletLibraryImage from '$lib/assets/screenshots/tablet-library.png?enhanced';
  import tabletMdImage from '$lib/assets/screenshots/tablet-md.png?enhanced';
  import tabletPlayerImage from '$lib/assets/screenshots/tablet-player.png?enhanced';
  import desktopHomeImage from '$lib/assets/screenshots/desktop-home.png?enhanced';
  import desktopLibraryImage from '$lib/assets/screenshots/desktop-library.png?enhanced';
  import desktopMdImage from '$lib/assets/screenshots/desktop-md.png?enhanced';
  import desktopPlayerImage from '$lib/assets/screenshots/desktop-player.png?enhanced';
  import tvHomeImage from '$lib/assets/screenshots/tv-home.png?enhanced';
  import tvLibraryImage from '$lib/assets/screenshots/tv-library.png?enhanced';
  import tvMdImage from '$lib/assets/screenshots/tv-md.png?enhanced';
  import tvPlayerImage from '$lib/assets/screenshots/tv-player.png?enhanced';

  type DeviceType = 'phone' | 'tablet' | 'desktop' | 'tv';
  type DeviceIconComponent = typeof DevicePhoneIcon | typeof DeviceTabletIcon | typeof DesktopIcon | typeof TvIcon;

  const devices: {
    id: DeviceType;
    icon: DeviceIconComponent;
    label: string;
    sizes: string;
    shots: { image: typeof phoneHomeImage; alt: string }[];
  }[] = [
    {
      id: 'phone',
      icon: DevicePhoneIcon,
      label: 'Phone',
      sizes: '(min-width: 1024px) 214px, 187px',
      shots: [
        { image: phoneHomeImage, alt: 'Plezy home screen' },
        { image: phoneLibraryImage, alt: 'Plezy library view' },
        { image: phoneMdImage, alt: 'Plezy media details' },
        { image: phoneSearchImage, alt: 'Plezy search' },
      ],
    },
    {
      id: 'tablet',
      icon: DeviceTabletIcon,
      label: 'Tablet',
      sizes: '(min-width: 1024px) 768px, 672px',
      shots: [
        { image: tabletHomeImage, alt: 'Plezy on tablet - home' },
        { image: tabletLibraryImage, alt: 'Plezy on tablet - library' },
        { image: tabletMdImage, alt: 'Plezy on tablet - media details' },
        { image: tabletPlayerImage, alt: 'Plezy on tablet - video player' },
      ],
    },
    {
      id: 'desktop',
      icon: DesktopIcon,
      label: 'Desktop',
      sizes: '(min-width: 1024px) 768px, 672px',
      shots: [
        { image: desktopHomeImage, alt: 'Plezy on desktop - home' },
        { image: desktopLibraryImage, alt: 'Plezy on desktop - library' },
        { image: desktopMdImage, alt: 'Plezy on desktop - media details' },
        { image: desktopPlayerImage, alt: 'Plezy on desktop - video player' },
      ],
    },
    {
      id: 'tv',
      icon: TvIcon,
      label: 'TV',
      sizes: '(min-width: 1024px) 854px, 747px',
      shots: [
        { image: tvHomeImage, alt: 'Plezy on TV - home' },
        { image: tvLibraryImage, alt: 'Plezy on TV - library' },
        { image: tvMdImage, alt: 'Plezy on TV - media details' },
        { image: tvPlayerImage, alt: 'Plezy on TV - video player' },
      ],
    },
  ];

  let active: DeviceType = $state('phone');
  let loaded: Record<DeviceType, boolean> = $state({
    phone: true,
    tablet: false,
    desktop: false,
    tv: false,
  });
  let scrollContainer: HTMLElement | undefined = $state();
  let canScrollLeft = $state(false);
  let canScrollRight = $state(false);
  let intendedScrollLeft: number | undefined;

  function selectDevice(device: DeviceType) {
    loaded[device] = true;
    active = device;
  }
  function updateScrollState() {
    if (!scrollContainer) return;
    if (intendedScrollLeft !== undefined && Math.abs(scrollContainer.scrollLeft - intendedScrollLeft) < 2) {
      intendedScrollLeft = undefined;
    }

    canScrollLeft = scrollContainer.scrollLeft > 10;
    canScrollRight = scrollContainer.scrollLeft < scrollContainer.scrollWidth - scrollContainer.clientWidth - 10;
  }

  function scroll(dir: 'left' | 'right') {
    if (!scrollContainer) return;

    const items = Array.from(scrollContainer.querySelectorAll<HTMLElement>('.screenshot-item'));
    const maxScroll = scrollContainer.scrollWidth - scrollContainer.clientWidth;

    if (!items.length || maxScroll <= 0) return;

    const tolerance = 2;
    const current = scrollContainer.scrollLeft;
    const base = intendedScrollLeft ?? current;
    const containerLeft = scrollContainer.getBoundingClientRect().left;
    const paddingLeft = parseFloat(getComputedStyle(scrollContainer).paddingLeft) || 0;
    const targets = items.map((item) => item.getBoundingClientRect().left - containerLeft + current - paddingLeft);
    const target = dir === 'right'
      ? Math.min(targets.find((left) => left > base + tolerance) ?? maxScroll, maxScroll)
      : targets.filter((left) => left < base - tolerance && left <= maxScroll + tolerance).at(-1) ?? 0;

    intendedScrollLeft = target;
    canScrollLeft = target > 10;
    canScrollRight = target < maxScroll - 10;
    scrollContainer.scrollTo({ left: target });
  }

  $effect(() => {
    // Re-check scroll state after the active tab changes.
    const currentActive = active;
    const el = document.getElementById(`screenshots-${currentActive}-panel`);

    intendedScrollLeft = undefined;
    scrollContainer = el ?? undefined;

    if (el) {
      // Double rAF waits for layout after the DOM update.
      const raf = requestAnimationFrame(() => {
        requestAnimationFrame(() => {
          if (currentActive === active && el === scrollContainer) updateScrollState();
        });
      });
      return () => cancelAnimationFrame(raf);
    } else {
      canScrollLeft = false;
      canScrollRight = false;
    }
  });
</script>

<section id="screenshots" class="bleed-section">
  <div class="screenshots-header">
    <SectionHeader
      label="Preview"
      heading="Designed with care"
      description="An experience that feels right at home on every device."
      descriptionGap="2rem"
    >
      <div class="screenshot-controls">
        <div class="device-tabs" role="group" aria-label="Screenshot device">
          {#each devices as device}
            {@const DeviceIcon = device.icon}
            <button
              type="button"
              onclick={() => selectDevice(device.id)}
              aria-pressed={active === device.id}
              aria-controls={`screenshots-${device.id}-panel`}
              aria-label={`Show ${device.label} screenshots`}
              class="device-button"
              class:active={active === device.id}
            >
              <DeviceIcon />
              <span class="device-label">{device.label}</span>
            </button>
          {/each}
        </div>

        <div class="scroll-arrows">
          <button
            type="button"
            aria-label="Scroll screenshots left"
            onclick={() => scroll('left')}
            disabled={!canScrollLeft}
            class="scroll-arrow"
            class:enabled={canScrollLeft}
          >
            <ChevronLeftIcon />
          </button>
          <button
            type="button"
            aria-label="Scroll screenshots right"
            onclick={() => scroll('right')}
            disabled={!canScrollRight}
            class="scroll-arrow"
            class:enabled={canScrollRight}
          >
            <ChevronRightIcon />
          </button>
        </div>
      </div>
    </SectionHeader>
  </div>

  <div class="screenshot-panels">
    {#each devices as device (device.id)}
      <div
        id={`screenshots-${device.id}-panel`}
        role="region"
        aria-label={`${device.label} screenshots`}
        aria-hidden={active !== device.id}
        class="screenshot-strip scrollbar-hide content-pad"
        class:panel-active={active === device.id}
        onscroll={() => {
          if (active === device.id) updateScrollState();
        }}
      >
        {#if loaded[device.id]}
          {#each device.shots as shot}
            <div class="screenshot-item">
              <div class={`screenshot-frame ${device.id}-frame`}>
                <enhanced:img
                  src={shot.image}
                  alt={shot.alt}
                  loading="lazy"
                  class="screenshot-image"
                  sizes={device.sizes}
                />
              </div>
            </div>
          {/each}
        {/if}
      </div>
    {/each}
  </div>
</section>

<style>
  .screenshots-header {
    max-width: 64rem;
    margin-inline: auto;
    margin-bottom: clamp(2rem, 5vw, 3.5rem);
    padding-inline: 1.5rem;
  }

  .screenshot-controls {
    display: flex;
    align-items: center;
    gap: 0.75rem;
  }

  .device-tabs {
    display: flex;
    width: fit-content;
    max-width: 100%;
    gap: var(--group-gap);
    overflow-x: auto;
    border-radius: var(--radius-full);
    padding: 0.25rem;
    background: var(--color-surface);
    scrollbar-width: none;
  }

  .device-tabs::-webkit-scrollbar {
    display: none;
  }

  .device-button {
    display: flex;
    min-height: 2.75rem;
    flex-shrink: 0;
    align-items: center;
    justify-content: center;
    gap: 0.5rem;
    border-radius: var(--radius-pill);
    padding-inline: 0.875rem;
    color: var(--color-text-muted);
    font-size: 0.8125rem;
    font-weight: 700;
    transition:
      border-radius var(--motion-expressive) var(--ease-standard),
      color var(--motion-fast) var(--ease-standard),
      background-color var(--motion-fast) var(--ease-standard);
  }

  .device-button:not(.active):hover,
  .device-button:not(.active):focus-visible {
    color: var(--color-text);
    background: rgb(237 237 237 / 0.12);
  }

  .device-button.active {
    color: var(--color-on-primary);
    background: var(--color-text);
  }

  .device-button.active:hover,
  .device-button.active:focus-visible {
    border-radius: var(--radius-md);
    background: #fff;
  }

  .device-button :global(svg),
  .scroll-arrow :global(svg) {
    width: 1.125rem;
    height: 1.125rem;
  }

  .device-label {
    display: none;
  }

  .scroll-arrows {
    display: none;
    align-items: center;
    gap: var(--group-gap);
    margin-left: auto;
  }

  .scroll-arrow {
    display: flex;
    width: 2.75rem;
    height: 2.75rem;
    align-items: center;
    justify-content: center;
    border-radius: var(--radius-pill);
    color: var(--color-text-subtle);
    background: var(--color-surface);
    transition:
      border-radius var(--motion-expressive) var(--ease-standard),
      color var(--motion-fast) var(--ease-standard),
      background-color var(--motion-fast) var(--ease-standard);
  }

  .scroll-arrow.enabled {
    color: var(--color-text);
  }

  .scroll-arrow.enabled:hover,
  .scroll-arrow.enabled:focus-visible {
    border-radius: var(--radius-md);
    background: var(--color-surface-highest);
  }

  .screenshot-panels {
    position: relative;
    min-height: calc(420px + 1rem);
  }

  .screenshot-strip {
    position: absolute;
    top: 0;
    left: 0;
    display: flex;
    width: 100%;
    gap: 1.25rem;
    overflow-x: auto;
    scroll-behavior: smooth;
    padding-bottom: 1rem;
    opacity: 0;
    pointer-events: none;
    scroll-snap-type: x mandatory;
    transition: opacity var(--motion-normal) var(--ease-standard);
  }

  .screenshot-strip.panel-active {
    position: relative;
    z-index: 1;
    opacity: 1;
    pointer-events: auto;
  }

  .screenshot-item {
    height: 420px;
    flex-shrink: 0;
    scroll-snap-align: start;
  }

  .screenshot-frame {
    height: 100%;
    overflow: hidden;
  }

  .phone-frame {
    border-radius: 2rem;
  }

  .tablet-frame {
    border-radius: 1rem;
  }

  .desktop-frame,
  .tv-frame {
    border-radius: 0.75rem;
  }

  .screenshot-image {
    display: block;
    width: auto;
    height: 100%;
    object-fit: contain;
  }

  .content-pad {
    padding-left: max(1.5rem, calc((100vw - 64rem) / 2 + 1.5rem));
    padding-right: 1.5rem;
    scroll-padding-left: max(1.5rem, calc((100vw - 64rem) / 2 + 1.5rem));
  }

  .scrollbar-hide {
    -ms-overflow-style: none;
    scrollbar-width: none;
  }

  .scrollbar-hide::-webkit-scrollbar {
    display: none;
  }

  @media (min-width: 560px) {
    .device-label {
      display: inline;
    }
  }

  @media (min-width: 768px) {
    .scroll-arrows {
      display: flex;
    }
  }

  @media (min-width: 1024px) {
    .screenshot-panels {
      min-height: calc(500px + 1rem);
    }

    .screenshot-item {
      height: 500px;
    }
  }
</style>
