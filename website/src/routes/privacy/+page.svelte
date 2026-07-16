<script lang="ts">
  import Logo from '$lib/components/Logo.svelte';
</script>

<svelte:head>
  <title>Privacy Policy - Plezy</title>
  <meta name="description" content="Learn how Plezy handles your data when connecting to Plex and Jellyfin. Our privacy policy covers authentication, crash diagnostics, local network information, and data storage practices." />
  <link rel="canonical" href="https://plezy.app/privacy" />

  <meta property="og:type" content="website" />
  <meta property="og:site_name" content="Plezy" />
  <meta property="og:title" content="Privacy Policy - Plezy" />
  <meta property="og:description" content="Learn how Plezy handles your data. Our privacy policy covers authentication, crash diagnostics, local network information, and data storage practices." />
  <meta property="og:url" content="https://plezy.app/privacy" />
  <meta property="og:image" content="https://plezy.app/og/plezy-social.png" />

  <meta name="twitter:card" content="summary_large_image" />
  <meta name="twitter:title" content="Privacy Policy - Plezy" />
  <meta name="twitter:description" content="Learn how Plezy handles your data. Our privacy policy covers authentication, crash diagnostics, local network information, and data storage practices." />
  <meta name="twitter:image" content="https://plezy.app/og/plezy-social.png" />
</svelte:head>

<article class="privacy-article">
  <a href="/" class="back-link">
    <span class="back-logo"><Logo /></span>
    <span>Back to Plezy</span>
  </a>

  <h1 class="privacy-heading">Privacy Policy</h1>
  <p class="last-updated">Last Updated: May 2, 2026</p>

  <div class="prose">
    <h2>Introduction</h2>
    <p>Plezy ("we", "our", or "the app") is a third-party client for Plex and Jellyfin that allows you to access and stream content from your media server. This privacy policy explains how we handle your information when you use our app.</p>

    <h2>Information We Collect</h2>

    <h3>Authentication Information</h3>
    <p>When you sign in to Plezy, we collect and process the following information depending on which service you connect:</p>
    <ul>
      <li>Plex: authentication tokens, account username, and server connection information</li>
      <li>Jellyfin: server URL, access token, username, and user ID</li>
    </ul>

    <h3>Crash and Diagnostic Data</h3>
    <p>To help us identify and fix bugs, the app automatically collects:</p>
    <ul>
      <li>Crash reports and error stack traces</li>
      <li>Application Not Responding (ANR) events</li>
      <li>Device model, OS version, and app version</li>
      <li>Diagnostic breadcrumbs (e.g. playback events leading up to a crash)</li>
    </ul>
    <p>This data is sent to our self-hosted error tracking server (bugs.plezy.app). Sensitive information such as authentication tokens and server URLs is automatically stripped before transmission.</p>

    <h3>Local Network Information</h3>
    <p>To connect to your media server on your local network, we may access:</p>
    <ul>
      <li>Local network device discovery information</li>
      <li>IP addresses of media servers on your network</li>
    </ul>

    <h3>Usage Information</h3>
    <p>The app stores locally on your device:</p>
    <ul>
      <li>Your authentication session</li>
      <li>App preferences and settings</li>
      <li>Recently accessed content history</li>
    </ul>

    <h2>How We Use Your Information</h2>
    <p>We use the collected information solely to:</p>
    <ul>
      <li>Authenticate you with your Plex or Jellyfin account</li>
      <li>Connect to and communicate with your media server</li>
      <li>Display your media library and stream content</li>
      <li>Maintain your session and app preferences</li>
    </ul>

    <h2>Data Storage and Security</h2>
    <ul>
      <li>Authentication tokens are stored securely on your device using platform-specific secure storage mechanisms</li>
      <li>App preferences are stored locally on your device</li>
      <li>Crash and diagnostic data is sent to our self-hosted error tracking server (bugs.plezy.app) &mdash; no third-party services receive this data</li>
      <li>All other communication is directly between your device and your media server, or with Plex's authentication services when signing in with Plex</li>
    </ul>

    <h2>Third-Party Services</h2>

    <h3>Plex</h3>
    <p>Plezy uses Plex's authentication and media services. When you use this app:</p>
    <ul>
      <li>You authenticate directly with Plex's servers</li>
      <li>Your media streaming occurs between your device and your Plex Media Server</li>
      <li>Plex's own privacy policy applies to their services: <a href="https://www.plex.tv/about/privacy-legal/" target="_blank" rel="noopener noreferrer">plex.tv/about/privacy-legal</a></li>
    </ul>
    <p>We do not control and are not responsible for Plex's data practices.</p>

    <h3>Jellyfin</h3>
    <p>Plezy can connect to your self-hosted Jellyfin server. When you use this app with Jellyfin:</p>
    <ul>
      <li>You authenticate directly with your Jellyfin server using your username and password, or via Quick Connect</li>
      <li>Your media streaming occurs between your device and your Jellyfin server</li>
      <li>No third party (including Plezy) is involved in Jellyfin authentication or playback</li>
    </ul>
    <p>Because Jellyfin is self-hosted, your Jellyfin server's privacy practices are determined by whoever operates it. More information about the Jellyfin project is available at <a href="https://jellyfin.org" target="_blank" rel="noopener noreferrer">jellyfin.org</a>.</p>

    <h3>Litterbox (Discord Rich Presence)</h3>
    <p>When Discord Rich Presence is enabled, media artwork may be temporarily uploaded to:</p>
    <ul>
      <li>Litterbox (litterbox.catbox.moe) &mdash; a temporary file hosting service</li>
    </ul>
    <p>These uploads are necessary because Discord requires publicly accessible image URLs for Rich Presence artwork. Uploaded images automatically expire after 1 hour. This feature is opt-in and disabled by default.</p>

    <h2>Data Sharing</h2>
    <p>We do not:</p>
    <ul>
      <li>Sell your personal information</li>
      <li>Share your information with third parties for marketing purposes</li>
      <li>Transmit your data to our own servers (except crash/diagnostic reports as described above)</li>
      <li>Track your viewing habits outside of local app functionality</li>
    </ul>
    <p>Your data is only shared with:</p>
    <ul>
      <li>Plex services for authentication and media server communication, when signing in with Plex (as required for the app to function)</li>
      <li>Your self-hosted Jellyfin server, when signing in with Jellyfin (as required for the app to function)</li>
    </ul>

    <h2>Your Rights and Choices</h2>
    <p>You can:</p>
    <ul>
      <li>Sign out at any time to remove your authentication session from the device</li>
      <li>Uninstall the app to remove all locally stored data</li>
      <li>Manage your Plex account directly through Plex's services, or your Jellyfin account through your Jellyfin server</li>
    </ul>

    <h2>Children's Privacy</h2>
    <p>Plezy does not knowingly collect personal information from children under 13. The app relies on authentication with Plex or Jellyfin servers, and users must comply with the terms of service and age requirements of whichever service they connect to.</p>

    <h2>Changes to This Privacy Policy</h2>
    <p>We may update this privacy policy from time to time. We will notify users of any material changes by updating the "Last Updated" date at the top of this policy.</p>

    <h2>Data Retention</h2>
    <ul>
      <li>Authentication tokens are retained on your device until you sign out or uninstall the app</li>
      <li>Local preferences and settings are retained until you uninstall the app</li>
      <li>Crash and diagnostic reports are retained on our self-hosted server and automatically pruned based on relevance</li>
    </ul>

    <h2>International Data Transfers</h2>
    <p>As we do not operate backend servers, there are no international data transfers from our side. Any data transfers occur directly between your device and either Plex's services (subject to Plex's privacy policy) or your Jellyfin server (governed by whoever operates it).</p>

    <h2>Legal Compliance</h2>
    <p>This app complies with:</p>
    <ul>
      <li>General Data Protection Regulation (GDPR)</li>
      <li>California Consumer Privacy Act (CCPA)</li>
      <li>Children's Online Privacy Protection Act (COPPA)</li>
      <li>Other applicable privacy laws</li>
    </ul>

    <h2>Your Consent</h2>
    <p>By using Plezy, you consent to this privacy policy and the processing of your information as described herein.</p>
  </div>
