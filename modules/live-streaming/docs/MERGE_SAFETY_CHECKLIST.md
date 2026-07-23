# Merge Safety Checklist

Before merging streaming overlay updates:

## Architecture

- [ ] Overlay does not replace YohPal Live foundation.
- [ ] Existing navigation remains intact.
- [ ] Existing auth/session ownership remains intact.
- [ ] Existing monetization/wallet modules remain intact.
- [ ] Existing creator profile/feed modules remain intact.

## Technical

- [ ] `.env.example` updated if config changed.
- [ ] Docker Compose still parses.
- [ ] Node smoke tests pass.
- [ ] Signaling contract tests pass.
- [ ] Flutter overlay files exist.
- [ ] Android/iOS merge docs updated if native changes occur.

## Runtime

- [ ] health endpoint works.
- [ ] WSS joins room.
- [ ] browser test client loads.
- [ ] local camera preview works.
- [ ] viewer can list producers.
