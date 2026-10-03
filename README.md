# BantayStock

**Simple stock, klaro araw-araw.**

BantayStock is a mobile-first inventory app for sari-sari stores and other small neighborhood retailers. The primary workflow is intentionally narrower than a traditional POS: know what is on hand and record changes quickly.

## Daily workflow

- **Stock In** — add newly received inventory.
- **Stock Out** — remove inventory that left the shelf; the app blocks negative stock.
- **Adjust** — enter the actual physical count when the system and shelf do not match.
- **Activity** — keep a readable history of inventory movement.

## Primary navigation

1. **Home** — inventory snapshot, low/out-of-stock attention, and the three quick actions.
2. **Inventory** — search products, filter stock status, add products, and open stock actions.
3. **Activity** — chronological Stock In, Stock Out, and Adjustment history.
4. **Settings** — currency, categories, deleted products, backup/restore, and app information.

Legacy POS, cart, loan, receipt, and AI-sales code is no longer exposed in the primary experience and can be removed as the data migration is completed.

## Brand

The product uses one chromatic hue only: **Bantay Blue `#2457D6`**, supported by neutral surfaces and text. The interface uses **Inter**, avoids gradients and decorative shadows, and communicates inventory states with icons and labels instead of red/green/yellow color coding.

See [BRAND.md](BRAND.md) for the complete identity and UI rules.

## Data architecture

SQLite is the durable offline store and backup source. Some legacy providers still read Hive while the migration is completed; inventory mutations are mirrored to SQLite so the UI remains usable during the transition.

## Development

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

The Android application label is **BantayStock**. The internal Dart package remains `nextpos` for compatibility with the existing import graph.
