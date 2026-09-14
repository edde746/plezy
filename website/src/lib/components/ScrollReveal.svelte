<script lang="ts">
  import type { Snippet } from 'svelte';

  let { children, delay = 0, class: className = '' }: { children: Snippet; delay?: number; class?: string } = $props();

  let el: HTMLDivElement | undefined = $state();
  let visible = $state(true);

  $effect(() => {
    if (!el) return;

    visible = true;
    if (
      typeof IntersectionObserver === 'undefined' ||
      window.matchMedia('(prefers-reduced-motion: reduce)').matches
    ) {
      return;
    }

    const rect = el.getBoundingClientRect();
    const hasGeometry = rect.width > 0 && rect.height > 0;
    const isInViewport =
      hasGeometry &&
      rect.bottom > 0 &&
      rect.right > 0 &&
      rect.top < window.innerHeight &&
      rect.left < window.innerWidth;
    if (!hasGeometry || isInViewport) return;

    let observer: IntersectionObserver | undefined;
    try {
      observer = new IntersectionObserver(
        ([entry]) => {
          if (entry?.isIntersecting) {
            visible = true;
            observer?.disconnect();
          }
        },
        { threshold: 0.1 }
      );
      observer.observe(el);
      visible = false;
    } catch {
      observer?.disconnect();
      visible = true;
      return;
    }

    return () => observer?.disconnect();
  });
</script>

<div
  bind:this={el}
  class="{className} scroll-reveal"
  style="opacity: {visible ? 1 : 0}; transform: translateY({visible ? 0 : 16}px); transition-delay: {delay}ms;"
>
  {@render children()}
</div>

<style>
  .scroll-reveal {
    transition:
      opacity var(--motion-expressive) var(--ease-standard),
      transform var(--motion-expressive) var(--ease-standard);
  }

  @media (prefers-reduced-motion: reduce) {
    .scroll-reveal {
      opacity: 1 !important;
      transform: none !important;
      transition: none !important;
    }
  }
</style>
