# YohPal Live — Run Guide & Feature Test Cases

**Date:** 2026-06-09  
**Branch:** fix/audit  
**Analyzer:** 0 errors · 0 warnings (`flutter analyze lib/`)

---

## Part 1 — Run Guide

### 1.1 Prerequisites

| Tool | Minimum version | Check |
|------|----------------|-------|
| Flutter SDK | 3.22+ | `flutter --version` |
| Dart | 3.4+ | `dart --version` |
| Xcode (iOS) | 15+ | `xcodebuild -version` |
| CocoaPods | 1.15+ | `pod --version` |
| Firebase CLI | 13+ | `firebase --version` |
| Node.js | 20+ | `node --version` |

---

### 1.2 Firebase Project Setup

These steps are required once per developer machine. Skip if already done.

```bash
# 1. Install Firebase CLI
npm install -g firebase-tools

# 2. Log in
firebase login

# 3. From repo root, select your project
cd /path/to/yohpal-video-app
firebase use <YOUR_PROJECT_ID>
```

Make sure `apps/mobile_flutter/lib/core/config/app_config.dart` has the correct `YOUR_PROJECT_ID` set via `--dart-define` at launch (see §1.4).  
The file uses compile-time constants — the in-code defaults are placeholders only.

---

### 1.3 Install Dependencies

```bash
cd apps/mobile_flutter
flutter pub get
cd ios && pod install && cd ..
```

---

### 1.4 Required `--dart-define` Variables

Every run command below must pass these four flags, or features that call the backend will silently fail (the UI still renders, but network calls hit placeholder URLs).

| Variable | Example value | Used by |
|----------|--------------|---------|
| `BACKEND_BASE_URL` | `https://us-central1-my-proj.cloudfunctions.net` | Video upload, live commerce payments |
| `RTC_SERVER_URL` | `wss://rtc.yohpal.com/ws` | Go Live, Live Viewer (mediasoup) |
| `WALLET_WEB_URL` | `https://us-central1-my-proj.cloudfunctions.net` | Wallet top-up STK |
| `YBOS_API_URL` | `https://us-central1-my-proj.cloudfunctions.net/ybosApi` | Business OS features |

---

### 1.5 Run Commands

#### iOS Simulator (most features testable)

```bash
cd apps/mobile_flutter

flutter run \
  --dart-define=BACKEND_BASE_URL=https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net \
  --dart-define=RTC_SERVER_URL=wss://rtc.yohpal.com/ws \
  --dart-define=WALLET_WEB_URL=https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net \
  --dart-define=YBOS_API_URL=https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net/ybosApi \
  -d <SIMULATOR_UDID>
```

List available simulators:
```bash
xcrun simctl list devices available | grep -i iphone
```

#### Physical iOS Device

Same command, add `-d <DEVICE_UDID>`.  
WebRTC camera requires a real device — simulator will show the camera preview placeholder only.

#### Android

```bash
flutter run \
  --dart-define=BACKEND_BASE_URL=... \
  --dart-define=RTC_SERVER_URL=... \
  --dart-define=WALLET_WEB_URL=... \
  --dart-define=YBOS_API_URL=... \
  -d <ANDROID_DEVICE_ID>
```

Note: `BACKEND_BASE_URL` on Android emulator should use `http://10.0.2.2:PORT` for localhost Functions.

---

### 1.6 Quick Local Smoke Test (No Backend Required)

To verify the app starts and navigation works without any backend services, run with placeholder values:

```bash
cd apps/mobile_flutter
flutter run -d <SIMULATOR_UDID>
```

All UI navigation, route wiring, and Firestore reads work. Network calls to `backendBaseUrl` and `rtcServerUrl` will fail gracefully with SnackBar errors.

---

### 1.7 Firebase Emulator Suite (Local Backend)

For full end-to-end testing without a deployed Firebase project:

```bash
# Terminal 1 — from repo root
firebase emulators:start --only auth,firestore,functions

# Terminal 2
cd apps/mobile_flutter
flutter run \
  --dart-define=BACKEND_BASE_URL=http://localhost:5001/demo-project/us-central1 \
  --dart-define=RTC_SERVER_URL=wss://rtc.yohpal.com/ws \
  --dart-define=WALLET_WEB_URL=http://localhost:5001/demo-project/us-central1 \
  --dart-define=YBOS_API_URL=http://localhost:5001/demo-project/us-central1/ybosApi \
  -d <SIMULATOR_UDID>
```

