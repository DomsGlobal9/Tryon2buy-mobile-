# TryOn2Buy — Flutter app

Mobile counterpart of [tryon2buy.com](https://tryon2buy.com): AI virtual
try-on for Indian ethnic wear. The app mirrors the website's functionality
(guest shoppers, merchant studio, B2B client portal) and talks to the same
`tryon_service` Express backend.

## The three repositories

| Part | Location | Notes |
|---|---|---|
| Flutter app | this repo | |
| Express backend | `../tryon2buy backend/tryon2buy_backend` | branch `dev` is the contract this app targets |
| React web app | `../tryon2buy frontend /tryon2buy_frontend` | the directory name ends in a **trailing space** |

## Backend hosts

| Host | Branch | Use |
|---|---|---|
| `https://tryon2buy-backend-dev.onrender.com` | `dev` | default for debug/profile builds; guest generation, B2B catalog, save-to-library |
| `https://tryon2buy-backend.onrender.com` | `main` | what the website uses; **lacks** `vendor/profile`, `catalog/*`, `save-to-library`, `auth/vendor/profile` and requires auth on `generate`. Do not point a release here until `dev` is merged. |
| `http://10.0.2.2:4000` | local | Android emulator → local server; cleartext HTTP is allowed in debug builds only |

The host comes from `--dart-define=API_BASE_URL`, normally via the files in
`env/`. Details and the routing rules are in `lib/core/constants/api_endpoints.dart`.

## Running

```bash
flutter pub get
flutter run --dart-define-from-file=env/dev.json      # or env/local.json
```

Without a define, debug builds use the dev host. A **release** build refuses
to start without one (it shows a configuration screen), so a store build can
never silently talk to the dev database.

## Release builds

```bash
flutter build appbundle --release --dart-define-from-file=env/prod.json
```

Signing: copy `android/key.properties.example` to `android/key.properties`
(git-ignored) and create the upload keystore as described there. Without it
the release build is signed with the debug key and Gradle prints a warning;
that artifact must not be uploaded.

## Accounts

Shoppers are guests (10 free generations per IP, enforced server-side).
Merchants and B2B clients sign in with email and password and receive a 7-day
JWT; the app checks the `exp` claim itself and signs the account out when it
lapses.

Open the portal with `AppRouter.openSignIn`. A successful sign-in shows a
welcome moment and then rebuilds the stack as home → workspace; pass
`returnToCaller: true` from a flow that must resume where it was (a guest in
the studio hitting the free-tier limit). Every sign-out goes through
`signOutAndLeave`, which confirms, clears the session and guest mode, shows
the signed-out screen, and lands on the welcome screen.

## Legal pages

The Profile tab's Privacy Policy and Terms of Service are rendered in-app
from `lib/features/content/data/legal_content.dart`. The website's footer
links for both are empty anchors, so there is nothing to link to. The text
describes what the app and backend actually do; update it when that changes,
and have it reviewed before a store release.

## Layout

```
lib/core        network client, session, storage, theme, shared widgets
lib/features    one folder per feature: data / domain / presentation
test            unit tests (run with `flutter test`)
env             API_BASE_URL per environment
```

## Checks

```bash
flutter analyze
flutter test
```

The GitHub Actions workflow in `.github/workflows/flutter.yml` runs both on
every push.
