# Mau Portfolio (Flutter)

Mobile admin app for the portfolio CMS behind [devmau.site](https://www.devmau.site).
Edit projects, skills, posts, auto-blog keywords and page sections from your phone. It talks to the same Next.js API as the web admin.

## Features

- **Light / dark theme.** Same palettes as devmau.site: warm "paper" light (default) and "Gold Noir" dark. Toggle with the sun/moon button in the drawer header or in **Settings → Appearance**. The choice is saved on the device.
- **Dashboard.** Real counts per collection plus recent activity.
- **Projects.** List with pull-to-refresh, shimmer loading and swipe-to-edit. The editor covers cover upload, slug validation, stack tags, status / current toggles, and a delete that asks you to type the slug.
- **Posts.** Filter chips (All / Blog / Case study). Markdown editor with Write / Preview tabs, cover upload, publish / draft.
- **Skills.** simpleicons.org brand icons tinted to the theme ink, with drag-to-reorder mode.
- **Keywords.** Auto-blog terms with enable switches, per-term or global "Generate now" (`/api/blog/generate`).
- **Sections.** JSON editor for the site's page sections, with reformat / copy / revert and Zod error display.
- **Search, Notifications, Settings, Design system** showcase.
- **Auth.** GitHub OAuth (PKCE) through `flutter_appauth`. The code is exchanged server-side for a long-lived API token, which is kept in `flutter_secure_storage`.

## Stack

Flutter 3.22+ · Material 3 (custom-themed) · `go_router` · `flutter_riverpod` · `dio` · `flutter_appauth` · `shared_preferences` · `url_launcher` · `google_fonts` (Inter / JetBrains Mono) · `lucide_icons_flutter`

## Project layout

```
lib/
  api/        Dio client (Bearer interceptor) + one file per resource
  auth/       GitHub OAuth (authorize on-device, exchange on the server)
  models/     Typed models matching the Drizzle schema
  screens/    One folder per resource (list + editor)
  theme/      tokens.dart (light + dark palettes), app_theme.dart, theme_controller.dart
  widgets/    Shared UI: drawer, sheets, badges, brand mark, theme toggle
  router.dart go_router with auth-aware redirects
  site.dart   Public site URL (https://www.devmau.site)
assets/logo.png   devmau.site favicon, used for app icon + splash
tool/gen_icons.py Generates launcher icons / splash from assets/logo.png
```

### Theming

`AppTokens` colors resolve against the active `AppPalette` (`AppPalette.light` / `AppPalette.dark`). The values mirror the CSS variables in the web portfolio's `app/globals.css`. `ThemeController` holds the saved preference. On toggle it swaps the palette and rebuilds the tree in place, so open screens and forms keep their state. As on the web (`defaultTheme="light"`, `enableSystem={false}`), the default is light and the OS setting is ignored.

## Running

```bash
flutter pub get
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:3000 \
  --dart-define=GITHUB_CLIENT_ID=<github-oauth-app-client-id>
```

Or on Windows: `./run.ps1` (defaults to the emulator → host API).

| Define               | Default                            | Notes                               |
| -------------------- | ---------------------------------- | ----------------------------------- |
| `API_BASE_URL`       | `http://localhost:3000`            | `http://10.0.2.2:3000` for Android emulator → host |
| `GITHUB_CLIENT_ID`   | —                                  | Required for sign-in                |
| `OAUTH_REDIRECT_URI` | `portfolio-admin://oauth/callback` |                                     |
| `SITE_URL`           | `https://www.devmau.site`          | "Visit portfolio" / "Open admin on web" links |

If you only want to look at the UI, the sign-in screen's **Dev: skip auth** button lets you in. Writes will return 401.

## Building the release APK

```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=https://www.devmau.site \
  --dart-define=GITHUB_CLIENT_ID=<client-id>
# → build/app/outputs/flutter-apk/app-release.apk
```

## Platform setup

Platform folders (`android/`, `ios/`, …) aren't committed. Generate them with `flutter create .`, then apply the patches in [PLATFORM_SETUP.md](./PLATFORM_SETUP.md): OAuth deep link, launch background, image-picker permissions, and branding (name, icon, splash via `python tool/gen_icons.py`).

## API auth (Next.js side)

- `POST /api/auth/exchange` takes `{ code, codeVerifier, redirectUri, label }` and swaps the code with GitHub using the server-held client secret. It enforces the `ADMIN_GITHUB_LOGIN` gate and returns an opaque API token. Only a hash of the token is stored, in `api_tokens`.
- `authorize(request)` in `lib/api-auth.ts` accepts either a NextAuth session cookie or `Authorization: Bearer <token>` on every mutating `/api/*` route.