Emulator UI: http://localhost:4000

---

### 1.8 Firestore Index Required

The Live Now feed row queries:
```
liveSessions WHERE status == "live" ORDER BY startedAt DESC
```

This composite index must exist. Deploy it once:

```bash
firebase deploy --only firestore:indexes
```

If not yet in `firestore/indexes/firestore.indexes.json`, add:

```json
{
  "collectionGroup": "liveSessions",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "status", "order": "ASCENDING" },
    { "fieldPath": "startedAt", "order": "DESCENDING" }
  ]
}
```

Without this index the "Live Now" row stays empty even when live sessions exist.

---

## Part 2 — Feature Test Cases

### Legend

| Tag | Meaning |
|-----|---------|
| `[LOCAL]` | Testable on simulator with no backend services running |
| `[FIRESTORE]` | Requires Firebase project connected (Auth + Firestore emulator or prod) |
| `[BACKEND]` | Requires deployed Cloud Functions (`BACKEND_BASE_URL`) |
| `[RTC]` | Requires mediasoup server (`RTC_SERVER_URL`) |
| `[MPESA]` | Requires Daraja sandbox/production credentials configured |
| ✅ | Code is complete and wired |
| ⚠️ | Works in code; backend service must be running |
| ❌ | Not yet implemented in code |

---

### TC-01 — Auth: Register New Account `[FIRESTORE]` ✅

**Entry point:** App launch → Login screen

| Step | Action | Expected result |
|------|--------|----------------|
| 1 | Launch app | Loading spinner, then Login screen |
| 2 | Tap "Register" | Register screen opens |
| 3 | Enter email, password, display name | Fields accept input |
| 4 | Tap "Create Account" | Spinner → shell loads with bottom nav |
| 5 | Check Firestore `users/{uid}` | Document created with display name |

**Fail states to verify:** Empty fields → validation error shown. Duplicate email → Firebase error shown.

---

### TC-02 — Auth: Login Existing Account `[FIRESTORE]` ✅

| Step | Action | Expected result |
|------|--------|----------------|
| 1 | Launch app | Login screen |
| 2 | Enter registered email + password | — |
| 3 | Tap "Sign In" | Shell opens, correct display name in Profile tab |
| 4 | Kill and relaunch app | Auto-login, shell loads directly |

---

### TC-03 — Feed: HLS Video Playback `[BACKEND]` ⚠️

**Entry point:** Feed tab (index 0)

| Step | Action | Expected result |
|------|--------|----------------|
| 1 | Open app after login | Feed tab visible |
| 2 | Wait for stream load | Videos appear in `PageView` |
| 3 | Swipe up | Next video loads and plays |
| 4 | Check title/description overlays | Text visible bottom-left |
| 5 | When no videos in Firestore | "No videos yet. Check back soon!" shown |

**Known gap:** No tap-to-pause/like/comment/share. `PageView.builder` items have no `GestureDetector`. Video interaction is read-only at this time.

---

### TC-04 — Feed: Live Now Discovery Row `[FIRESTORE]` ✅

| Step | Action | Expected result |
|------|--------|----------------|
| 1 | Seed Firestore: add a `liveSessions` doc with `status:"live"` and `startedAt:now` | — |
| 2 | Open Feed tab | Red-bordered "LIVE" card appears above the video feed |
| 3 | Tap the card | `LiveRtcViewerScreen` opens with the session ID |
| 4 | Delete/update doc to `status:"ended"` | Card disappears from row in real-time |
| 5 | No live sessions exist | Row is hidden (zero height) |

Seed command (Firestore emulator):
```bash
firebase firestore:set liveSessions/test-session-1 \
  '{"status":"live","title":"Test Stream","creatorUserId":"uid-123","startedAt":{"__time__":"2026-06-09T10:00:00Z"}}'
```

---

### TC-05 — Upload Video `[BACKEND]` ⚠️

**Entry point:** "+" FAB → Upload Video

