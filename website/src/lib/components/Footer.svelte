<script lang="ts">
  import Logo from './Logo.svelte';
</script>

<footer class="site-footer">
  <div class="footer-content">
    <div class="footer-brand">
      <span class="footer-logo"><Logo /></span>
      <span>Plezy</span>
    </div>

    <nav class="footer-nav" aria-label="Footer navigation">
      <a href="https://github.com/edde746/plezy" target="_blank" rel="noopener noreferrer">GitHub</a>
      <a href="/privacy">Privacy</a>
      <a href="#home">Back to top</a>
    </nav>
  </div>
</footer>

<style>
  .site-footer {
    padding: clamp(3rem, 7vw, 5rem) var(--page-gutter);
  }

  .footer-content {
    display: flex;
    width: min(100%, var(--page-width));
    flex-direction: column;
    align-items: flex-start;
    justify-content: space-between;
    gap: 1.5rem;
    margin-inline: auto;
  }

  .footer-brand {
    display: flex;
    align-items: center;
    gap: 0.625rem;
    color: var(--color-text-muted);
    font-weight: 700;
  }

  .footer-logo :global(svg) {
    width: 1.5rem;
    height: 1.5rem;
  }

  .footer-nav {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    gap: 0.25rem;
    color: var(--color-text-muted);
    font-size: 0.8125rem;
    font-weight: 600;
  }

  .footer-nav a {
    border-radius: var(--radius-full);
    padding: 0.625rem 0.875rem;
    transition:
      color var(--motion-fast) var(--ease-standard),
      background-color var(--motion-fast) var(--ease-standard);
  }

  .footer-nav a:hover,
  .footer-nav a:focus-visible {
    color: var(--color-text);
    background: rgb(237 237 237 / 0.12);
    outline: none;
  }

  @media (min-width: 640px) {
    .footer-content {
      flex-direction: row;
      align-items: center;
    }
  }
</style>
