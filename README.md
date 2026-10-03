# BantayStock

**Simple stock, klaro araw-araw.**

BantayStock is a mobile-first, offline-first inventory app for sari-sari stores and other small neighborhood retailers.

## Product goal

Keep daily inventory work simple:

**Product Setup → Stock In → Stock Out → Stock Adjustment → Movement History**

The active product intentionally avoids a traditional POS workflow. Cart, cashier payment, receipt, customer-loan, and POS-AI flows are not part of the primary experience.

## Daily workflow

- **Stock In** — add newly received inventory.
- **Stock Out** — remove inventory that left the shelf; negative inventory is blocked.
- **Adjust** — reconcile the system quantity with the actual physical count.
- **Activity** — review a readable chronological history of inventory movement.

## Primary navigation

1. **Home** — stock snapshot, low/out-of-stock attention, and quick stock actions.
2. **Inventory** — search products, filter stock status, add products, and open stock actions.
3. **Activity** — chronological Stock In, Stock Out, and Adjustment history.
4. **Settings** — preferences, categories, deleted products, backup/restore, and app information.

## Core inventory rules

1. Stock In adds to current quantity.
2. Stock Out subtracts quantity and is rejected when it would make inventory negative.
3. Adjustment sets stock to the physical count and records the signed difference.
4. Every inventory movement creates a dated history record.
5. Product editing does not directly overwrite stock quantities.
6. New products start at zero stock; use Stock In to establish opening inventory.

## Brand

BantayStock uses one chromatic hue: **Bantay Blue `#2457D6`**, supported by neutral surfaces and text. The UI uses Inter, avoids decorative gradients, and prioritizes fast one-handed mobile use.

See [BRAND.md](BRAND.md) for the complete identity and UI rules.

## Offline-first storage

SQLite is the single local persistence source. Product state, metadata, backup data, and the sync outbox are stored locally so the app remains usable without a network connection.

## Backup and restore

Settings provides JSON backup and restore for product data, metadata, and pending sync records. Restoring reloads the live Provider-backed ProductStore so the UI reflects restored data immediately.

## Cloud sync

Supabase synchronization is optional. BantayStock can start and operate without cloud credentials.

## Tech stack

- Flutter / Dart
- Provider
- SQLite / sqflite
- Supabase (optional sync)
- Mobile Scanner
- Material 3

## Development

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

The Android application label is **BantayStock**. The internal Dart package remains `nextpos` for compatibility with the existing import graph.

## Android release

Download the installable APK and its SHA-256 checksum from [GitHub Releases](https://github.com/curib123/pocket_pos/releases).

The **Android Release** workflow runs analysis, tests, release compilation, APK signature verification, and an offline Android startup check before publishing. It can be started manually, by pushing a version tag, or by updating the `release/android-apk` branch. The version and build number come from `pubspec.yaml`. Inter fonts are bundled so the interface does not need a network connection to load its font.

For a local build, run `flutter build apk --release`. The output is `build/app/outputs/flutter-apk/app-release.apk`.

Android signing uses `android/key.properties` when configured. Without it, the existing Gradle configuration uses a debug key for direct installation. A stable private release keystore is required for Play Store distribution and reliable updates across build machines. Never commit the keystore or its passwords.
