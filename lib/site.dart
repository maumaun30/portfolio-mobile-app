/// Public portfolio site. Override with `--dart-define=SITE_URL=...`.
const String siteUrl = String.fromEnvironment(
  'SITE_URL',
  defaultValue: 'https://www.devmau.site',
);