| Step | Action | Expected result |
|------|--------|----------------|
| 1 | Tap "+" FAB | Bottom sheet appears with: Upload Video, Go Live, Search, AI Creator Studio, Settings |
| 2 | Tap "Upload Video" | `UploadVideoScreen` opens |
| 3 | Tap the file picker area | System gallery picker opens (real device) or placeholder (simulator) |
| 4 | Select a video ≤250 MB and ≤5 min | File name shown in UI |
| 5 | Select a video >250 MB | Error message shown before upload attempt |
| 6 | Tap "Upload" with valid file | Progress bar + percentage visible |
| 7 | Upload completes | Navigates to `VideoProcessingStatusScreen` |
| 8 | Upload fails (no backend) | Red error message shown; button re-enabled |

**Note:** On iOS simulator the gallery picker shows no real videos. Use a physical device or Android emulator.

---

### TC-06 — Search `[FIRESTORE]` ✅

**Entry point:** "+" FAB → Search

| Step | Action | Expected result |
|------|--------|----------------|
| 1 | Tap "+" FAB → Search | SearchScreen opens with text field focused |
| 2 | Type a query matching a Firestore video title | Results list populates |
| 3 | Results show entity type chip and score | — |
| 4 | Clear query | Results list empties |
| 5 | Network unavailable | Loading spinner stops; no crash |

---

### TC-07 — Go Live (Host) `[RTC]` ⚠️

**Entry point:** "+" FAB → Go Live

| Step | Action | Expected result |
|------|--------|----------------|
| 1 | Tap "+" FAB → Go Live | `LiveStartScreen` opens; camera placeholder shown |
| 2 | Tap "Start Preview" | Camera permission prompt (real device); camera feed shown in `RTCVideoView` |
| 3 | Leave title field empty, tap "Go Live" | Button does nothing (guard: empty title) |
| 4 | Enter title, tap "Go Live" | Spinner; mediasoup publish attempt |
| 5 | Publish succeeds (RTC server up) | "LIVE" badge visible in AppBar; chat overlay visible; "Pin Product" FAB appears |
| 6 | Firestore `liveSessions/{id}` | `status:"live"`, `startedAt` set, `creatorUserId` matches logged-in user |
| 7 | Go Live fails (no RTC server) | SnackBar: "Failed to go live: [error]"; screen stays on preview |
| 8 | While live: tap "Pin Product" FAB | Bottom sheet with Name, Price, Stock fields |
| 9 | Fill fields, tap "Pin Now" | `liveSessions/{id}/pinnedProducts` doc created with `active:true` |
| 10 | Tap "End Live" | Firestore `status:"ended"`; screen pops |

---

### TC-08 — Live Viewer `[RTC]` ⚠️

**Entry point:** Feed → Live Now card → tap session

Requires TC-07 to be active (a live session must exist).

| Step | Action | Expected result |
|------|--------|----------------|
| 1 | Tap a "LIVE" card in feed | `LiveRtcViewerScreen` opens; "Connecting" badge visible |
| 2 | RTC server up | Remote video stream appears; badge turns "Connected" |
| 3 | Type in chat field; tap Send | Message appears in overlay with display name |
| 4 | Host pins a product (TC-07 step 8–9) | `LivePinnedProductCard` appears bottom-right: name, price, "Pay Now" button |
| 5 | Tap "Pay Now" | Firestore `businessOrders` doc created; `LivePaymentOptionsSheet` opens |
| 6 | Enter M-Pesa phone; tap "Pay via M-Pesa" | Payment attempt; STK push on real device `[MPESA]` |
| 7 | Tap "Pay via Wallet" | Wallet deduction attempt `[BACKEND]` |
| 8 | Tap X (close) | Screen pops; viewer heartbeat stops |
| 9 | No RTC server | "Connecting" stays; reconnect attempts logged |

---

### TC-09 — Live Chat Display Name `[FIRESTORE]` ✅

| Step | Action | Expected result |
|------|--------|----------------|
| 1 | Two test accounts both join same live session | — |
| 2 | Each sends a chat message | Messages show `displayName: [user's name]` not "User" |
| 3 | Check Firestore `chatMessages` docs | `displayName` field populated (not null) |

---

### TC-10 — Creator Profile Navigation `[LOCAL]` ✅

**Entry point:** Profile tab (index 4)

