# Transport Ledger

A native Android app for a transport business to track orders, customers,
companies, bank accounts, expenses, and payments — a Flutter port of the
`transport-ledger` React prototype, built for a single user's personal use
(not distributed via the Play Store).

## Features

- **Orders** — create/edit transport orders, generate and share a PDF bill.
- **Ledger** — per-party (company/customer) running ledger with payment
  allocation across orders.
- **Payments** — record receipts and allocate them against outstanding
  orders.
- **Banks** — bank accounts and their transactions.
- **Expenses** — standalone expense records.
- **Reports & dashboard** — summarized metrics across the above.
- **Backup & restore** — local JSON/CSV export, plus optional Google Drive
  backup (see [docs/google-drive-setup.md](docs/google-drive-setup.md)).

All data is stored locally on-device (Hive). There is no backend server;
Google Drive is used only as an optional, user-owned backup destination.

## Tech stack

- Flutter, Riverpod for state management, `go_router` for navigation.
- Hive CE for local storage.
- `google_sign_in` + `googleapis` for Google Drive backup, `workmanager` for
  periodic background backups.
- `pdf` / `printing` for bill generation, `share_plus` for sharing exports.

## Getting started

```
flutter pub get
flutter run
```

The app is Android-only by design (see `dependency_overrides` in
`pubspec.yaml` and the `ios: false` launcher-icon config).

### Google Drive backup setup

Google Sign-In and Drive backup require a Google Cloud/Firebase OAuth
client that isn't checked into this repo. See
[docs/google-drive-setup.md](docs/google-drive-setup.md) for how to
provision it, and [docs/privacy-policy.html](docs/privacy-policy.html) for
the privacy policy required by Google's OAuth consent screen.

### Building a release APK

```
flutter build apk --release
```

The release build currently signs with the debug keystore (see
`android/app/build.gradle.kts`), which is sufficient for installing on your
own device without going through the Play Store.

## Project structure

- `lib/models/` — Hive-backed data models (orders, customers, companies,
  banks, expenses, payments, ledger).
- `lib/providers/` — Riverpod providers/state notifiers.
- `lib/screens/` — top-level screens.
- `lib/services/` — PDF generation, exports, Google Drive backup client,
  background backup task.
- `lib/storage/` — Hive box setup and keys.
- `lib/router/` — `go_router` route definitions.
