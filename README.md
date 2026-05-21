# Portfolio Admin (Flutter)

Mobile admin app for the [Maurico Maun portfolio CMS](../portfolio/my-portfolio).
Implements the design system from `claude.ai/design` → "Portfolio Mobile App".

## What's built

- `lib/theme/` — custom `ThemeData` over Material 3 matching the editorial dark-gold brand.
- `lib/widgets/` — `SectionLabel`, `StatusBadge`, `SubmitBar`, `AppDrawer`, `ScreenScaffold`, `CoverThumb`, `EmptyState`, `ErrorPanel`, `ConfirmDeleteSheet`.
- `lib/screens/` — Splash, Sign-in, Dashboard, Design System showcase. **Projects list + editor (full CRUD)**. Stubs for Skills / Posts / Keywords / Sections / Notifications / Search / Settings.
- `lib/auth/` — GitHub OAuth scaffolding via `flutter_appauth` + `flutter_secure_storage`, with a dev "skip auth" button.
- `lib/api/` — Dio client with Bearer interceptor, `projects_api.dart` (list / create / update / delete with Riverpod providers).
- `lib/models/project.dart` — typed Project model matching the Drizzle schema.
- `lib/router.dart` — `go_router` with auth-aware redirects and nested `/projects/:id` routes.

All drawer routes are now real screens — no more stubs. Stub_screen.dart is gone.

### Projects screens implemented
- **List** — pull-to-refresh, loading shimmer rows, empty state, error state with retry, sub-bar with count and sort dropdown, pill FAB. Swipe-end-to-start opens the editor (delete lives inside).
- **Editor** — cover (URL prompt for now), name, slug (auto from name, regex validation), domain, link, description, stacks tag input (chips + add-on-submit), status + isCurrent toggles, sticky save bar, error banner on save failure, destructive "Delete project…" → `ConfirmDeleteSheet` requiring the slug typed verbatim.

## What's NOT built yet

- The screen bodies for Projects / Skills / Posts / Keywords / Sections (designs exist; not implemented).
- The token-exchange endpoint on the Next.js side. NextAuth uses session cookies, so the API doesn't accept `Bearer` tokens today. See **API changes needed** below.
- Image upload (Vercel Blob) integration on mobile.
- Pull-to-refresh, shimmer loading states, swipe-row actions, bottom-sheet confirms.

## Running

```bash
flutter pub get
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:3000 \
  --dart-define=GITHUB_CLIENT_ID=<github-oauth-app-client-id> \
  --dart-define=OAUTH_REDIRECT_URI=portfolio-admin://oauth/callback
```

For Android emulator → host machine, `localhost` is `10.0.2.2`. For iOS simulator, `localhost` works.

While the token exchange endpoint doesn't exist, use the **Dev: skip auth** button on the sign-in screen to enter the app.

## API auth (Next.js side)

Implemented. The portfolio repo now ships:

- `api_tokens` table — `token_hash` (sha256), `label`, `user_id`, `last_used_at`.
- `lib/api-auth.ts` → `authorize(request)` accepts a NextAuth session cookie **or** a valid `Authorization: Bearer <token>` header.
- `POST /api/auth/exchange` — accepts `{ githubAccessToken, label? }`, validates the token via `GET https://api.github.com/user`, enforces the `ADMIN_GITHUB_LOGIN` gate, and returns a freshly-generated opaque token (hash-only stored).
- Every mutating `/api/*` route swept to use the new helper (`projects`, `skills`, `content`, `upload`, `blog/generate`).

The plain token is returned ONCE on exchange — `flutter_secure_storage` keeps it on-device after that.

## OAuth setup

Create a GitHub OAuth App (`https://github.com/settings/developers`):
- Authorization callback URL: `portfolio-admin://oauth/callback`
- Add `OAUTH_REDIRECT_URI` to `android/app/src/main/AndroidManifest.xml` as an `intent-filter` and to `ios/Runner/Info.plist` as a `CFBundleURLSchemes` entry. See `flutter_appauth` docs.

## Next screens to build (in priority order)

1. ~~Projects list + editor~~ — done.
2. ~~Image upload bottom sheet~~ — done. Picker / uploading-with-progress / done-with-blob-URL-preview / error states. Used by the project editor's cover field; ready to reuse on the post editor.
3. ~~Keywords list with "Generate now" action wired to `/api/blog/generate`~~ — done. Hero auto-blog CTA fires the global generate; per-row spark button generates for a specific term. Inline enable/disable switch. Editor for create/edit. New REST endpoints `/api/keywords` + `/api/keywords/[id]` on the Next.js side.
4. ~~Posts list + markdown editor~~ — done. Filter chips (All / Blog / Case study), row with cover thumb + type + date + status badge, FAB to add. Editor has cover (via ImageUploadSheet), title, type dropdown, status switch, slug (auto from title, regex-validated), excerpt, markdown body with Write / Preview tabs (flutter_markdown), bottom bar with separate Publish pill and Save & publish / Save draft action.
5. ~~Skills list with reorder~~ — done. Static list with simpleicons.org-tinted brand icons. App-bar toggle flips into a `ReorderableListView` (drag-handles surface, sort PATCHes only the rows that actually moved). Editor with live preview tile, slug + label fields, delete confirm.
6. ~~Page sections editor~~ — done. List of the 6 known sections with section-specific icons. Editor is a monospaced JSON textarea (full-screen, scroll-safe) with reformat and copy actions in the app bar, a Revert button on the submit bar, and structured error display (server-side Zod issues come back as `path: message` lines).
