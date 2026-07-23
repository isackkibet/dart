# Floating Experience Platform Blueprint

## Architecture
Floating Experience is a YohPal Platform capability, not a YohPal Live capability.

## Folder Structure
```
lib/platform/floating/
├── core/
├── runtime/
├── context/
├── actions/
├── adapters/
├── analytics/
├── permissions/
├── routing/
├── widgets/
├── pilot/
└── floating_platform.dart
```

## Module Adapters
- LiveFloatingAdapter
- JobsFloatingAdapter
- MarketFloatingAdapter

## Analytics Events
- floating_started
- floating_restored
- floating_closed
- floating_action
- floating_conversion
- floating_return
- floating_duration