| Step | Action | Expected result |
|------|--------|----------------|
| 1 | Tap Profile tab | Screen shows avatar initial, display name, role chip |
| 2 | Tap "Settings" | SettingsScreen opens |
| 3 | Tap "Creator Earnings" | CreatorEarningsScreen opens |
| 4 | Tap "My Purchases" | CustomerLivePurchaseHistoryScreen opens |
| 5 | Tap "Merchant Dashboard" | MerchantLiveSalesDashboardScreen opens |
| 6 | Tap "Upload Video" | UploadVideoScreen opens |
| 7 | Tap "AI Creator Studio" | AIEditorScreen opens |
| 8 | Back navigation from each | Returns to Profile |

---

### TC-11 — Wallet Top-Up `[MPESA]` ⚠️

**Entry point:** Wallet tab (index 2)

| Step | Action | Expected result |
|------|--------|----------------|
| 1 | Tap Wallet tab | WalletStatusScreen opens with amount + phone fields |
| 2 | Enter amount `100` and phone `254700000000` (sandbox) | — |
| 3 | Tap "Pay with M-Pesa" | Loading spinner; STK push initiated |
| 4 | STK completes | Navigates to `WalletCompletionScreen` |
| 5 | Enter invalid amount (letters) | Error: "Enter a valid amount in KES" |
| 6 | Leave phone empty | Error: "Enter your M-Pesa phone number" |

---

### TC-12 — Purchase History `[FIRESTORE]` ✅

**Entry point:** Wallet tab → "My Purchases" OR Profile → "My Purchases"

| Step | Action | Expected result |
|------|--------|----------------|
| 1 | Open My Purchases with no orders | "No purchases yet." |
| 2 | Seed `businessOrders` doc with `buyerUserId` = current user | Order appears with product name, KES amount, status |
| 3 | Real-time: add second order | List updates without reload |
| 4 | Order with `receiptNumber` | Receipt number shown as trailing text |

---

### TC-13 — Merchant Live Sales Dashboard `[FIRESTORE]` ✅

**Entry point:** Business tab → "Live Sales Dashboard" OR Profile → "Merchant Dashboard"

| Step | Action | Expected result |
|------|--------|----------------|
| 1 | Open with no orders | Total Revenue: KES 0; Paid Orders: 0 |
| 2 | Seed `businessOrders` doc with `merchantUserId` = current user, `status:"paid"`, `amount:500` | Revenue: KES 500; Paid Orders: 1 |
| 3 | Seed order with `status:"pending"` | Count not added to revenue |
| 4 | Orders list shows product name, KES, payment method, status chip | — |

---

### TC-14 — Business OS Navigation `[LOCAL]` ✅

**Entry point:** Business tab (index 3)

| Step | Action | Expected result |
|------|--------|----------------|
| 1 | Tap Business tab | BusinessDashboardScreen with 4 cards |
| 2 | Tap "Create Business Account" | CreateBusinessScreen opens |
| 3 | Tap "Business TV Studio" | BusinessTvScreen opens |
| 4 | Tap "Business Radio Studio" | BusinessRadioScreen opens |
| 5 | Tap "Live Sales Dashboard" | MerchantLiveSalesDashboardScreen opens |

---

### TC-15 — Chat `[FIRESTORE]` ✅

**Entry point:** Chat tab (index 1)

| Step | Action | Expected result |
|------|--------|----------------|
| 1 | Tap Chat tab | ChatListScreen opens with conversation list |
| 2 | Tap a conversation | ChatRoomScreen opens |
| 3 | Type and send message | Message appears in list |
| 4 | Real-time: second device sends message | Message appears without reload |

---

### TC-16 — AI Creator Studio `[BACKEND]` ⚠️

**Entry point:** "+" FAB → AI Creator Studio OR Profile → AI Creator Studio

| Step | Action | Expected result |
|------|--------|----------------|
| 1 | Tap AI Creator Studio | `AIEditorScreen` opens |
| 2 | Submit an AI job | Request sent to `BACKEND_BASE_URL` |
| 3 | No backend | SnackBar error; no crash |

---

### TC-17 — Settings `[LOCAL]` ✅

**Entry point:** "+" FAB → Settings OR Profile → Settings

| Step | Action | Expected result |
|------|--------|----------------|
| 1 | Open Settings | SettingsScreen renders |
| 2 | Log out (if button exists) | Returns to LoginScreen |

---

### TC-18 — Creator Earnings `[FIRESTORE]` ✅

**Entry point:** Wallet tab → "Creator earnings" OR Profile → "Creator Earnings"

| Step | Action | Expected result |
|------|--------|----------------|
| 1 | Open earnings | `CreatorEarningsScreen` opens with creator's stats |
| 2 | No earnings data | Shows zero state |

