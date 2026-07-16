<script lang="ts">
  import { page } from '$app/state';
  import { faqs } from '$lib/content/faqs';
  import MinusIcon from '~icons/heroicons/minus';
  import PlusIcon from '~icons/heroicons/plus';
  import ScrollReveal from "./ScrollReveal.svelte";

  const hash = $derived(page.url.hash.slice(1));
  const hashIndex = $derived(faqs.findIndex((f) => f.id === hash));

  let openIndex = $state<number | null>(null);

  $effect(() => {
    if (hashIndex !== -1) {
      openIndex = hashIndex;
      requestAnimationFrame(() => {
        document.getElementById(hash)?.scrollIntoView({ behavior: "smooth", block: "center" });
      });
    }
  });

  function toggle(index: number) {
    openIndex = openIndex === index ? null : index;
  }
</script>

<section id="faq" class="faq-section">
  <ScrollReveal>
    <p class="section-label">FAQ</p>
    <h2 class="section-heading">Common questions</h2>
    <p class="section-description">Everything you need to know about Plezy.</p>
  </ScrollReveal>

  <div class="faq-list">
    {#each faqs as faq, i}
      <ScrollReveal delay={i * 50} class="faq-row">
        <div id={faq.id} class="flat-card faq-card">
          <button
            type="button"
            class="faq-toggle"
            onclick={() => toggle(i)}
            aria-expanded={openIndex === i}
            aria-controls={`${faq.id}-answer`}
          >
            <span class="faq-question">{faq.question}</span>
            <span class="faq-icon">
              {#if openIndex === i}
                <MinusIcon />
              {:else}
                <PlusIcon />
              {/if}
            </span>
          </button>
          <div
            id={`${faq.id}-answer`}
            class="faq-answer"
            class:open={openIndex === i}
            aria-hidden={openIndex !== i}
            inert={openIndex !== i}
          >
            <div>
              <div class="faq-answer-content">
                {@html faq.answer}
              </div>
            </div>
          </div>
        </div>
      </ScrollReveal>
    {/each}
  </div>
</section>

<style>
  .faq-section {
    width: min(100%, var(--page-width));
    margin-inline: auto;
    padding: clamp(4rem, 9vw, 8rem) var(--page-gutter);
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
    margin-bottom: clamp(2.5rem, 6vw, 4.5rem);
    color: var(--color-text-muted);
    font-size: clamp(1rem, 2vw, 1.125rem);
    line-height: 1.7;
  }

  .faq-list {
    display: flex;
    flex-direction: column;
    gap: var(--group-gap);
  }

  .faq-card {
    overflow: hidden;
    border-radius: var(--radius-xs);
    background: var(--color-surface);
    transition: background-color var(--motion-normal) var(--ease-standard);
  }

  .faq-card:has(.faq-toggle[aria-expanded="true"]) {
    background: var(--color-surface-high);
  }

  :global(.faq-row:first-child) .faq-card {
    border-radius: var(--radius-lg) var(--radius-lg) var(--radius-xs) var(--radius-xs);
  }

  :global(.faq-row:last-child) .faq-card {
    border-radius: var(--radius-xs) var(--radius-xs) var(--radius-lg) var(--radius-lg);
  }

  .faq-toggle {
    display: flex;
    width: 100%;
    min-height: 4.5rem;
    align-items: center;
    justify-content: space-between;
    gap: 1rem;
    padding: 0.75rem 1rem 0.75rem clamp(1rem, 4vw, 1.5rem);
    border-radius: inherit;
    text-align: left;
    transition: background-color var(--motion-fast) var(--ease-standard);
  }

  .faq-toggle:not([aria-expanded="true"]):hover {
    background: rgb(237 237 237 / 0.08);
  }

  .faq-toggle:focus-visible {
    background: rgb(237 237 237 / 0.14);
    outline: none;
  }

  .faq-question {
    font-family: var(--font-display);
    font-size: clamp(0.9375rem, 2vw, 1.0625rem);
    font-weight: 700;
    letter-spacing: -0.01em;
  }

  .faq-icon {
    display: flex;
    width: 2.5rem;
    height: 2.5rem;
    flex-shrink: 0;
    align-items: center;
    justify-content: center;
    border-radius: var(--radius-full);
    color: var(--color-text);
    background: rgb(237 237 237 / 0.1);
    transition:
      border-radius var(--motion-normal) var(--ease-standard),
      background-color var(--motion-fast) var(--ease-standard);
  }

  .faq-toggle[aria-expanded="true"] .faq-icon {
    border-radius: var(--radius-md);
    background: rgb(237 237 237 / 0.16);
  }

  .faq-icon :global(svg) {
    width: 1.125rem;
    height: 1.125rem;
  }

  .faq-answer {
    display: grid;
    grid-template-rows: 0fr;
    transition: grid-template-rows var(--motion-normal) var(--ease-standard);
  }

  .faq-answer.open {
    grid-template-rows: 1fr;
  }

  .faq-answer > div {
    min-height: 0;
    overflow: hidden;
  }

  .faq-answer-content {
    max-width: 50rem;
    padding: 0 clamp(1rem, 4vw, 1.5rem) 1.5rem;
    color: var(--color-text-muted);
    font-size: 0.875rem;
    line-height: 1.7;
  }

  .faq-answer-content :global(a) {
    color: var(--color-text);
    text-decoration: underline;
    text-decoration-color: var(--color-text-subtle);
    text-underline-offset: 0.2em;
  }

  .faq-answer-content :global(a:hover),
  .faq-answer-content :global(a:focus-visible) {
    text-decoration-color: var(--color-text);
    outline: none;
  }
</style>
