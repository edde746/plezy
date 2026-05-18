<script lang="ts">
  import ScrollReveal from './ScrollReveal.svelte';
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

  const devices: { id: DeviceType; icon: DeviceIconComponent; label: string }[] = [
    { id: 'phone', icon: DevicePhoneIcon, label: 'Phone' },
    { id: 'tablet', icon: DeviceTabletIcon, label: 'Tablet' },
    { id: 'desktop', icon: DesktopIcon, label: 'Desktop' },
    { id: 'tv', icon: TvIcon, label: 'TV' },
  ];

  const phoneShots = [
    { image: phoneHomeImage, alt: 'Plezy home screen' },
    { image: phoneLibraryImage, alt: 'Plezy library view' },
    { image: phoneMdImage, alt: 'Plezy media details' },
    { image: phoneSearchImage, alt: 'Plezy search' },
  ];

  const tabletShots = [
    { image: tabletHomeImage, alt: 'Plezy on tablet - home' },
    { image: tabletLibraryImage, alt: 'Plezy on tablet - library' },
    { image: tabletMdImage, alt: 'Plezy on tablet - media details' },
    { image: tabletPlayerImage, alt: 'Plezy on tablet - video player' },
  ];

  const desktopShots = [
    { image: desktopHomeImage, alt: 'Plezy on desktop - home' },
    { image: desktopLibraryImage, alt: 'Plezy on desktop - library' },
    { image: desktopMdImage, alt: 'Plezy on desktop - media details' },
    { image: desktopPlayerImage, alt: 'Plezy on desktop - video player' },
  ];

  const tvShots = [
    { image: tvHomeImage, alt: 'Plezy on TV - home' },
    { image: tvLibraryImage, alt: 'Plezy on TV - library' },
    { image: tvMdImage, alt: 'Plezy on TV - media details' },
    { image: tvPlayerImage, alt: 'Plezy on TV - video player' },
  ];

  const screenshots: Record<
    DeviceType,
    {
      shots: typeof phoneShots;
      frameClass: string;
      sizes: string;
      ariaLabel: string;
    }
  > = {
    phone: {
      shots: phoneShots,
      frameClass: 'phone-frame',
      sizes: '(min-width: 1024px) 214px, 187px',
      ariaLabel: 'Phone screenshots',
    },
    tablet: {
      shots: tabletShots,
      frameClass: 'tablet-frame',
      sizes: '(min-width: 1024px) 768px, 672px',
      ariaLabel: 'Tablet screenshots',
    },
    desktop: {
      shots: desktopShots,
      frameClass: 'desktop-frame',
      sizes: '(min-width: 1024px) 768px, 672px',
      ariaLabel: 'Desktop screenshots',
    },
    tv: {
      shots: tvShots,
      frameClass: 'tv-frame',
      sizes: '(min-width: 1024px) 854px, 747px',
      ariaLabel: 'TV screenshots',
    },
  };

  let active: DeviceType = $state('phone');
  let scrollContainer: HTMLElement | undefined = $state();
  let canScrollLeft = $state(false);
  let canScrollRight = $state(false);
  let intendedScrollLeft: number | undefined;

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
    scrollContainer.scrollTo({ left: target, behavior: 'smooth' });
  }

  $effect(() => {
    // Re-check scroll state when active tab changes.
    const currentActive = active;
    const el = document.getElementById(`screenshots-${currentActive}-panel`);

    intendedScrollLeft = undefined;
    scrollContainer = el ?? undefined;

    if (el) {
      // Double rAF ensures browser has computed layout after DOM update
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

<section id="screenshots" class="screenshots-section">
  <div class="screenshots-header">
    <ScrollReveal>
      <p class="section-label">Preview</p>
      <h2 class="section-heading">Designed with care</h2>
      <p class="section-description">An experience that feels right at home on every device.</p>

      <div class="screenshot-controls">
        <!-- Device tabs -->
        <div class="device-tabs" role="group" aria-label="Screenshot device">
          {#each devices as device}
            {@const DeviceIcon = device.icon}
            <button
              type="button"
              onclick={() => active = device.id}
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

        <!-- Scroll arrows -->
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
    </ScrollReveal>
  </div>

  <div class="screenshot-panels">
    {#each devices as device (device.id)}
      {@const screenshot = screenshots[device.id]}
      <div
        id={`screenshots-${device.id}-panel`}
        role="region"
        aria-label={screenshot.ariaLabel}
        aria-hidden={active !== device.id}
        class="screenshot-strip scrollbar-hide content-pad"
        class:panel-active={active === device.id}
        onscroll={() => {
          if (active === device.id) updateScrollState();
        }}
      >
        {#each screenshot.shots as shot}
          <div class="screenshot-item">
            <div class={`screenshot-frame ${screenshot.frameClass}`}>
              <enhanced:img
                src={shot.image}
                alt={shot.alt}
                loading="eager"
                class="screenshot-image"
                sizes={screenshot.sizes}
              />
            </div>
          </div>
        {/each}
      </div>
    {/each}
  </div>
</section>

<style>
  .screenshots-section {
    overflow: hidden;
    padding-block: 4rem;
  }

  .screenshots-header {
    max-width: 64rem;
    margin-inline: auto;
    margin-bottom: 2rem;
    padding-inline: 1.5rem;
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
    margin-bottom: 1.5rem;
    color: var(--color-text-muted);
    font-size: 1.125rem;
    line-height: 1.75rem;
  }

  .screenshot-controls {
    display: flex;
    align-items: center;
    gap: 1rem;
  }

  .device-tabs {
    display: flex;
    width: fit-content;
    gap: 0.25rem;
    border-radius: 0.75rem;
    background: rgb(255 255 255 / 0.04);
    padding: 0.25rem;
  }

  .device-button {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    border-radius: 0.5rem;
    padding: 0.5rem 1rem;
    color: var(--color-text-muted);
    font-size: 0.875rem;
    font-weight: 500;
    line-height: 1.25rem;
    transition: background-color 150ms ease, color 150ms ease;
  }

  .device-button:not(.active):hover {
    color: color-mix(in srgb, var(--color-text) 80%, transparent);
  }

  .device-button.active {
    color: var(--color-text);
    background: rgb(255 255 255 / 0.1);
  }

  .device-button :global(svg),
  .scroll-arrow :global(svg) {
    width: 1rem;
    height: 1rem;
  }

  .device-label {
    display: none;
  }

  .scroll-arrows {
    display: none;
    align-items: center;
    gap: 0.25rem;
    margin-left: auto;
  }

  .scroll-arrow {
    display: flex;
    width: 2rem;
    height: 2rem;
    align-items: center;
    justify-content: center;
    border-radius: 0.5rem;
    background: rgb(255 255 255 / 0.04);
    color: color-mix(in srgb, var(--color-text-muted) 30%, transparent);
    transition: background-color 150ms ease, color 150ms ease;
  }

  .scroll-arrow.enabled {
    color: var(--color-text);
  }

  .scroll-arrow.enabled:hover {
    background: rgb(255 255 255 / 0.1);
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
    opacity: 0;
    padding-bottom: 1rem;
    pointer-events: none;
    transition: opacity 220ms ease;
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
    border: 1px solid color-mix(in srgb, var(--color-border) 40%, transparent);
    box-shadow: 0 25px 50px -12px rgb(0 0 0 / 0.5);
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

  .tv-frame {
    border-width: 2px;
    border-color: color-mix(in srgb, var(--color-border) 30%, transparent);
    background: #000;
  }

  .screenshot-image {
    display: block;
    width: auto;
    height: 100%;
  }

  .content-pad {
    /* Left padding aligns with max-w-5xl (64rem) + px-6 */
    padding-left: max(1.5rem, calc((100vw - 64rem) / 2 + 1.5rem));
    padding-right: 1.5rem;
  }

  .scrollbar-hide {
    -ms-overflow-style: none;
    scrollbar-width: none;
  }
  .scrollbar-hide::-webkit-scrollbar {
    display: none;
  }

  @media (min-width: 640px) {
    .screenshots-section {
      padding-block: 6rem;
    }

    .screenshots-header {
      margin-bottom: 3rem;
    }

    .section-description {
      margin-bottom: 2.5rem;
    }

    .device-label {
      display: inline;
    }
  }

  @media (min-width: 768px) {
    .screenshots-section {
      padding-block: 8rem;
    }

    .section-heading {
      font-size: 3rem;
      line-height: 1;
    }

    .scroll-arrows {
      display: flex;
    }
  }

  @media (min-width: 1024px) {
    .screenshot-panels {
      min-height: calc(480px + 1rem);
    }

    .screenshot-item {
      height: 480px;
    }
  }
</style>
