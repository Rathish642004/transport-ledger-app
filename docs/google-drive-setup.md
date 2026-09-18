# Google Drive backup setup

Google Drive backup requires Google Cloud configuration in addition to the
Flutter code. The checked-in `android/app/google-services.json` currently has
only an Android OAuth client (`client_type: 1`), so it cannot provide the Web
OAuth client required by `google_sign_in` 7 on Android.

1. In the Firebase project `transport-ledger-c3580`, enable Google Sign-In and
   create (or restore) a **Web application** OAuth 2.0 client. Do not use the
   Android client ID from `client_secret_*.json` as a server client ID.
2. Enable the **Google Drive API** in the same Google Cloud project.
3. Add Android OAuth clients for package
   `com.transportledger.flutter_app` and the SHA-1 of every signing key used
   to install the app (debug and release/Play App Signing as applicable).
4. Download a fresh `google-services.json`. Its `oauth_client` list must
   include both `client_type: 1` (Android) and `client_type: 3` (Web).
5. Replace `android/app/google-services.json`, run `flutter clean`, then
   rebuild and reinstall the app. A hot reload is not enough because Gradle
   generates Android resources from this file during the build.

The backup uses the `drive.appdata` scope. Its backup file is intentionally
stored in the app's hidden Drive data area rather than the visible My Drive
file list.
