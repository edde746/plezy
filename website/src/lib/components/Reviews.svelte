<script lang="ts">
  import { onMount } from "svelte";
  import ScrollReveal from "./ScrollReveal.svelte";
  import AppleIcon from "~icons/simple-icons/apple";
  import GooglePlayIcon from "~icons/simple-icons/googleplay";
  import RedditIcon from "~icons/fa6-brands/reddit-alien";
  import ArrowUpIcon from "~icons/heroicons/arrow-up-solid";
  import StarIcon from "~icons/heroicons/star-solid";

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
      text: "If you're having troubles with the default plex app just ditch it and switch to this. Plezy is faster, and easier to use. Worth the $5",
      name: "boyknight53",
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
      text: "College student here this is a godsend. Cannot recommend enough. For mediaheads on the go this is the best $4 you could ever spend.",
      name: "djmeowmeow",
      source: "App Store",
      icon: AppleIcon,
    },
    {
      text: "Much better than the official app! The sticking point for me is that downloads actually work reliably. The interface is great and snappy.",
      name: "Ryan T.",
      source: "Play Store",
      icon: GooglePlayIcon,
    },
    {
      text: "This has to be my new favorite plex client. Starts up and connects quickly. Quality is amazing. Well worth the $5.",
      name: "nasukaren",
      source: "App Store",
      icon: AppleIcon,
    },
    {
      text: "Fantastic and super lean looking! Must have if you have a Plex server.",
      name: "Alex W.",
      source: "Play Store",
      icon: GooglePlayIcon,
    },
  ];

  let mounted = $state(false);

  onMount(() => {
    mounted = true;
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

  <!-- Row 1: scrolls left -->
  <div class="marquee-row row-gap">
    <div class="marquee-track marquee-left">
      {#each row1 as review}
        {@const SourceIcon = review.icon}
        <div class="review-card glass-card">
          {#if review.source === "Reddit"}
            <div class="upvote">
              <ArrowUpIcon />
              <span>{review.upvotes}</span>
            </div>
          {:else}
            <div class="stars">
              {#each Array(5) as _}
                <StarIcon />
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
        </div>
      {/each}
      {#if mounted}
        <!-- Duplicate for seamless loop -->
        <div aria-hidden="true" class="duplicate-cards">
          {#each row1 as review}
            {@const SourceIcon = review.icon}
            <div class="review-card glass-card">
              {#if review.source === "Reddit"}
                <div class="upvote">
                  <ArrowUpIcon />
                  <span>{review.upvotes}</span>
                </div>
              {:else}
                <div class="stars">
                  {#each Array(5) as _}
                    <StarIcon />
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
            </div>
          {/each}
        </div>
      {/if}
    </div>
  </div>

  <!-- Row 2: scrolls right -->
  <div class="marquee-row">
    <div class="marquee-track marquee-right">
      {#each row2 as review}
        {@const SourceIcon = review.icon}
        <div class="review-card glass-card">
          {#if review.source === "Reddit"}
            <div class="upvote">
              <ArrowUpIcon />
              <span>{review.upvotes}</span>
            </div>
          {:else}
            <div class="stars">
              {#each Array(5) as _}
                <StarIcon />
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
        </div>
      {/each}
      {#if mounted}
        <!-- Duplicate for seamless loop -->
        <div aria-hidden="true" class="duplicate-cards">
          {#each row2 as review}
            {@const SourceIcon = review.icon}
            <div class="review-card glass-card">
              {#if review.source === "Reddit"}
                <div class="upvote">
                  <ArrowUpIcon />
                  <span>{review.upvotes}</span>
                </div>
              {:else}
                <div class="stars">
                  {#each Array(5) as _}
                    <StarIcon />
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
            </div>
          {/each}
        </div>
      {/if}
    </div>
  </div>
</section>

<style>
  .reviews-section {
    overflow: hidden;
    padding-block: 4rem;
  }

  .reviews-header {
    max-width: 64rem;
    margin-inline: auto;
    margin-bottom: 2.5rem;
    padding-inline: 1.5rem;
  }

  .section-label {
    margin-bottom: 0.75rem;
    color: var(--color-accent);
    font-size: 0.875rem;
    font-weight: 500;
    letter-spacing: 0.025em;
    line-height: 1.25rem;
    text-transform: uppercase;
  }

  .section-heading {
    margin-bottom: 1rem;
    font-size: 2.25rem;
    font-weight: 700;
    line-height: 2.5rem;
  }

  .section-description {
    max-width: 32rem;
    color: var(--color-text-muted);
    font-size: 1.125rem;
    line-height: 1.75rem;
  }

  .row-gap {
    margin-bottom: 1rem;
  }

  .review-card {
    display: flex;
    width: 300px;
    flex-shrink: 0;
    flex-direction: column;
    padding: 1.25rem;
    border-radius: 1rem;
  }

  .upvote,
  .stars,
  .review-footer,
  .review-source {
    display: flex;
    align-items: center;
  }

  .upvote {
    gap: 0.375rem;
    margin-bottom: 0.75rem;
    color: var(--color-accent);
    font-size: 0.875rem;
    font-weight: 500;
    line-height: 1.25rem;
  }

  .upvote :global(svg) {
    width: 1rem;
    height: 1rem;
  }

  .stars {
    gap: 0.125rem;
    margin-bottom: 0.75rem;
    color: var(--color-accent);
  }

  .stars :global(svg),
  .review-source :global(svg) {
    width: 0.875rem;
    height: 0.875rem;
  }

  .review-text {
    flex: 1;
    margin-bottom: 1rem;
    color: var(--color-text-muted);
    font-size: 0.875rem;
    line-height: 1.625;
  }

  .review-footer {
    justify-content: space-between;
  }

  .review-name {
    font-size: 0.875rem;
    font-weight: 600;
    line-height: 1.25rem;
  }

  .review-source {
    gap: 0.375rem;
    color: color-mix(in srgb, var(--color-text-muted) 60%, transparent);
    font-size: 0.75rem;
    line-height: 1rem;
  }

  .duplicate-cards {
    display: contents;
  }

  .marquee-row {
    overflow: hidden;
    mask-image: linear-gradient(
      to right,
      transparent,
      black 5%,
      black 95%,
      transparent
    );
    -webkit-mask-image: linear-gradient(
      to right,
      transparent,
      black 5%,
      black 95%,
      transparent
    );
  }

  .marquee-track {
    display: flex;
    gap: 1rem;
    width: max-content;
    will-change: transform;
  }

  .marquee-left {
    animation: scroll-left 60s linear infinite;
  }

  .marquee-right {
    animation: scroll-right 60s linear infinite;
  }

  .marquee-row:hover .marquee-track {
    animation-play-state: paused;
  }

  @keyframes scroll-left {
    from {
      transform: translateX(0);
    }
    to {
      transform: translateX(-50%);
    }
  }

  @keyframes scroll-right {
    from {
      transform: translateX(-50%);
    }
    to {
      transform: translateX(0);
    }
  }

  @media (prefers-reduced-motion: reduce) {
    .marquee-track {
      animation-play-state: paused;
    }
  }

  @media (min-width: 640px) {
    .reviews-section {
      padding-block: 6rem;
    }

    .reviews-header {
      margin-bottom: 4rem;
    }

    .review-card {
      width: 340px;
    }
  }

  @media (min-width: 768px) {
    .reviews-section {
      padding-block: 8rem;
    }

    .section-heading {
      font-size: 3rem;
      line-height: 1;
    }
  }
</style>
