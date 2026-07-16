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
    padding-block: clamp(4rem, 9vw, 8rem);
  }

  .screenshots-header {
    max-width: 64rem;
    margin-inline: auto;
    margin-bottom: clamp(2rem, 5vw, 3.5rem);
    padding-inline: 1.5rem;
  }

  .section-label {
    width: fit-content;
    margin-bottom: 1rem;
    border-radius: var(--radius-full);
    padding: 0.5rem 0.875rem;
    color: var(--color-text-muted);
    background: var(--color-surface);
    font-size: 0.75rem;
    font-weight: 700;
    letter-spacing: 0.03em;
  }

  .section-heading {
    max-width: 12ch;
    margin-bottom: 1rem;
    font-family: var(--font-display);
    font-size: clamp(2.5rem, 7vw, 4.75rem);
    font-weight: 700;
    letter-spacing: -0.045em;
    line-height: 1;
    text-wrap: balance;
  }

  .section-description {
    max-width: 34rem;
    margin-bottom: 2rem;
    color: var(--color-text-muted);
    font-size: clamp(1rem, 2vw, 1.125rem);
    line-height: 1.7;
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
    outline: none;
  }

  .device-button.active {
    color: var(--color-on-primary);
    background: var(--color-text);
  }

  .device-button.active:hover,
  .device-button.active:focus-visible {
    border-radius: var(--radius-md);
    background: #fff;
    outline: none;
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
    outline: none;
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
