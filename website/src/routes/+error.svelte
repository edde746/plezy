<script lang="ts">
  import { page } from '$app/state';
  import Logo from '$lib/components/Logo.svelte';
</script>

<svelte:head>
  <title>{page.status} - Plezy</title>
  <meta name="robots" content="noindex" />
</svelte:head>

<div class="centered-page">
  <div class="centered-card">
    <span class="card-logo"><Logo /></span>

    <h1 class="error-code">{page.status}</h1>
    <p class="error-message">{page.error?.message || 'Page not found'}</p>

    <a
      href="/"
      class="btn-pill"
    >
      Back to home
    </a>
  </div>
</div>

<style>
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
</style>
