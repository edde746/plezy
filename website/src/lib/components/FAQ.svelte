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
      <ScrollReveal delay={i * 50}>
        <div id={faq.id} class="glass-card faq-card">
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
    max-width: 64rem;
    margin-inline: auto;
    padding: 4rem 1.5rem;
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
    margin-bottom: 2.5rem;
    color: var(--color-text-muted);
    font-size: 1.125rem;
    line-height: 1.75rem;
  }

  .faq-list {
    display: flex;
    flex-direction: column;
    gap: 0.625rem;
  }

  .faq-card {
    border-radius: 1rem;
  }

  .faq-toggle {
    display: flex;
    width: 100%;
    align-items: center;
    justify-content: space-between;
    gap: 1rem;
    padding: 1rem 1.5rem;
    text-align: left;
  }

  .faq-question {
    font-weight: 500;
  }

  .faq-icon {
    flex-shrink: 0;
    width: 1.25rem;
    height: 1.25rem;
    color: var(--color-accent);
  }

  .faq-icon :global(svg) {
    width: 1.25rem;
    height: 1.25rem;
  }

  .faq-answer {
    display: grid;
    grid-template-rows: 0fr;
    transition: grid-template-rows 200ms ease;
  }
  .faq-answer.open {
    grid-template-rows: 1fr;
  }
  .faq-answer > div {
    overflow: hidden;
    min-height: 0;
  }

  .faq-answer-content {
    padding: 0 1.5rem 1rem;
    color: var(--color-text-muted);
    font-size: 0.875rem;
    line-height: 1.625;
  }

  .faq-answer-content :global(a) {
    color: var(--color-accent);
  }

  .faq-answer-content :global(a:hover) {
    text-decoration: underline;
  }

  @media (min-width: 640px) {
    .faq-section {
      padding-block: 6rem;
    }

    .section-description {
      margin-bottom: 4rem;
    }
  }

  @media (min-width: 768px) {
    .faq-section {
      padding-block: 8rem;
    }

    .section-heading {
      font-size: 3rem;
      line-height: 1;
    }
  }
</style>
