<script lang="ts">
  import Hero from '$lib/components/Hero.svelte';
  import Features from '$lib/components/Features.svelte';
  import Screenshots from '$lib/components/Screenshots.svelte';
  import Reviews from '$lib/components/Reviews.svelte';
  import FAQ from '$lib/components/FAQ.svelte';
  import Footer from '$lib/components/Footer.svelte';
  import PageMetadata from '$lib/components/PageMetadata.svelte';
  import { faqSchemaMainEntity } from '$lib/content/faqs';
  import { buildSoftwareApplicationOffers } from '$lib/content/software_app_offers';

  const { data } = $props();

  const title = "Plezy - A Beautiful Plex & Jellyfin Client";
  const description = "Plezy is a beautiful client for Plex and Jellyfin, available on iOS, Android, Android TV, tvOS, Windows, macOS, and Linux. HDR, Dolby Vision, offline downloads, and more.";
  const url = "https://plezy.app/";

  const softwareAppSchema = $derived.by(() => {
    const schema: Record<string, unknown> = {
      "@context": "https://schema.org",
      "@type": "SoftwareApplication",
      "name": "Plezy",
      "description": description,
      "url": "https://plezy.app",
      "applicationCategory": "MultimediaApplication",
      "operatingSystem": "iOS, Android, Android TV, tvOS, Windows, macOS, Linux",
      "offers": buildSoftwareApplicationOffers({
        appStorePrice: data.appStorePrice,
        playStorePrice: data.playStorePrice
      })
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

<PageMetadata {title} {description} {url} />

<svelte:head>
  {@html `<script type="application/ld+json">${JSON.stringify(softwareAppSchema)}</script>`}
  {@html `<script type="application/ld+json">${JSON.stringify(faqSchema)}</script>`}
</svelte:head>

<Hero />
<Features />
<Screenshots />
<Reviews />
<FAQ />
<Footer />
