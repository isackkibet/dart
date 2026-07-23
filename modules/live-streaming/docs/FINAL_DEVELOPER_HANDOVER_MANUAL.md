# YohPal Live Streaming Overlay — Final Developer Handover Manual

## 1. Binding instruction

This module is an **overlay update** to the existing YohPal Live foundation. It must **not** replace, rename, delete, or bypass the existing YohPal Live foundation.

Do not replace:
- existing Flutter `main.dart`
- existing app shell
- existing routing/navigation
- existing authentication
- existing creator profile/feed modules
- existing wallet/monetization modules
- existing Firebase/backend services
- existing Android manifest
- existing iOS Info.plist

Only merge the streaming overlay through controlled integration points.

## 2. Final target folder

Place the overlay here:

```text
modules/live-streaming/
```

Final structure:

```text
modules/live-streaming/
  README.md
  .env.example
  package.json
  scripts/
  docker/
  server/
  flutter/
  android/
  ios/
  test-client/
  tests/
  docs/
```

## 3. Execution order

Developers must follow this order exactly.

### Step 1 — Read architecture documents

Read first:
- modules/live-streaming/docs/MASTER_BLUEPRINT.md
- modules/live-streaming/docs/MERGE_GUIDE.md
- modules/live-streaming/docs/FINAL_DEVELOPER_HANDOVER_MANUAL.md

Then read:
- modules/live-streaming/docs/LOCAL_DOCKER_WORKFLOW.md
- modules/live-streaming/docs/SMOKE_TEST_CHECKLIST.md
- modules/live-streaming/docs/production/GO_NO_GO_LAUNCH_CHECKLIST.md

### Step 2 — Install local tools

Required:
- Node.js 20+
- npm
- Docker
- Docker Compose
- OpenSSL
- Flutter SDK
- Android Studio
- Xcode for iOS

Verify:
```bash
cd modules/live-streaming
npm run doctor
```

### Step 3 — Create environment file

```bash
cd modules/live-streaming
cp .env.example .env
```

Edit:
```
ANNOUNCED_IP=<developer-machine-LAN-IP>
LAN_IP=<developer-machine-LAN-IP>
```

Example:
```
ANNOUNCED_IP=192.168.1.10
LAN_IP=192.168.1.10
```

Do not use 127.0.0.1 for physical Android/iOS device testing.

### Step 4 — Bootstrap dependencies

```bash
npm run bootstrap
```

This installs:
- root Node dependencies
- mediasoup server dependencies
- generated TURN config

### Step 5 — Generate TLS certificates

```bash
npm run certs
```

Generated files:
- docker/certs/localhost.crt
- docker/certs/localhost.key

Install and trust the certificate on test devices before Flutter WSS testing.

Guides:
- docs/TLS_CERTIFICATE_TRUST_GUIDE.md
- android/docs/ANDROID_MERGE_GUIDE.md
- ios/docs/IOS_MERGE_GUIDE.md

### Step 6 — Generate TURN config

```bash
npm run turn:config
```

Generated file:
- docker/turn/turnserver.conf

### Step 7 — Validate local environment

```bash
npm run lan:check
npm run ci:required-files
npm run ci:no-overwrite
```

### Step 8 — Start local Docker stack

```bash
npm run docker:up
```

Expected services:
- yohpal-live-mediasoup
- yohpal-live-turn
- yohpal-live-nginx

### Step 9 — Check local endpoints

```bash
npm run endpoints:check
```

Expected:
- https://<LAN_IP>/health
- https://<LAN_IP>/test-client/

### Step 10 — Generate local JWT tokens

Broadcaster token:
```bash
npm run token:broadcaster
```

Viewer token:
```bash
npm run token:viewer
```

Use these only for local prototype testing. Production tokens must be issued by the YohPal Live backend.

### Step 11 — Browser test client validation

Open:
```
https://<LAN_IP>/test-client/
```

Validate:
- WSS connects
- joinRoom succeeds
- routerRtpCapabilities appears
- listProducers returns response
- local camera preview works

### Step 12 — Merge Flutter overlay

Copy `modules/live-streaming/flutter/` into the existing YohPal Live Flutter project according to the existing project structure.

Add dependencies if missing:
```yaml
dependencies:
  flutter_webrtc: ^0.11.7
  web_socket_channel: ^3.0.1
```

Main entry point:
```dart
YohPalStreamingHomeScreen(config: config)
```

Example integration file:
- modules/live-streaming/flutter/lib/src/ui/yohpal_existing_app_integration_example.dart

Do not replace existing YohPal Live navigation. Add a route into the existing creator/live area.

### Step 13 — Merge Android native changes

Use:
- modules/live-streaming/android/docs/ANDROID_MERGE_GUIDE.md

Required:
- camera permission
- microphone permission
- internet permission
- network security config
- optional foreground service

Do not replace the existing Android manifest. Merge only required entries.

