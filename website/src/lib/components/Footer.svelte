<script lang="ts">
  import Logo from './Logo.svelte';
</script>

<footer class="site-footer">
  <div class="footer-inner">
    <!-- Gradient rule -->
    <div class="gradient-rule"></div>

    <div class="footer-content">
      <!-- Logo + name -->
      <div class="footer-brand">
        <span class="footer-logo"><Logo /></span>
        <span>Plezy</span>
      </div>

      <!-- Links -->
      <nav class="footer-nav">
        <a href="https://github.com/edde746/plezy" target="_blank" rel="noopener noreferrer">GitHub</a>
        <a href="/privacy">Privacy Policy</a>
      </nav>
    </div>
  </div>
</footer>

<style>
  .site-footer {
    padding: 2.5rem 1.5rem;
  }

  .footer-inner {
    max-width: 64rem;
    margin-inline: auto;
  }

  .gradient-rule {
    height: 1px;
    margin-bottom: 2rem;
    background: linear-gradient(to right, transparent, var(--color-border), transparent);
  }

  .footer-content {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: space-between;
    gap: 2rem;
  }

  .footer-brand {
    display: flex;
    align-items: center;
    gap: 0.625rem;
    color: var(--color-text-muted);
    font-weight: 500;
  }

  .footer-logo :global(svg) {
    width: 1.75rem;
    height: 1.75rem;
  }

  .footer-nav {
    display: flex;
    align-items: center;
    gap: 2rem;
    color: var(--color-text-muted);
    font-size: 0.875rem;
    line-height: 1.25rem;
  }

  .footer-nav a {
    transition: color 150ms ease;
  }

  .footer-nav a:hover {
    color: var(--color-text);
  }

  @media (min-width: 640px) {
    .site-footer {
      padding-block: 4rem;
    }

    .gradient-rule {
      margin-bottom: 3rem;
    }

    .footer-content {
      flex-direction: row;
    }
  }
</style>
