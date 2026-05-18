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
    min-height: 100vh;
    align-items: center;
    justify-content: center;
    padding: 4rem 1.5rem;
  }

  .error-card {
    display: flex;
    max-width: 24rem;
    flex-direction: column;
    align-items: center;
    text-align: center;
  }

  .error-logo {
    margin-bottom: 1.5rem;
  }

  .error-logo :global(svg) {
    width: 4rem;
    height: 4rem;
  }

  .error-code {
    margin-bottom: 0.5rem;
    font-size: 3rem;
    font-weight: 700;
    line-height: 1;
  }

  .error-message {
    margin-bottom: 2rem;
    color: var(--color-text-muted);
  }

  .home-link {
    display: inline-flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.75rem 1.25rem;
    border-radius: 9999px;
    background: var(--color-accent);
    color: #fff;
    font-size: 0.875rem;
    font-weight: 600;
    line-height: 1.25rem;
    transition: background-color 150ms ease;
  }

  .home-link:hover {
    background: color-mix(in srgb, var(--color-accent) 90%, transparent);
  }
</style>
