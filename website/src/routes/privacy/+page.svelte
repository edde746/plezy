<script lang="ts">
  import Logo from '$lib/components/Logo.svelte';

  const title = 'Privacy Policy - Plezy';
  const description = 'How Plezy stores data on your device and shares data when you use connected services.';
  const url = 'https://plezy.app/privacy';
</script>

<svelte:head>
  <title>{title}</title>
  <meta name="description" content={description} />
  <link rel="canonical" href={url} />

  <meta property="og:type" content="website" />
  <meta property="og:site_name" content="Plezy" />
  <meta property="og:title" content={title} />
  <meta property="og:description" content={description} />
  <meta property="og:url" content={url} />
  <meta property="og:image" content="https://plezy.app/og/plezy-social.png" />

  <meta name="twitter:card" content="summary_large_image" />
  <meta name="twitter:title" content={title} />
  <meta name="twitter:description" content={description} />
  <meta name="twitter:image" content="https://plezy.app/og/plezy-social.png" />
</svelte:head>

<article class="privacy-article">
  <a href="/" class="back-link">
    <span class="back-logo"><Logo /></span>
    <span>Back to Plezy</span>
  </a>

  <h1>Privacy Policy</h1>
  <p class="last-updated">Last updated: July 24, 2026</p>

  <div class="prose">
    <section aria-labelledby="overview">
      <h2 id="overview">Overview</h2>
      <p>
        Plezy is a third-party Plex and Jellyfin client. Most account, library, playback, streaming, and
        download traffic travels directly between your device and the services or media servers you choose.
        Plezy servers are not in the normal media-streaming path.
      </p>
      <p>
        We do not sell personal data or use it for advertising. The Plezy website does not use analytics or
        advertising trackers.
      </p>
    </section>

    <section aria-labelledby="device-data">
      <h2 id="device-data">Data on your device</h2>
      <p>
        To provide its features, Plezy saves server addresses, access tokens and other sign-in data, profiles,
        settings, integration sessions, playback state, downloads, and cached artwork on your device. Sensitive
        credentials use platform-provided protected storage where available. TV versions may also publish
        Continue Watching titles, progress, and artwork to the system home screen.
      </p>
      <p>
        Downloads in a custom folder and copies kept by the operating system or a backup provider may remain
        outside storage controlled by Plezy.
      </p>
    </section>

    <section aria-labelledby="connections">
      <h2 id="connections">Connections and third parties</h2>
      <p>
        When you use a connected feature, Plezy sends the data needed for it to the relevant provider. This can
        include authentication data, searches, library requests, media identifiers, playback state, and changes
        you make. Providers can include Plex, the Jellyfin or Seerr server you select, TMDB, Trakt, Simkl,
        MyAnimeList, AniList, Discord, GitHub, jsDelivr, and artwork hosts returned by those services. They also
        receive ordinary network information such as your IP address and user agent, and handle data under their
        own privacy terms.
      </p>
      <p>
        Jellyfin and Companion Remote can send discovery traffic on your local network. If you use an external
        player, that app receives the media URL, which may contain a server access credential, together with
        playback details. TV home-screen features can automatically fetch artwork from your media server. A
        server or relay you configure may use HTTP instead of HTTPS.
      </p>
    </section>

    <section aria-labelledby="plezy-services">
      <h2 id="plezy-services">Optional Plezy services</h2>
      <p>
        Plezy-hosted services are used for Watch Together, MyAnimeList and AniList sign-in handoff, temporary
        Discord artwork, optional crash reporting, and support logs you explicitly upload. Watch Together
        exchanges room, participant, server and media identifiers, and playback timing; it does not carry the
        media stream or your media-server credentials. A custom relay is controlled by its operator.
      </p>
      <p>
        Crash reports can include app, device, error, and recent diagnostic information. Support logs may still
        contain sensitive details after automatic redaction, and anyone with the retrieval ID can access an
        uploaded log while it is available. Discord artwork is available through a temporary public URL.
        Plezy-hosted services also keep limited operational logs for security and reliability.
      </p>
    </section>

    <section aria-labelledby="choices">
      <h2 id="choices">Your choices</h2>
      <p>
        You can remove media-server and tracker connections, disable crash reporting, update checks, scrobbling,
        Companion Remote, Discord Rich Presence, and external-player routing, or leave Watch Together. You can
        delete downloads, clear the artwork cache, remove profiles, or delete app data. Support-log uploads are
        always explicit. Removing local data does not remove copies already held by a connected service, custom
        storage provider, external app, system home screen, or backup.
      </p>
    </section>

    <section aria-labelledby="retention-security">
      <h2 id="retention-security">Retention and security</h2>
      <p>
        Local connection and profile data remains until you remove it or delete app data. Downloads have no
        automatic expiry. Cached artwork is removed through cache maintenance or the Clear Cache action, and TV
        home-screen data remains until a later update or clear succeeds. Plezy-hosted crash events are configured
        for up to 90 days, support logs can be retrieved for three days, and Discord artwork is available for no
        more than three hours. OAuth handoffs and inactive Watch Together rooms are short-lived. Other providers
        set their own retention periods.
      </p>
      <p>
        Plezy uses HTTPS for its hosted services and supported cloud providers, limits sensitive uploads, and
        redacts known secrets from diagnostics. No system is completely secure, and user-configured servers,
        relays, external players, storage locations, and platform backups remain under their respective
        operators’ control.
      </p>
    </section>

    <section aria-labelledby="contact">
      <h2 id="contact">Contact and changes</h2>
      <p>
        For privacy questions or requests, contact us through the
        <a href="https://github.com/edde746/plezy" target="_blank" rel="noopener noreferrer">Plezy GitHub project</a>.
        GitHub activity is public, so do not include passwords, access tokens, support-log IDs, or other sensitive
        information. Material changes to this policy will be posted here with a new date.
      </p>
    </section>
  </div>
</article>

<style>
  .privacy-article {
    width: min(100%, 48rem);
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
  }

  .back-logo :global(img) {
    width: 1.375rem;
    height: 1.375rem;
  }

  h1 {
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
    color: var(--color-text-muted);
    font-size: 1rem;
    line-height: 1.8;
  }

  .prose > section + section {
    margin-top: 3rem;
  }

  .prose h2 {
    margin-bottom: 1rem;
    color: var(--color-text);
    font-family: var(--font-display);
    font-size: clamp(1.5rem, 4vw, 2rem);
    font-weight: 700;
    letter-spacing: -0.025em;
    line-height: 1.2;
  }

  .prose p + p {
    margin-top: 1.125rem;
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
  }
</style>