</article>

<style>
  .privacy-article {
    width: min(100%, 58rem);
    margin-inline: auto;
    padding: clamp(2rem, 7vw, 6rem) var(--page-gutter) clamp(5rem, 10vw, 9rem);
  }

  .back-link {
    display: inline-flex;
    min-height: 2.75rem;
    align-items: center;
    gap: 0.625rem;
    margin-bottom: clamp(3rem, 8vw, 6rem);
    border-radius: var(--radius-full);
    padding-inline: 0.875rem;
    color: var(--color-text-muted);
    background: var(--color-surface);
    font-size: 0.8125rem;
    font-weight: 700;
    transition:
      color var(--motion-fast) var(--ease-standard),
      background-color var(--motion-fast) var(--ease-standard);
  }

  .back-link:hover,
  .back-link:focus-visible {
    color: var(--color-text);
    background: var(--color-surface-highest);
    outline: none;
  }

  .back-logo :global(svg) {
    width: 1.375rem;
    height: 1.375rem;
  }

  .privacy-heading {
    margin-bottom: 0.75rem;
    font-family: var(--font-display);
    font-size: clamp(2.75rem, 9vw, 5rem);
    font-weight: 700;
    letter-spacing: -0.05em;
    line-height: 1;
  }

  .last-updated {
    margin-bottom: clamp(3rem, 7vw, 5rem);
    color: var(--color-text-muted);
    font-family: var(--font-utility);
    font-size: 0.75rem;
  }

  .prose {
    max-width: 48rem;
    color: var(--color-text-muted);
    font-size: 1rem;
    line-height: 1.8;
  }

  .prose h2 {
    margin-top: 3.5rem;
    margin-bottom: 1rem;
    color: var(--color-text);
    font-family: var(--font-display);
    font-size: clamp(1.5rem, 4vw, 2rem);
    font-weight: 700;
    letter-spacing: -0.025em;
    line-height: 1.2;
  }

  .prose h3 {
    margin-top: 2rem;
    margin-bottom: 0.625rem;
    color: var(--color-text);
    font-family: var(--font-display);
    font-size: 1.0625rem;
    font-weight: 700;
  }

  .prose p {
    margin-bottom: 1.125rem;
  }

  .prose ul {
    margin-bottom: 1.25rem;
    border-radius: var(--radius-lg);
    padding: 1.25rem 1.25rem 1.25rem 2.75rem;
    background: var(--color-surface);
    list-style: disc;
  }

  .prose li + li {
    margin-top: 0.5rem;
  }

  .prose a {
    color: var(--color-text);
    text-decoration: underline;
    text-decoration-color: var(--color-text-subtle);
    text-underline-offset: 0.2em;
  }

  .prose a:hover,
  .prose a:focus-visible {
    text-decoration-color: var(--color-text);
    outline: none;
  }
</style>
