# iOS Background Mode Warning

For this prototype, do not enable broad background modes just to keep video live.

## Why

iOS restricts background execution for battery, privacy, and App Store policy reasons.

Live video broadcasting should normally remain a foreground experience unless YohPal Live has a clear product requirement and compliant technical design.

## Prototype policy

When the app enters background:
- stop stream, or
- show an interruption state, or
- reconnect when the app returns foreground

## Production decision needed later

Before production release, decide:
- should stream end when app backgrounds?
- should stream pause and auto-recover?
- should audio continue?
- should the creator be warned before leaving the app?
