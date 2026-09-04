<script lang="ts">
  import type { Snippet } from 'svelte';
  import ScrollReveal from './ScrollReveal.svelte';

  let {
    label,
    heading,
    description,
    headingWidth = '12ch',
    descriptionGap = 'clamp(2.5rem, 6vw, 4.5rem)',
    children,
  }: {
    label: string;
    heading: string;
    description: string;
    /** CSS max-width for the heading. */
    headingWidth?: string;
    /** Gap below the description. */
    descriptionGap?: string;
    children?: Snippet;
  } = $props();
</script>

<ScrollReveal>
  <p class="section-label">{label}</p>
  <h2 class="section-heading" style="max-width: {headingWidth};">{heading}</h2>
  <p class="section-description" style="margin-bottom: {descriptionGap};">{description}</p>
  {@render children?.()}
</ScrollReveal>

<style>
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
    color: var(--color-text-muted);
    font-size: clamp(1rem, 2vw, 1.125rem);
    line-height: 1.7;
  }
</style>
