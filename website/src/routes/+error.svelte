<script lang="ts">
  import { page } from '$app/state';
  import Logo from '$lib/components/Logo.svelte';
</script>

<svelte:head>
  <title>{page.status} - Plezy</title>
  <meta name="robots" content="noindex" />
</svelte:head>

<div class="error-page">
  <div class="error-card">
    <span class="error-logo"><Logo /></span>

    <h1 class="error-code">{page.status}</h1>
    <p class="error-message">{page.error?.message || 'Page not found'}</p>

    <a
      href="/"
      class="home-link"
    >
      Back to home
    </a>
  </div>
</div>

<style>
  .error-page {
    display: flex;
    min-height: 100dvh;
    align-items: center;
    justify-content: center;
    padding: var(--page-gutter);
  }

  .error-card {
    display: flex;
    width: min(100%, 32rem);
    flex-direction: column;
    align-items: center;
    border-radius: var(--radius-xl);
    padding: clamp(2rem, 8vw, 4rem);
    background: var(--color-surface);
    text-align: center;
  }

  .error-logo {
    display: flex;
    width: 5rem;
    height: 5rem;
    align-items: center;
    justify-content: center;
    margin-bottom: 2rem;
    border-radius: var(--radius-lg);
    background: var(--color-surface-highest);
  }

  .error-logo :global(svg) {
    width: 2.5rem;
    height: 2.5rem;
  }

  .error-code {
    margin-bottom: 0.5rem;
    font-family: var(--font-display);
    font-size: clamp(3.5rem, 16vw, 6rem);
    font-weight: 700;
    letter-spacing: -0.06em;
    line-height: 1;
  }

  .error-message {
    margin-bottom: 2rem;
    color: var(--color-text-muted);
  }

  .home-link {
    display: inline-flex;
    min-height: 3rem;
    align-items: center;
    border-radius: var(--radius-pill);
    padding-inline: 1.25rem;
    color: var(--color-on-primary);
    background: var(--color-text);
    font-size: 0.8125rem;
    font-weight: 700;
    transition:
      border-radius var(--motion-expressive) var(--ease-standard),
      background-color var(--motion-fast) var(--ease-standard);
  }

  .home-link:hover,
  .home-link:focus-visible {
    border-radius: var(--radius-md);
    background: #fff;
    outline: none;
  }
</style>
