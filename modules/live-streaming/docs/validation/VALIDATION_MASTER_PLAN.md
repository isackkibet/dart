# YohPal Live Streaming Validation Master Plan

## Goal

Validate that the streaming overlay can safely merge into YohPal Live without breaking the existing foundation.

## Validation layers

1. Static file validation
2. Node server config and contract tests
3. Docker Compose config validation
4. HTTPS/WSS endpoint checks
5. Browser test client validation
6. Flutter analyzer validation inside existing YohPal Live app
7. Android physical device validation
8. iOS physical device validation
9. 30-minute stability test

## Pass criteria

The overlay is merge-ready when:
- server smoke tests pass
- signaling contract tests pass
- Docker Compose config parses
- `/health` responds over HTTPS
- `/test-client/` loads
- Flutter overlay imports compile inside YohPal Live
- at least one Android device passes broadcaster and viewer flows
- at least one iOS device passes broadcaster and viewer flows
