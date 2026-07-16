<script lang="ts">
  import type { Snippet } from 'svelte';

  let { children, delay = 0, class: className = '' }: { children: Snippet; delay?: number; class?: string } = $props();

  let el: HTMLDivElement | undefined = $state();
  let visible = $state(false);

  $effect(() => {
    if (!el) return;
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          visible = true;
          observer.disconnect();
        }
      },
      { threshold: 0.1 }
    );
    observer.observe(el);
    return () => observer.disconnect();
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
      transform: none !important;
    }
  }
</style>
