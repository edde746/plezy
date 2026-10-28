/// Base URL of Plezy upstream's hosted service: the tracker OAuth proxy
/// (`/auth`), log uploads (`/logs`) and Discord posters (`/posters`). Watch
/// Together rooms run on Open Watch Party relays, not here.
const String plezyServerBaseUrl = 'https://ice.plezy.app';

/// Comic affiliate links are resolved by Plezy's hosted relay. Override at
/// build time when deploying the commerce endpoint on a separate relay.
const String plezyComicCommerceBaseUrl = String.fromEnvironment(
  'PLEZY_COMIC_COMMERCE_BASE_URL',
  defaultValue: plezyServerBaseUrl,
);
