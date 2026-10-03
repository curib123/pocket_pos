# Pocket Inventory

Pocket Inventory is a mobile-first, offline-first inventory tracker designed for sari-sari stores and other micro-retail shops.

## Product goal

Keep daily inventory work simple:

**Product Setup → Stock In → Stock Out → Stock Adjustment → Movement History**

This branch intentionally removes the checkout/POS workflow. There is no cart, cashier payment flow, sales receipt flow, customer-loan workflow, or POS AI assistant in the active product.

## Core inventory rules

1. **Stock In**: new stock = current stock + received quantity.
2. **Stock Out**: new stock = current stock - released quantity.
3. Stock Out is rejected when the requested quantity is greater than stock on hand.
4. **Adjustment** sets stock to the physical count and records a signed difference.
5. A no-op adjustment is rejected when physical stock already matches system stock.
6. Every inventory movement creates a dated history record.
7. Product editing cannot directly overwrite stock quantities.
8. New products start at zero stock; use Stock In to establish opening inventory.

## Sari-sari workflow

### Product Setup

Create only the information needed to identify and count the item:

- product name
- category
- tracking unit
- optional barcode

Stock is not entered in Product Setup.

### Stock In

Use when deliveries or restocks arrive.

Example:

Current stock: 12  
Received: 24  
New stock: 36

### Stock Out

Use when stock leaves the store, including:

- sold / released
- damaged
- expired
- personal / store use
- other

Stock cannot become negative.

### Adjustment

Use only for physical-count reconciliation.

Example:

System stock: 20  
Physical count: 17  
Difference: -3  
New system stock: 17

The signed difference is stored in movement history so upward and downward adjustments remain distinguishable.

## Offline-first storage

The application keeps local product data in Hive and mirrors inventory aggregates to SQLite. SQLite also contains the durable sync outbox used for future/optional cloud synchronization.

## Cloud sync

Supabase synchronization remains optional. The inventory app can start and operate without cloud credentials.

## Tech stack

- Flutter / Dart
- Provider
- Hive
- SQLite / sqflite
- Supabase (optional sync)
- Mobile Scanner for product barcode setup

## Development branch

The sari-sari inventory refactor is developed on:

`feature/sari-sari-inventory-flow`

Base branch:

`productionv3`
