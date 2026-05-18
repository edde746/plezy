<script lang="ts">
  import Hero from '$lib/components/Hero.svelte';
  import Features from '$lib/components/Features.svelte';
  import Screenshots from '$lib/components/Screenshots.svelte';
  import Reviews from '$lib/components/Reviews.svelte';
  import FAQ from '$lib/components/FAQ.svelte';
  import Footer from '$lib/components/Footer.svelte';
  import NoiseOverlay from '$lib/components/NoiseOverlay.svelte';
  import { faqSchemaMainEntity } from '$lib/content/faqs';

  const { data } = $props();

  const title = "Plezy - A Beautiful Plex & Jellyfin Client";
  const description = "Plezy is a beautiful client for Plex and Jellyfin, available on iOS, Android, Android TV, tvOS, Windows, macOS, and Linux. HDR, Dolby Vision, offline downloads, and more.";
  const url = "https://plezy.app/";
  const image = "https://plezy.app/og/plezy-social.png";

  const softwareAppSchema = $derived.by(() => {
    const schema: Record<string, unknown> = {
      "@context": "https://schema.org",
      "@type": "SoftwareApplication",
      "name": "Plezy",
      "description": description,
      "url": "https://plezy.app",
      "applicationCategory": "MultimediaApplication",
      "operatingSystem": "iOS, Android, Android TV, tvOS, Windows, macOS, Linux",
      "offers": [
        {
          "@type": "Offer",
          "url": "https://apps.apple.com/us/app/id6754315964",
          "price": data.appStorePrice ?? "0",
          "priceCurrency": "USD",
          "category": "App Store"
        },
        {
          "@type": "Offer",
          "url": "https://play.google.com/store/apps/details?id=com.edde746.plezy",
          "price": data.playStorePrice ?? "0",
          "priceCurrency": "USD",
          "category": "Google Play"
        },
        {
          "@type": "Offer",
          "url": "https://www.amazon.com/gp/product/B0GK65CVS1",
          "category": "Amazon Appstore"
        },
        {
          "@type": "Offer",
          "url": "https://github.com/edde746/plezy",
          "price": "0",
          "priceCurrency": "USD",
          "category": "GitHub"
        }
      ]
    };

    if (data.aggregateRating) {
      schema.aggregateRating = {
        "@type": "AggregateRating",
        "ratingValue": data.aggregateRating.ratingValue,
        "ratingCount": data.aggregateRating.ratingCount,
        "bestRating": "5",
        "worstRating": "1"
      };
    }

    return schema;
  });

  const faqSchema = {
    "@context": "https://schema.org",
    "@type": "FAQPage",
    "mainEntity": faqSchemaMainEntity
  };
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
  <meta property="og:image" content={image} />

  <meta name="twitter:card" content="summary_large_image" />
  <meta name="twitter:title" content={title} />
  <meta name="twitter:description" content={description} />
  <meta name="twitter:image" content={image} />

  {@html `<script type="application/ld+json">${JSON.stringify(softwareAppSchema)}</script>`}
  {@html `<script type="application/ld+json">${JSON.stringify(faqSchema)}</script>`}
</svelte:head>

<NoiseOverlay />
<Hero />
<Features />
<Screenshots />
<Reviews />
<FAQ />
<Footer />
