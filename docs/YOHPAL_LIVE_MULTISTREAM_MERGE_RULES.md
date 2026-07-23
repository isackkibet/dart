# YohPal Live Multistreaming Merge Rules

## Objective

This update adds YohPal AI Multistreaming, Traffic Funnel, Autonomy, Creator Growth, Revenue Engine, and Command Center modules to the existing YohPal Live app.

## Non-Replacement Rule

Do not delete or overwrite existing YohPal Live features.

All new Flutter modules must be added under:
- `lib/features/multistream_v2`
- `lib/features/traffic_funnel`
- `lib/features/autonomy`
- `lib/features/creator_growth`
- `lib/features/command_center`
- `lib/features/revenue_engine`

Existing YohPal Live screens may call into these modules, but existing screens should not be replaced unless approved.

## Firebase Rule

Do not hardcode Firebase project IDs or Firebase app options.

Run:
```bash
flutterfire configure
```

inside:
```
apps/yohpal_live
```

to generate the real Firebase options for the selected project.

## Functions Rule

All new backend functions must be namespaced by module:

```
/multistream/*
/traffic/*
/autonomy/*
/growth/*
/revenue/*
/command-center/*
```

## Data Rule

All Firestore writes must include:

- `createdAt`
- `updatedAt`
- `createdBy`
- `tenantId` or `platformId` where applicable
- `status`
- audit fields where needed

## Finance Rule

Revenue, tips, payouts, and monetisation records must use ledger-style records. Never use only mutable balance fields as the source of truth.

## AI Autonomy Rule

AI may recommend by default. Auto-execution must be feature-flagged and auditable.

## Required Verification

Before merge approval, developer must run:

```bash
flutter analyze
flutter test
npm --prefix functions run build
firebase emulators:start
```
