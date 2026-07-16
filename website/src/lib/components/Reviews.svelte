<script lang="ts">
  import ScrollReveal from "./ScrollReveal.svelte";
  import AppleIcon from "~icons/simple-icons/apple";
  import GooglePlayIcon from "~icons/simple-icons/googleplay";
  import RedditIcon from "~icons/fa6-brands/reddit-alien";
  import ArrowUpIcon from "~icons/heroicons/arrow-up-solid";
  import StarIcon from "~icons/heroicons/star-solid";
  import ChevronLeftIcon from "~icons/heroicons/chevron-left-solid";
  import ChevronRightIcon from "~icons/heroicons/chevron-right-solid";

  type SourceIcon = typeof AppleIcon | typeof GooglePlayIcon | typeof RedditIcon;

  type Review = {
    text: string;
    name: string;
    source: "App Store" | "Play Store" | "Reddit";
    icon: SourceIcon;
    upvotes?: number;
  };

  const row1: Review[] = [
    {
      text: "Impressively way better than the official Plex client!",
      name: "Adam P.",
      source: "Play Store",
      icon: GooglePlayIcon,
    },
    {
      text: "Really works better than the native plex app. If the developer keeps going this can be a killer app",
      name: "Mr. Wick 03",
      source: "App Store",
      icon: AppleIcon,
    },
    {
      text: "Holy shit. This comment just made me install it and give it a shot. I've never had a video open so fast. It was amazing.",
      name: "u/Khatib",
      source: "Reddit",
      icon: RedditIcon,
      upvotes: 69,
    },
    {
      text: "Clean UI, great performance, and things ACTUALLY WORK. Scrubbing through a video takes no time at all, turning on subtitles takes maybe .5s, starting episodes is near instant. Incredible work.",
      name: "Frank the Tank uwu",
      source: "App Store",
      icon: AppleIcon,
    },
    {
      text: "Downloads that work...what a concept.",
      name: "Chris R.",
      source: "Play Store",
      icon: GooglePlayIcon,
    },
    {
      text: "It's leap years ahead of Plex's slow and horrible UI. Fast, responsive, and just works. 10/10",
      name: "Starry_mcfly",
      source: "App Store",
      icon: AppleIcon,
    },
    {
      text: "Best plex client I know of, so much better than official Plex app.",
      name: "James K.",
      source: "Play Store",
      icon: GooglePlayIcon,
    },
    {
      text: "This app is absolutely beautiful. It's clean and smooth. A real professional feel to it. Much better than the official Plex app.",
      name: "Mr Kinxy",
      source: "App Store",
      icon: AppleIcon,
    },
  ];

  const row2: Review[] = [
    {
      text: "Replaced the official Plex client with your app and WOW! Even Infuse didn't feel this smooth while also looking nice! Great work!!",
      name: "u/mustbeSaransh",
      source: "Reddit",
      icon: RedditIcon,
      upvotes: 50,
    },
    {
      text: "Design and theme are much better. Love having the buffer size setting. Clean and intuitive. Single developer app that is consistently updated, thank you for your hard work.",
      name: "Corrykid",
      source: "App Store",
      icon: AppleIcon,
    },
    {
      text: "Better than the official client after just a few months. Keeps getting updates that make it better. Great app.",
      name: "Derek S.",
      source: "Play Store",
      icon: GooglePlayIcon,
    },
    {
      text: "Nice, fast and clean app! It has much greater support for codecs than the official app and the download function is made better. I'm changing to this now.",
      name: "Marcus L.",
      source: "Play Store",
      icon: GooglePlayIcon,
    },
    {
      text: "Perfect. I'm so excited for the development of this app. It's exactly what Plex should have been a decade ago. The client-side MPV player with full codec support fixes playback issues and removes the need for server-side lossy transcoding",
      name: "John Capasso",
      source: "Play Store",
      icon: GooglePlayIcon,
    },
    {
      text: "Much better than the official app! The sticking point for me is that downloads actually work reliably. The interface is great and snappy.",
      name: "Ryan T.",
      source: "Play Store",
      icon: GooglePlayIcon,
    },
    {
      text: "Just brilliant. Using on all my Android TV boxes. UI and UX are great. I was having intermittent audio drops with the latest build of the official Plex app. No issues with Plezy.",
      name: "Jon Evans",
      source: "Play Store",
      icon: GooglePlayIcon,
    },
    {
      text: "Fantastic and super lean looking! Must have if you have a Plex server.",
      name: "Alex W.",
      source: "Play Store",
      icon: GooglePlayIcon,
    },
  ];

  const featuredReviews = [row1[3]!, row2[0]!, row2[4]!, row1[5]!];
  const featuredReviewSet = new Set(featuredReviews);
  const supportingReviews = [...row1, ...row2].filter((review) => !featuredReviewSet.has(review));

  let featuredIndex = $state(0);
  let carouselHovered = $state(false);
  let carouselFocused = $state(false);
  let prefersReducedMotion = $state(false);

  const featuredReview = $derived(featuredReviews[featuredIndex]!);
  const carouselPaused = $derived(carouselHovered || carouselFocused || prefersReducedMotion);

  function showReview(index: number) {
    featuredIndex = (index + featuredReviews.length) % featuredReviews.length;
  }

  function previousReview() {
    showReview(featuredIndex - 1);
  }

  function nextReview() {
    showReview(featuredIndex + 1);
  }

  function handleCarouselFocusOut(event: FocusEvent) {
    const currentTarget = event.currentTarget;
    carouselFocused =
      currentTarget instanceof HTMLElement &&
      event.relatedTarget instanceof Node &&
      currentTarget.contains(event.relatedTarget);
  }

  $effect(() => {
    const media = window.matchMedia("(prefers-reduced-motion: reduce)");
    const updatePreference = () => {
      prefersReducedMotion = media.matches;
    };

    updatePreference();
    media.addEventListener("change", updatePreference);
    return () => media.removeEventListener("change", updatePreference);
  });

  $effect(() => {
    const currentIndex = featuredIndex;
    if (carouselPaused) return;

    const timeout = window.setTimeout(() => {
      showReview(currentIndex + 1);
    }, 8000);

    return () => window.clearTimeout(timeout);
  });