### Step 14 — Merge iOS native changes

Use:
- modules/live-streaming/ios/docs/IOS_MERGE_GUIDE.md

Required:
- NSCameraUsageDescription
- NSMicrophoneUsageDescription
- local network usage description for local prototype testing
- certificate trust for local HTTPS/WSS

Do not replace the existing Info.plist. Merge only required entries.

### Step 15 — Run Flutter validation

Inside the real YohPal Live Flutter app:
```bash
flutter pub get
flutter analyze
```

Then run on device:
```bash
flutter run
```

Validate:
- app launches
- existing YohPal Live foundation still works
- streaming entry screen opens
- creator preview works
- viewer screen opens

### Step 16 — Run Android device validation

Use:
- docs/validation/ANDROID_CERTIFICATION_TEMPLATE.md
- android/docs/ANDROID_DEBUG_CHECKLIST.md

Minimum Android pass:
- same Wi-Fi confirmed
- certificate installed
- health endpoint opens on phone
- camera permission works
- microphone permission works
- preview visible
- WSS join succeeds
- send transport created
- audio/video producer request sent
- cleanup works

### Step 17 — Run iOS device validation

Use:
- docs/validation/IOS_CERTIFICATION_TEMPLATE.md
- ios/docs/IOS_DEBUG_CHECKLIST.md

Minimum iOS pass:
- same Wi-Fi confirmed
- certificate installed and trusted
- health endpoint opens in Safari
- camera permission works
- microphone permission works
- preview visible
- WSS join succeeds
- receive transport flow reaches server
- cleanup works

### Step 18 — Run CI guardrails

From `modules/live-streaming/`:
```bash
npm run ci
```

Must pass before PR merge.

## 4. Required validation evidence

Every developer handover report must include:

### Local stack evidence

```bash
npm run docker:ps
npm run endpoints:check
```

Screenshot or copied output required.

### Server evidence

```bash
cd server/mediasoup
npm run test:smoke
npm run test:contract
```

### Browser evidence

Screenshot of:
```
https://<LAN_IP>/test-client/
```
showing successful joinRoom.

### Flutter evidence

Output from:
```bash
flutter analyze
```

### Android evidence

Completed:
- docs/validation/ANDROID_CERTIFICATION_TEMPLATE.md

### iOS evidence

Completed:
- docs/validation/IOS_CERTIFICATION_TEMPLATE.md

## 5. Developer responsibilities

The developer owns:
- merging without replacing YohPal Live foundation
- resolving existing repo import paths
- adding Flutter dependencies
- merging Android manifest changes safely
- merging iOS Info.plist changes safely
- running local Docker stack
- validating browser client
- testing Android physical device
- testing iOS physical device
- documenting unsupported devices
- producing validation evidence

## 6. What must not be done

Developers must not:
- replace existing YohPal Live app shell
- replace existing main.dart
- replace existing Android manifest wholesale
- replace existing iOS Info.plist wholesale
- hardcode production JWT tokens
- hardcode production TURN credentials
- use self-signed cert setup in production
- claim every device is supported without certification
- bypass CI guardrails
- launch public production without Go/No-Go approval

## 7. Local prototype success criteria

The local prototype is successful when:
- Docker stack starts
- /health works
- /test-client/ opens
- JWT token joins room
- browser signaling test passes
- Flutter app opens streaming module
- Android device can open creator preview
- iOS device can open viewer/creator flow
- no existing YohPal Live foundation feature is broken

## 8. Production readiness rule

The streaming overlay is not production-ready until all documents in `docs/production/` are satisfied.

Minimum required production files:
- PRODUCTION_TOPOLOGY.md
- TLS_AND_DOMAIN_STRATEGY.md
- TURN_PUBLIC_IP_STRATEGY.md
- MEDIASOUP_SCALING_LIMITS.md
- SECURE_TOKEN_ISSUANCE.md
- OBSERVABILITY_REQUIREMENTS.md
- GO_NO_GO_LAUNCH_CHECKLIST.md
- CONTROLLED_PILOT_PLAN.md
- ROLLBACK_PLAN.md
- INCIDENT_RESPONSE_PLAYBOOK.md

Final production decision must be one of:
- GO
- NO-GO
- CONTROLLED PILOT ONLY

## 9. Final merge checklist

Before merge:
- overlay placed under modules/live-streaming/
- no foundation files replaced
- .env.example reviewed
- Docker Compose config validates
- TURN config generated
- Node tests pass
- signaling contract tests pass
- browser test client works
- Flutter analyzer passes
- Android merge validated
- iOS merge validated
- CI passes
- validation evidence attached to PR

## 10. Final instruction to developer

This overlay upgrades YohPal Live streaming. It does not authorize removing or rewriting the existing YohPal Live foundation.

If an integration conflict exists, developers must report the conflict and propose a minimal adapter, not overwrite the foundation.

Production launch is prohibited until Go/No-Go approval is completed.
