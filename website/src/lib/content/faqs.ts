export type Faq = {
  id: string;
  question: string;
  answer: string;
  schemaAnswer?: string;
};

export const faqs: Faq[] = [
  {
    id: "plex-pass",
    question: "Do I need Plex Pass to stream remotely?",
    answer:
      "No. The remote viewing checks are done client-side in the official Plex apps, not on your server. Plezy connects directly to your server's API, so there are no such checks.",
  },
  {
    id: "jellyfin",
    question: "Does Plezy support Jellyfin?",
    answer:
      "Yes! Plezy works with Jellyfin servers alongside Plex. You can sign in with either your Jellyfin username and password or use Quick Connect for a one-tap login from another device. Most of Plezy's features — direct play, HDR, subtitles, offline downloads — work the same way on both.",
  },
  {
    id: "free",
    question: "Is Plezy free?",
    answer:
      "Plezy is open-source and free to download from GitHub. The App Store and Play Store versions are paid (one-time purchase, price varies by region). The charge helps cover developer account fees, test devices, and the time spent developing and maintaining the app.<br><br>There's no free trial because the app stores don't natively support trials for paid apps. The only way to offer one would be to make the app free and use in-app purchases — which means integrating StoreKit and Google Play Billing, gating features behind a paywall, and adding a layer of complexity that doesn't make sense for a simple one-time purchase. If you'd like to try before you buy, you can sideload the binaries from GitHub or try it on desktop first.",
  },
  {
    id: "apple-tv",
    question: "Does Plezy work on Apple TV?",
    answer: "Yes, Plezy is available for tvOS on the App Store.",
  },
  {
    id: "android-tv",
    question: "Does Plezy work on Android TV / Shield?",
    answer: "Yes! The app is available for Android TV including the Shield.",
  },
  {
    id: "watch-together",
    question: "How does Watch Together work?",
    answer:
      "Watch Together uses a WebSocket relay to sync playback between users. The other person needs access to the same media on the same server. Only playback sync messages are exchanged - nothing about your server is shared.",
  },
  {
    id: "video-player",
    question: "What video player does Plezy use?",
    answer:
      'mpv on most platforms, with ExoPlayer available on Android for HDR support and better performance. ExoPlayer also has libass support via <a href="https://github.com/peerless2012/libass-android" target="_blank" rel="noopener">libass-android</a>.',
    schemaAnswer:
      "mpv on most platforms, with ExoPlayer available on Android for HDR support and better performance. ExoPlayer also has libass support via libass-android.",
  },
  {
    id: "plex-block",
    question: "Will Plex block this app?",
    answer: "Unlikely. We use the officially documented Plex API with their recommended authentication method.",
  },
];

function htmlToText(value: string) {
  return value
    .replace(/<br\s*\/?>/gi, " ")
    .replace(/<[^>]+>/g, "")
    .replace(/&amp;/g, "&")
    .replace(/&middot;/g, "·")
    .replace(/\s+/g, " ")
    .trim();
}

export const faqSchemaMainEntity = faqs.map((faq) => ({
  "@type": "Question",
  name: faq.question,
  acceptedAnswer: {
    "@type": "Answer",
    text: faq.schemaAnswer ?? htmlToText(faq.answer),
  },
}));
