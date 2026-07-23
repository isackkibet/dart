# Rollback Plan

## Rollback triggers

Rollback if:
- creators cannot start streams
- viewers cannot watch streams
- high crash rate
- high media failure rate
- TURN cost spike
- security incident
- moderation failure
- platform instability

## Rollback action

1. Disable "Go Live" entry point in YohPal Live.
2. Keep existing YohPal Live video feed unaffected.
3. Stop accepting new stream sessions.
4. Let active sessions end or force-end if required.
5. Preserve logs.
6. Notify support team.
7. Open incident report.

## Feature flag requirement

Production integration must place live streaming behind a feature flag:
```text
liveStreamingEnabled
```

## Rollback owner

Assign:
- technical owner
- product owner
- support owner