</script>

<section id="reviews" class="reviews-section">
  <div class="reviews-header">
    <ScrollReveal>
      <p class="section-label">Reviews</p>
      <h2 class="section-heading">Loved by users</h2>
      <p class="section-description">
        See what people are saying about their experience with Plezy.
      </p>
    </ScrollReveal>
  </div>

  <div class="featured-wrap">
    <ScrollReveal>
      <article
        class="featured-review"
        aria-label="Featured user reviews"
        aria-roledescription="carousel"
        onpointerenter={() => carouselHovered = true}
        onpointerleave={() => carouselHovered = false}
        onfocusin={() => carouselFocused = true}
        onfocusout={handleCarouselFocusOut}
      >
        <div class="featured-top">
          {#if featuredReview.source === "Reddit"}
            <div class="upvote">
              <ArrowUpIcon />
              <span>{featuredReview.upvotes}</span>
            </div>
          {:else}
            <div class="stars" aria-label="5 out of 5 stars">
              {#each Array(5) as _}
                <StarIcon aria-hidden="true" />
              {/each}
            </div>
          {/if}

          <div class="carousel-controls">
            <button type="button" class="carousel-arrow" onclick={previousReview} aria-label="Previous featured review">
              <ChevronLeftIcon />
            </button>
            <div class="carousel-dots" role="group" aria-label="Choose featured review">
              {#each featuredReviews as _, index}
                <button
                  type="button"
                  class="carousel-dot"
                  class:active={featuredIndex === index}
                  onclick={() => showReview(index)}
                  aria-label={`Show featured review ${index + 1}`}
                  aria-current={featuredIndex === index ? "true" : undefined}
                ></button>
              {/each}
            </div>
            <button type="button" class="carousel-arrow" onclick={nextReview} aria-label="Next featured review">
              <ChevronRightIcon />
            </button>
          </div>
        </div>

        <div class="featured-slide" aria-live={carouselPaused ? "polite" : "off"}>
          {#key featuredIndex}
            {@const FeaturedSourceIcon = featuredReview.icon}
            <div class="featured-content">
              <blockquote>"{featuredReview.text}"</blockquote>
              <div class="review-footer">
                <span class="review-name">{featuredReview.name}</span>
                <div class="review-source">
                  <FeaturedSourceIcon />
                  <span>{featuredReview.source}</span>
                </div>
              </div>
            </div>
          {/key}
        </div>
      </article>
    </ScrollReveal>
  </div>

  <div class="review-strip content-pad" role="list" aria-label="More user reviews">
    {#each supportingReviews as review}
      {@const SourceIcon = review.icon}
      <article class="review-card" role="listitem">
        {#if review.source === "Reddit"}
          <div class="upvote">
            <ArrowUpIcon />
            <span>{review.upvotes}</span>
          </div>
        {:else}
          <div class="stars" aria-label="5 out of 5 stars">
            {#each Array(5) as _}
              <StarIcon aria-hidden="true" />
            {/each}
          </div>
        {/if}
        <p class="review-text">"{review.text}"</p>
        <div class="review-footer">
          <span class="review-name">{review.name}</span>
          <div class="review-source">
            <SourceIcon />
            <span>{review.source}</span>
          </div>
        </div>
      </article>
    {/each}
  </div>
</section>

<style>
  .reviews-section {
    overflow: hidden;
    padding-block: clamp(4rem, 9vw, 8rem);
  }

  .reviews-header,
  .featured-wrap {
    width: min(100%, var(--page-width));
    margin-inline: auto;
    padding-inline: var(--page-gutter);
  }

  .reviews-header {
    margin-bottom: clamp(2rem, 5vw, 3.5rem);
  }

  .section-label {
    width: fit-content;
    margin-bottom: 1rem;
    border-radius: var(--radius-full);
    padding: 0.5rem 0.875rem;
    color: var(--color-text-muted);
    background: var(--color-surface);
    font-size: 0.75rem;
    font-weight: 700;
    letter-spacing: 0.03em;
  }

  .section-heading {
    max-width: 12ch;
    margin-bottom: 1rem;
    font-family: var(--font-display);
    font-size: clamp(2.5rem, 7vw, 4.75rem);
    font-weight: 700;
    letter-spacing: -0.045em;
    line-height: 1;
    text-wrap: balance;
  }

  .section-description {
    max-width: 34rem;
    color: var(--color-text-muted);
    font-size: clamp(1rem, 2vw, 1.125rem);
    line-height: 1.7;
  }

  .featured-review {
    display: flex;
    min-height: clamp(22rem, 42vw, 31rem);
    flex-direction: column;
    justify-content: space-between;
    border-radius: var(--radius-xl);
    padding: clamp(1.5rem, 6vw, 4rem);
    background: var(--color-surface);
  }

  .featured-top {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 1rem;
  }

  .featured-top .upvote {
    margin-bottom: 0;
  }

  .carousel-controls,
  .carousel-dots {
    display: flex;
    align-items: center;
  }

  .carousel-controls {
    gap: 0.375rem;
  }

  .carousel-dots {
    gap: 0.375rem;
    padding-inline: 0.25rem;
  }

  .carousel-arrow,
  .carousel-dot {
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: var(--radius-full);
    color: var(--color-text-muted);
    background: var(--color-surface-highest);
    transition:
      color var(--motion-fast) var(--ease-standard),
      background-color var(--motion-fast) var(--ease-standard);
  }

  .carousel-arrow {
    width: 2.25rem;
    height: 2.25rem;
  }

  .carousel-arrow :global(svg) {
    width: 1rem;
    height: 1rem;
  }

  .carousel-dot {
    width: 0.5rem;
    height: 0.5rem;
    padding: 0;
    background: var(--color-text-subtle);
  }

  .carousel-dot.active {
    background: var(--color-text);
  }

  .carousel-arrow:hover,
  .carousel-arrow:focus-visible,
  .carousel-dot:hover,
  .carousel-dot:focus-visible {
    color: var(--color-text);
    background: rgb(237 237 237 / 0.18);
    outline: none;
  }

  .carousel-dot:focus-visible {
    box-shadow: 0 0 0 0.25rem rgb(237 237 237 / 0.12);
  }

  .featured-slide {
    display: grid;
    flex: 1;
  }

  .featured-content {
    display: flex;
    flex-direction: column;
    justify-content: space-between;
    animation: featured-review-enter var(--motion-normal) var(--ease-standard) both;
  }

  @keyframes featured-review-enter {
    from {
      opacity: 0;
      transform: translateY(0.5rem);
    }

    to {
      opacity: 1;
      transform: translateY(0);
    }
  }

  .featured-review blockquote {
    max-width: 24ch;
    margin: 2rem 0;
    font-family: var(--font-display);
    font-size: clamp(1.75rem, 4.5vw, 3.25rem);
    font-weight: 700;
    letter-spacing: -0.035em;
    line-height: 1.15;
  }

  .review-strip {
    display: flex;
    gap: 1rem;
    margin-top: 1rem;
    overflow-x: auto;
    scroll-snap-type: x mandatory;
    scrollbar-width: none;
  }

  .review-strip::-webkit-scrollbar {
    display: none;
  }

  .review-card {
    display: flex;
    width: min(82vw, 20rem);
    min-height: 14rem;
    flex-shrink: 0;
    flex-direction: column;
    border-radius: var(--radius-lg);
    padding: 1.5rem;
    background: var(--color-surface-high);
    scroll-snap-align: start;
  }

  .review-card:nth-child(3n) {
    background: var(--color-surface);
  }

  .upvote,
  .stars,
  .review-footer,
  .review-source {
    display: flex;
    align-items: center;
  }

  .upvote {
    width: fit-content;
    gap: 0.375rem;
    margin-bottom: 1.25rem;
    border-radius: var(--radius-full);
    padding: 0.375rem 0.625rem;
    color: #ff9a7d;
    background: rgb(255 118 82 / 0.14);
    font-size: 0.75rem;
    font-weight: 800;
  }

  .upvote :global(svg) {
    width: 0.875rem;
    height: 0.875rem;
  }

  .stars {
    gap: 0.125rem;
    color: var(--color-brand);
  }

  .review-card .stars {
    margin-bottom: 1.25rem;
  }

  .stars :global(svg),
  .review-source :global(svg) {
    width: 0.875rem;
    height: 0.875rem;
  }

  .review-text {
    flex: 1;
    margin-bottom: 1.5rem;
    color: var(--color-text-muted);
    font-size: 0.9375rem;
    line-height: 1.65;
  }

  .review-footer {
    justify-content: space-between;
    gap: 1rem;
  }

  .review-name {
    font-size: 0.8125rem;
    font-weight: 700;
  }

  .review-source {
    flex-shrink: 0;
    gap: 0.375rem;
    color: var(--color-text-subtle);
    font-size: 0.6875rem;
    font-weight: 600;
  }

  .content-pad {
    padding-left: max(var(--page-gutter), calc((100vw - var(--page-width)) / 2 + var(--page-gutter)));
    padding-right: var(--page-gutter);
  }
</style>
