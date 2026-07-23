# YohPal Video Engine V13 — Android/iOS 30-Minute Certification

**Version:** V13 Production Stabilization  
**Date:** 2026-07-07  
**Scope:** Physical device playback verification — HLS adaptive streaming, CDN delivery, quality switching

---

## Pre-flight Checklist

- [ ] Android physical device connected via ADB (API 30+)
- [ ] iOS physical device connected via Xcode (iOS 15+)
- [ ] `adb devices` confirms Android device listed
- [ ] Network: Wi-Fi and cellular (4G/5G) both accessible
- [ ] `cdn.stream.yohpal.com` reachable: `curl -sI https://cdn.stream.yohpal.com/` → HTTP/2 200
- [ ] Firebase Auth test account available
- [ ] Video-pipeline backend running: `npm run start:dev` in `backend/video-pipeline/`

---

## Android Certification (15 minutes)

### A1 — App Install & Launch (2 min)

```bash
cd apps/mobile_flutter
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell am start -n com.yohpal.app/.MainActivity
```

**Pass:** App launches to feed without crash; Impeller/Vulkan backend confirmed in logcat.

---

### A2 — HLS Playback on Wi-Fi (4 min)

1. Open the feed on device (Wi-Fi connected).
2. Tap first video — allow 3 seconds to buffer.
3. Pull logcat:
   ```bash
   adb logcat -s ExoPlayer:D flutter:D | grep -i "hls\|cdn\|720p\|quality"
   ```

**Pass criteria:**
- [ ] `recommendedDelivery: hls` in response payload
- [ ] `recommendedQuality: 720p` (Wi-Fi path)
- [ ] ExoPlayer resolves `cdn.stream.yohpal.com/videos-hls/{id}/playlist_720p.m3u8`
- [ ] No `firebasestorage.googleapis.com` URLs in segment requests
- [ ] Video plays without buffering stall >3 s

---

### A3 — Quality Fallback on Throttled Network (4 min)

1. Enable Android Developer Options → Network → "Limit background processes" or use ADB network throttle:
   ```bash
   adb shell settings put global network_preference 0   # force 2G-like
   ```
2. Restart the app; open feed.
3. Check delivery decision response:

**Pass criteria:**
- [ ] `recommendedQuality: 360p` when `networkType: 3g` or `lowDataMode: true`
- [ ] ExoPlayer uses `playlist_360p.m3u8`
- [ ] No playback crash during quality switch

Restore network:
```bash
adb shell settings delete global network_preference
```

---

### A4 — CDN Cache Headers (3 min)

```bash
curl -sI "https://cdn.stream.yohpal.com/videos-hls/$(adb shell am get-task-id 1)/master.m3u8" \
  | grep -i "cache-control\|x-cache\|age"
```

Or verify via a known video ID:
```bash
curl -sI "https://cdn.stream.yohpal.com/videos-hls/TEST_VIDEO_ID/master.m3u8"
```

**Pass criteria:**
- [ ] `cache-control: public, max-age=86400`
- [ ] Response < 200 ms on second request (CDN cache hit)

---

### A5 — HLS Segment Naming Validation (2 min)

```bash
curl -s "https://cdn.stream.yohpal.com/videos-hls/TEST_VIDEO_ID/playlist_360p.m3u8" \
  | grep "\.ts"
```

**Pass criteria:**
- [ ] Segments follow `v360p_NNN.ts` pattern (flat, no subdirectory)
- [ ] No `360p/segment_` or `360p/index.m3u8` references present

---

## iOS Certification (15 minutes)

### I1 — App Build & Install (3 min)

```bash
cd apps/mobile_flutter
flutter run --release -d <iOS_DEVICE_UDID>
```

Or via Xcode: open `apps/mobile_flutter/ios/Runner.xcworkspace` → select device → Run.

**Pass:** App launches; no `NSAppTransportSecurity` warnings in Xcode console.

---

### I2 — AVPlayer HLS Playback on Wi-Fi (4 min)

1. Open feed on device (Wi-Fi).
2. Tap first video.
3. Check Xcode console for:
   ```
   flutter: delivery=hls quality=720p
   flutter: playbackUrl=https://cdn.stream.yohpal.com/videos-hls/...
   ```

**Pass criteria:**
- [ ] `recommendedDelivery: hls`, `recommendedQuality: 720p`
- [ ] AVPlayer selects `playlist_720p.m3u8` variant
- [ ] No ATS error (CDN endpoint uses HTTPS/TLS 1.2+)
- [ ] Video plays without crash; thumbnail loads

---

### I3 — Quality Fallback (3 min)

1. Enable iOS Settings → Cellular → toggle "Low Data Mode" ON.
2. Return to app; open feed.

**Pass criteria:**
- [ ] `recommendedQuality: 360p` (low-data path)
- [ ] `playlist_360p.m3u8` used
- [ ] No crash; smooth fallback

Restore: disable Low Data Mode.

---

### I4 — Background Playback & PiP (3 min)

1. Start video playback.
2. Press Home → video should continue in background audio.
3. Return to app — video resumes without reload.

**Pass criteria:**
- [ ] Background audio playback active (AVAudioSession configured)
- [ ] No `EXC_BAD_ACCESS` or `AVPlayerItem` error in console

---

### I5 — Memory & Thermal Check (2 min)

Use Xcode Instruments → Activity Monitor during 5-minute feed scroll session.

**Pass criteria:**
- [ ] Memory < 250 MB peak during feed scroll
- [ ] No thermal throttle indicator in Instruments
- [ ] Frame rate ≥ 55 fps during scroll (Impeller renderer)

---

## Certification Sign-off

| Check | Android | iOS | Notes |
|---|---|---|---|
| A1/I1 — Launch | ☐ PASS ☐ FAIL | ☐ PASS ☐ FAIL | |
| A2/I2 — HLS 720p Wi-Fi | ☐ PASS ☐ FAIL | ☐ PASS ☐ FAIL | |
| A3/I3 — 360p fallback | ☐ PASS ☐ FAIL | ☐ PASS ☐ FAIL | |
| A4 — CDN cache headers | ☐ PASS ☐ FAIL | N/A | |
| A5 — Segment naming | ☐ PASS ☐ FAIL | ☐ PASS ☐ FAIL | |
| I4 — Background/PiP | N/A | ☐ PASS ☐ FAIL | |
| I5 — Memory/Thermal | N/A | ☐ PASS ☐ FAIL | |

**Overall result:** ☐ CERTIFIED ☐ BLOCKED

**Certified by:** _______________________  
**Date:** _______________________  
**Build hash:** _______________________

> All checks must PASS before proceeding to Sprint F release lock.
