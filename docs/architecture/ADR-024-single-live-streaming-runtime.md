# ADR-024: Single YohPal Live Streaming Runtime

## Status
Accepted

## Date
14 July 2026

## Decision owners
- Architecture Review Board
- Release Review Board
- YohPal Live Engineering
- YohPal Platform Operations

## Context
The YohPal repository contains:
1. A validated mediasoup streaming module under:
`modules/live-streaming/`
2. A separate application-side LiveKit implementation under:
`apps/mobile_flutter/lib/features/live_streaming/`

Maintaining two production streaming runtimes would create duplicated:
- session lifecycle logic,
- signaling behavior,
- reconnect handling,
- recording paths,
- analytics,
- moderation integration,
- gifting,
- chat,
- testing,
- operational monitoring,
- security controls.

## Decision
**mediasoup is the canonical YohPal Live production streaming runtime.**

The Flutter application must access streaming only through the shared
`YohPalLiveStreamingRuntime` interface.

The LiveKit implementation is not authorized as a parallel production path.

## Required actions
1. Register the mediasoup adapter in production dependency injection.
2. Disable LiveKit routes in production.
3. Map all live analytics to the canonical session ID.
4. Ensure recording and replay consume mediasoup session events.
5. Remove LiveKit after feature and migration parity is verified.
6. Any future runtime replacement requires a new Architecture Review Board ADR.

## Consequences

### Positive
- One signaling model.
- One reconnect strategy.
- One production evidence package.
- Lower operational complexity.
- Consistent Mission Control metrics.
- Reduced security and financial reconciliation risk.

### Negative
- Existing LiveKit-specific code must be migrated or retired.
- Any useful LiveKit-only UI behavior must be ported to the canonical adapter.

## Rollback
This ADR may be reversed only through a formal Architecture Review Board
decision supported by comparative physical-device, reliability, security,
cost and operational evidence.
