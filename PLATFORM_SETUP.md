# Platform setup (one-time)

After cloning this repo on a new machine, the `android/` and `ios/` folders don't exist yet — Flutter generates them lazily. Run this once:

```powershell
cd "C:\Web Projects\portfolio-mobile-app"
flutter create .         # fills in android/, ios/, web/, windows/, etc.
flutter pub get
```

Then apply the GitHub-OAuth and image-picker patches below. Run `flutter analyze` to confirm a clean build.

> **Note:** On a fresh `flutter create .` you may also need to install Android command-line tools (so Gradle can call `sdkmanager`) and let it accept SDK licenses. If the build complains about a corrupted NDK (`source.properties` missing), delete `$ANDROID_HOME/ndk/<version>/` and let AGP re-download it.

---

## 1. GitHub OAuth — deep-link callback

The mobile app uses `flutter_appauth` (PKCE). After GitHub redirects to `portfolio-admin://oauth/callback`, the OS needs to know which app handles that scheme.

### Android — `android/app/build.gradle.kts`

> **Do not add a `<data android:scheme="portfolio-admin" ...>` intent-filter to MainActivity.** flutter_appauth ≥ 12 already registers its own `RedirectUriReceiverActivity` for the scheme declared via `manifestPlaceholders["appAuthRedirectScheme"]`. A duplicate intent-filter on MainActivity competes with it, and Android may route the OAuth callback to MainActivity — which can't complete the AppAuth Future, leaving the app on a blank screen after sign-in.

Inside `android/app/build.gradle.kts` (Module-level — modern Flutter uses Kotlin DSL), set `compileSdk = 36` (image_picker_android requirement), bump `minSdk` to at least 21 (flutter_appauth requirement), and declare the `appAuthRedirectScheme` placeholder used by the AppAuth library:

```kotlin
android {
    compileSdk = 36

    defaultConfig {
        minSdk = maxOf(flutter.minSdkVersion, 21)
        manifestPlaceholders["appAuthRedirectScheme"] = "portfolio-admin"
        // ...other defaults
    }
}
```

### iOS — `ios/Runner/Info.plist`

Inside `<dict>`, add the URL scheme:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>portfolio-admin</string>
        </array>
    </dict>
</array>
```

---

## 2. Image picker — gallery & camera permissions

### iOS — `ios/Runner/Info.plist`

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Pick cover images for projects and posts.</string>
<key>NSCameraUsageDescription</key>
<string>Take a photo to use as a cover image.</string>
```

### Android — no manifest changes for API 33+

Modern Android grants per-image read scoped via the picker — no manifest declaration is needed if your `compileSdkVersion >= 33`. For API ≤ 32 add:

```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
                 android:maxSdkVersion="32" />
```

---

## 3. GitHub OAuth app (one-time on the GitHub side)

Create at https://github.com/settings/developers → **OAuth Apps** → **New OAuth App**:

| Field                       | Value                                                  |
| --------------------------- | ------------------------------------------------------ |
| Application name            | Portfolio Admin (mobile)                               |
| Homepage URL                | https://your-portfolio.vercel.app                      |
| Authorization callback URL  | `portfolio-admin://oauth/callback`                     |

Save, copy the **Client ID** (no secret needed; flutter_appauth uses PKCE), then pass at run time:

```powershell
flutter run `
  --dart-define=API_BASE_URL=http://10.0.2.2:3000 `
  --dart-define=GITHUB_CLIENT_ID=Ov23li...
```

The first sign-in exchanges that GitHub token for a long-lived API token via `POST /api/auth/exchange`, which gets stored in `flutter_secure_storage`. After that, every request to `/api/*` carries `Authorization: Bearer <token>`.

---

## 4. Local dev quick reference

| Target                | API base URL                  |
| --------------------- | ----------------------------- |
| Android emulator      | `http://10.0.2.2:3000`        |
| iOS simulator         | `http://localhost:3000`       |
| Physical device, LAN  | `http://<your-PC-IP>:3000`    |
| Vercel preview        | `https://<branch>-<...>.vercel.app` |

If you only want to exercise the UI (read-only screens, etc.) without a working OAuth flow, the sign-in screen has a **Dev: skip auth** button that writes a placeholder token. Mutating requests will then 401, but list/detail screens render fine.

---

## 5. Why these files aren't already in the repo

Flutter's platform scaffolding includes machine-specific artifacts (`build.gradle` plugin versions, Xcode project files keyed to your team ID, etc.) that vary between toolchain versions. Committing them risks merge conflicts every time the SDK updates. The convention is: keep `lib/`, `pubspec.yaml`, and platform-folder *patches* in version control; let each developer run `flutter create .` to generate the rest.
