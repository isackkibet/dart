# YohPal Mesh Live v1.0.2-R — Security and Canonical Runtime Recovery

This recovery removes distributed server credentials, requires Firebase ID-token authentication and owner authorization, uses Firestore persistence, wires Mesh Control into Docker Compose, connects layout state to the canonical mediasoup room program API, adds the canonical mobile route `/mesh-live`, adds missing Flutter packages, validates signaling payloads, applies request-size and rate limits, and removes unsafe production secret defaults.

## Certification boundary
This repository is a repaired integration candidate. Physical-device, TURN-only, Docker runtime and protected-CI certification remain required before YECO PASS.
