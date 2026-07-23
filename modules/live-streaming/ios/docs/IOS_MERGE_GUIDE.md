# iOS Merge Guide

## 1. Merge permission descriptions

Open existing:

```text
ios/Runner/Info.plist
```

Add:

```xml
<key>NSCameraUsageDescription</key>
<string>YohPal Live needs camera access so you can broadcast live video.</string>

<key>NSMicrophoneUsageDescription</key>
<string>YohPal Live needs microphone access so viewers can hear your live stream.</string>

<key>NSLocalNetworkUsageDescription</key>
<string>YohPal Live needs local network access to connect to the local streaming server during development testing.</string>

<key>NSBonjourServices</key>
<array/>
```

## 2. Local HTTPS/WSS

The Flutter app should connect to:

```
wss://<HOST_LAN_IP>/ws
```

Example:

```
wss://192.168.1.10/ws
```

Do not use:

```
localhost
127.0.0.1
```

on a physical iPhone.

## 3. Certificate trust

Install and trust:

```
modules/live-streaming/docker/certs/localhost.crt
```

on the iPhone.

Steps:

1. Send the certificate to the iPhone.
2. Open the certificate.
3. Install the profile.
4. Go to:

   Settings > General > About > Certificate Trust Settings

5. Enable full trust for the certificate.
6. Open:

   ```
   https://<HOST_LAN_IP>/health
   ```

   in Safari and confirm it loads.

## 4. ATS

Prefer certificate trust over disabling ATS.

If needed, add temporary debug-only ATS exception entries from:

```
modules/live-streaming/ios/Info.debug.ATS.merge.xml
```

Do not ship permissive ATS exceptions in production.

## 5. Xcode signing

For physical iPhone testing:

```
open ios/Runner.xcworkspace
select Runner target
confirm signing team
enable developer mode on iPhone if required
trust developer profile on device
```