---

### TC-19 — Multistream Setup `[LOCAL]` ✅

**Entry point:** Route `/multistream` (not yet in FAB — navigate programmatically or add manually)

| Step | Action | Expected result |
|------|--------|----------------|
| 1 | Navigate to `/multistream` | `MultistreamSetupScreen` opens |

**Note:** No FAB or nav entry exists for multistream. Entry point gap not addressed by current activation work.

---

### TC-20 — Video Processing Status `[BACKEND]` ⚠️

Reached automatically after successful upload (TC-05 step 7).

| Step | Action | Expected result |
|------|--------|----------------|
| 1 | After upload, status screen opens | `VideoProcessingStatusScreen` shows progress |
| 2 | Firestore `videos/{videoId}` updates | UI reflects current processing state in real-time |

---

## Part 3 — Known Gaps (Not Fixed by Current Activation)

These are identified in the audit but not yet addressed in code:

| Gap | Severity | Description |
|-----|----------|-------------|
| Feed video tap | P2 | `PageView.builder` items have no `GestureDetector` — can't like, comment, share, or navigate to creator |
| Auction bid UI | P3 | `LiveAuctionRepository.placeBid()` exists; zero viewer UI |
| Group buy UI | P3 | `GroupBuyRepository.joinGroupBuy()` exists; zero viewer UI |
| Multistream entry point | P2 | `MultistreamSetupScreen` has no nav entry point in shell or FAB |
| `PublicVideoRepository()` in `build()` | Low | Creates new repo instance on every rebuild; functional but untestable |
| Firestore schema mismatch | Medium | Old `LiveRepository` uses `creatorId`; new uses `creatorUserId`. Old path sessions fail security rules |
| Live recorder | P3 | `POST /record/start` never triggered from app |
| App Check enforcement | Prod-only | `APP_CHECK_ENFORCEMENT` not enabled |

---

## Part 4 — Environment Readiness Checklist

Before a pilot/production run, confirm each item:

```
[ ] Firebase project created and google-services.json / GoogleService-Info.plist present
[ ] Firestore security rules deployed (firestore.rules)
[ ] Firestore indexes deployed (firestore.indexes.json) — especially liveSessions composite
[ ] Firebase Auth — Email/Password provider enabled
[ ] BACKEND_BASE_URL — Cloud Functions deployed and URL confirmed
[ ] RTC_SERVER_URL — mediasoup server running and accessible
[ ] WALLET_WEB_URL — wallet Functions deployed
[ ] YBOS_API_URL — YBOS Functions deployed
[ ] Daraja credentials set in Functions config (MPESA_CONSUMER_KEY, etc.)
[ ] TURN server credentials configured in Functions env
[ ] image_picker permissions in Info.plist: NSPhotoLibraryUsageDescription
[ ] Camera + microphone permissions in Info.plist: NSCameraUsageDescription, NSMicrophoneUsageDescription
[ ] flutter pub get && pod install run successfully
[ ] flutter analyze lib/ → 0 issues
```

---

## Part 5 — Quick Reference: Entry Points Matrix

| Feature | Tab | FAB "+" | Profile tile | Route constant |
|---------|-----|---------|-------------|----------------|
| Feed / Live Now | Live (0) | — | — | `/` shell |
| Chat | Chat (1) | — | — | `/chat-room` |
| Wallet Top-Up | Wallet (2) | — | — | — |
| My Purchases | Wallet (2) → tile | — | ✓ | `/purchase-history` |
| Creator Earnings | Wallet (2) → tile | — | ✓ | `/earnings` |
| Business OS | Business (3) | — | — | `/business` |
| Live Sales Dashboard | Business (3) → card | — | ✓ | `/merchant-live-dashboard` |
| Profile | Profile (4) | — | — | `/creator-profile` |
| Settings | — | ✓ | ✓ | `/settings` |
| Upload Video | — | ✓ | ✓ | `/upload-video` |
| Go Live | — | ✓ | — | `/live-start` |
| Search | — | ✓ | — | `/search` |
| AI Creator Studio | — | ✓ | ✓ | `/ai-editor` |
| Live Viewer | Feed → card | — | — | `/live-rtc-viewer` |
| Multistream | — | — | — | `/multistream` ⚠️ no entry |
