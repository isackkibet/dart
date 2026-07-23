# YohPal Live — Feature Accessibility & Activation Audit

**Date:** 2026-06-08  
**Auditor:** Claude Code (claude-sonnet-4-6)  
**Scope:** Flutter mobile app (`apps/mobile_flutter`) — routing, DI, wiring, backend connectivity

---

## 1. Orphaned Screens

These screens have complete implementations and route registrations in the router, but **no navigation entry point leads to them**.

| # | Screen | File | Route Constant | Status |
|---|---|---|---|---|
| 1 | `VideoFeedScreen` | `lib/features/video_feed/screens/video_feed_screen.dart` | None | Route case absent; tab replaced by SuggestedFeedScreen |
| 2 | `CustomerLivePurchaseHistoryScreen` | `lib/features/live_commerce/screens/customer_live_purchase_history_screen.dart` | `/purchase-history` ✓ | Route registered; no button, tab, or menu navigates there |
| 3 | `MerchantLiveSalesDashboardScreen` | `lib/features/live_commerce/screens/merchant_live_sales_dashboard_screen.dart` | `/merchant-live-dashboard` ✓ | Route registered; no button, tab, or menu navigates there |
| 4 | `GoLiveScreen` | `lib/features/live_streaming/screens/go_live_screen.dart` | Constant absent | `ScreenFactory.goLive()` never called; route `/go-live` never registered |
| 5 | `SearchScreen` | `lib/features/search/screens/search_screen.dart` | None | No route constant, no route case, not in any tab or menu |
| 6 | `LiveRtcViewerScreen` | `lib/features/live_rtc/screens/live_rtc_viewer_screen.dart` | `/live-rtc-viewer` ✓ | Route registered; **nothing in the feed navigates to it** |

---

## 2. Orphaned Services

Implemented services that are never instantiated or called from any active code path.

| # | Service | File | Problem |
|---|---|---|---|
| 1 | `VideoUploadService` | `lib/features/upload/services/video_upload_service.dart` | No upload picker screen exists; service never called |
| 2 | `VideoValidationService` | `lib/features/upload/services/video_validation_service.dart` | Same — no UI to trigger validation |
| 3 | `LiveProductRepository` | `lib/features/live_commerce/repositories/live_product_repository.dart` | Never instantiated anywhere in the app |
| 4 | `LiveAuctionRepository` | `lib/features/live_commerce/repositories/live_auction_repository.dart` | Never instantiated; no auction UI in any screen |
| 5 | `GroupBuyRepository` | `lib/features/live_commerce/repositories/group_buy_repository.dart` | Never instantiated; no group-buy UI in any screen |
| 6 | `LivePaymentRepository` | `lib/features/live_commerce/repositories/live_payment_repository.dart` | `LivePaymentOptionsSheet` uses it but the sheet is never shown in any screen |
| 7 | `LivePinnedProductCard` | `lib/features/live_commerce/widgets/live_pinned_product_card.dart` | Widget built but never included in `LiveRtcViewerScreen` or any live screen |
| 8 | `LivePaymentOptionsSheet` | `lib/features/live_commerce/widgets/live_payment_options_sheet.dart` | Widget built; `showModalBottomSheet` for it is never called |

---

## 3. Unused APIs

Backend endpoints that are implemented but have no frontend caller in any active code path.

| # | Backend Endpoint | Expected Caller | Problem |
|---|---|---|---|
| 1 | `POST /videos/init-upload` | `VideoUploadService.uploadVideo()` | Service implemented; no screen calls it |
| 2 | `POST /videos/complete-upload` | `VideoUploadService.uploadVideo()` | Same |
| 3 | `POST /live-commerce/pay/mpesa` | `LivePaymentRepository.payWithMpesa()` | Repository implemented; no screen triggers it |
| 4 | `POST /live-commerce/pay/wallet` | `LivePaymentRepository.payWithWallet()` | Same |
| 5 | `POST /live-commerce/auction/bid` | `LiveAuctionRepository.placeBid()` | Repository never called |
| 6 | `POST /live-commerce/group-buy/join` | `GroupBuyRepository.joinGroupBuy()` | Repository never called |

---

## 4. Unreachable Features

### 4.1 Video Upload — Completely Inaccessible

The entire upload pipeline is built but has no entry point.

- **What's missing:** An `UploadVideoScreen` (file picker → validate → upload → navigate to status)
- `VideoUploadService` and `VideoValidationService` are implemented and correct
- `VideoProcessingStatusScreen` is implemented and correct
- The "+" FAB in `app_shell.dart:26–66` shows only: AI Creator Studio, Go Live, Settings
- **Users cannot upload any video**

---

### 4.2 Live Session Discovery — Viewers Cannot Join Any Live Session

`SuggestedFeedScreen` (`lib/features/feed/screens/suggested_feed_screen.dart:21`) queries:

```
videos where status==public && visibility==public
```

It shows **only finished/published videos**, never active live sessions.

`liveSessions` collection is never queried in any screen visible to viewers. The `liveRtcViewer` route requires a `sessionId`, but no screen lists live sessions for a user to tap into.

**Result:** Hosts can start a live session (Go Live works). Viewers can never find or join it.

---

### 4.3 Live Commerce — Entirely Disconnected from Viewer Screen

`LiveRtcViewerScreen` (`lib/features/live_rtc/screens/live_rtc_viewer_screen.dart`) contains only:
- `RTCVideoView` (video stream)
- `LiveConnectionBadge`
- `LiveChatOverlay`
- Close button

It does **not** include:
- `LivePinnedProductCard` — product display
- `LivePaymentOptionsSheet` — payment trigger
- Any subscription to `liveSessions/{id}/pinnedProducts`

Users watching a live session see no products, cannot tap "Buy Now", and cannot initiate any payment.

---

### 4.4 Auction Bidding — Zero UI

`LiveAuctionRepository.placeBid()` is implemented in `lib/features/live_commerce/repositories/live_auction_repository.dart`. No widget displays a bid input. No screen calls `placeBid()`. The auction feature is entirely invisible to users.

---

### 4.5 Group Buy — Zero UI

`GroupBuyRepository.joinGroupBuy()` is implemented. No widget shows group buy status or a "Join" button. Completely inaccessible.

---

### 4.6 Search — No Entry Point

`SearchScreen` exists at `lib/features/search/screens/search_screen.dart`. `searchRepository` is registered in `AppDependencies`. But:
- No route constant exists in `yohpal_routes.dart`
- No case in `YohPalRouter.onGenerateRoute`
- No tab in `app_shell.dart`
- Not in the "+" more menu

`ScreenFactory.search()` exists but is never called.

---

### 4.7 Purchase History — No Entry Point

`CustomerLivePurchaseHistoryScreen` has a registered route `/purchase-history`. No screen or button navigates to it. The Wallet tab (`WalletStatusScreen`) has a "Creator earnings" link but no "My Purchases" link. Nowhere reachable from any user journey.

---

### 4.8 Merchant Live Dashboard — No Entry Point

`MerchantLiveSalesDashboardScreen` has a registered route `/merchant-live-dashboard`. The Business dashboard (`BusinessDashboardScreen`) links to: Create Business, Business TV, Business Radio. No "Live Sales Dashboard" card exists there. Unreachable by any merchant.

---

### 4.9 Merchant Product Pinning — Missing from Live Start Screen

`LiveStartScreen` has: title input, camera preview, Go Live, End Live. It does **not** include any way for the host/merchant to pin a product to their live session. `LiveProductRepository.pinProduct()` exists but is never called from `LiveStartScreen`.

---

## 5. Missing Wiring Issues

### 5.1 `LiveStartScreen._goLive()` — Double Camera Start Bug

**File:** `lib/features/live_rtc/screens/live_start_screen.dart:67–97`

The flow is:
1. `_startPreview()` at line 53 → `_host!.startCamera()` → creates local stream
2. `_goLive()` at line 67 → recreates `_host` with a new `MediasoupSignalingClient` → calls `_host!.startCamera()` again

The `_host` object is replaced at line 79, which discards the camera stream from `_startPreview`. Then `_host!.publish(iceServers)` is called but `localStream` was set on the **old** `_host`. The new host calls `startCamera()` a second time — a possible device access conflict on iOS.

---

### 5.2 `LiveStartScreen` Never Updates Status to `live`

**File:** `lib/features/live_rtc/screens/live_start_screen.dart:88`

`createLiveSession()` sets `status: starting`. After `_host!.publish(iceServers)` succeeds, the code sets `_isLive = true` but never calls `_repo.updateStatus(_sessionId!, LiveSessionStatus.live)`.

The `liveFailureDetector` Firebase Function marks sessions `failed` after 30s with no heartbeat, and viewers watching `liveSessions` will see incorrect state permanently stuck at `starting`.

---

### 5.3 `LiveRtcSessionRepository.createLiveSession` Missing `startedAt`

**File:** `lib/features/live_rtc/services/live_session_repository.dart:11`

The document is created without `startedAt`. Live session listings cannot be sorted chronologically by start time, and the admin monitoring dashboard cannot show accurate session timing.

---

### 5.4 `LiveChatOverlay` Missing Display Name on Send

**File:** `lib/features/live_rtc/widgets/live_chat_overlay.dart:76–83`

When sending a chat message, only `userId` is written. The `displayName` field is absent — messages display as `"User: <text>"` for every participant. `AppDependencies.instance.senderDisplayName` is available but not imported or used here.

---

### 5.5 `PublicVideoRepository` Bypasses `AppDependencies`

**File:** `lib/features/feed/screens/suggested_feed_screen.dart:11`

```dart
final repo = PublicVideoRepository();
```

This is called inside `build()`, creating a new repository on every rebuild. Firestore is a singleton so it's functionally safe, but the pattern prevents testing and injection. The repository should be passed from `ScreenFactory` via `AppDependencies.instance.firestore`.

---

### 5.6 `SuggestedFeedScreen` Has No Tap Interaction

**File:** `lib/features/feed/screens/suggested_feed_screen.dart:22–68`

The `PageView.builder` shows title/description overlays but wraps no `GestureDetector`. Users cannot tap a video to see details, navigate to the creator profile, like, comment, share, or detect whether the item is a live session.

---

### 5.7 `WalletStatusScreen` Has No Path to Purchase History

**File:** `lib/features/wallet_web/screens/wallet_status_screen.dart:138–148`

The screen has one ListTile linking to `YohPalRoutes.earnings`. No link to purchase history. Buyers have no path from the Wallet tab to their orders.

---

### 5.8 `BusinessDashboardScreen` Missing Merchant Live Commerce Links

**File:** `lib/features/business_os/screens/business_dashboard_screen.dart:28–50`

Three `_ActionCard`s: Create Business, Business TV, Business Radio. Missing: Live Sales Dashboard and a merchant-context live session start with product pinning.

---

### 5.9 Two `liveSessions` Implementations Diverge on Field Name

**Old** (`lib/features/live_streaming/repositories/live_repository.dart`): creates session with `creatorId` field.  
**New** (`lib/features/live_rtc/services/live_session_repository.dart`): creates session with `creatorUserId` field.

The Firestore security rule enforces `request.resource.data.creatorUserId == request.auth.uid`. Sessions created by the old `LiveRepository` will fail this rule, silently blocking all old-path live session creation.

---

## 6. Missing Route Issues

| # | Feature | Missing Route Constant | Missing Router Case | Fix Location |
|---|---|---|---|---|
| 1 | Search | `YohPalRoutes.search = '/search'` | No case for `/search` | `yohpal_routes.dart` + `router.dart` |
| 2 | Upload video | `YohPalRoutes.uploadVideo = '/upload-video'` | No case | Same |
| 3 | Live sessions list | `YohPalRoutes.liveSessions = '/live-sessions'` | No case | Same |
| 4 | Video detail | `YohPalRoutes.videoDetail = '/video-detail'` | No case | Same |

The `GoLiveScreen` route was never registered and is now superseded by `liveStart`. `ScreenFactory.goLive()` is dead code and should be removed.

---

## 7. Missing Provider / DI Issues

`AppDependencies` (`lib/core/di/app_dependencies.dart`) is missing the following registrations:

| # | Service | Why Needed | Fix |
|---|---|---|---|
| 1 | `VideoUploadService` | Needs `AppConfig.backendBaseUrl`; upload screen will need it | Add `late final videoUploadService = VideoUploadService(backendBaseUrl: AppConfig.backendBaseUrl)` |
| 2 | `VideoValidationService` | Stateless but benefits from central access | Add `final videoValidationService = VideoValidationService()` |
| 3 | `LiveProductRepository` | Viewer screen needs it for product subscription | Add `late final liveProductRepository = LiveProductRepository()` |
| 4 | `LivePaymentRepository` | Payment sheet needs `backendBaseUrl` and an `idToken` getter | Add factory or lazy getter |

---

## 8. Missing Backend Integrations

| # | Feature | Frontend Gap | Backend Status |
|---|---|---|---|
| 1 | Video upload | No `UploadVideoScreen`; `VideoUploadService` never called | `POST /videos/init-upload` + `POST /videos/complete-upload` implemented ✓ |
| 2 | Live session listing | No query on `liveSessions` in viewer-facing screens | `liveSessions` collection + indexes exist ✓ |
| 3 | Live commerce checkout | `LivePaymentOptionsSheet` never shown | `businessLiveCommerceApi` implemented ✓ |
| 4 | Product pinning by host | No UI in `LiveStartScreen` | Firestore `pinnedProducts` subcollection writable ✓ |
| 5 | Auction bid | No bid UI | `POST /live-commerce/auction/bid` implemented ✓ |
| 6 | Group buy join | No group-buy UI | `POST /live-commerce/group-buy/join` implemented ✓ |
| 7 | Live recording trigger | `live_recorder` never called from app | `POST /record/start` implemented ✓ (needs Firebase Function trigger wired) |

---

## Accessibility Score

| Subsystem | Implemented | Reachable from UI | Functionally Wired | Production Enabled |
|---|---|---|---|---|
| HLS Video Feed | 90% | 90% | 60% (no tap actions) | 80% (needs CDN config) |
| Video Upload | 80% | **0%** | 0% (no picker screen) | 0% |
| Video Processing Status | 100% | **0%** (only reachable if upload works) | 100% | 100% |
| Live Streaming (Host) | 95% | 95% (via "+" menu) | 85% (status bug) | 70% (RTC_SERVER_URL env needed) |
| Live Streaming (Viewer) | 90% | **0%** (no session discovery) | 90% | 70% |
| Live Chat | 100% | 90% (shown in viewer) | 90% (display name missing) | 100% |
| Live Commerce Checkout | 90% | **0%** (payment sheet never shown) | 80% | 80% (Daraja env needed) |
| Live Commerce - Auctions | 70% | **0%** | 0% | 0% |
| Live Commerce - Group Buy | 70% | **0%** | 0% | 0% |
| Purchase History | 100% | **0%** | 100% | 100% |
| Merchant Dashboard | 100% | **0%** | 100% | 100% |
| Search | 80% | **0%** | 0% | 0% |
| Wallet Top-Up | 100% | 100% | 100% | 80% (STK endpoint) |
| Creator Earnings | 100% | 90% (via Wallet tab) | 100% | 100% |
| Business OS (Create/TV/Radio) | 80% | 90% | 70% | 60% |
| AI Creator Studio | 90% | 90% (via "+" menu) | 80% | 70% |

---

## Activation Roadmap

---

### Phase 1 — Unlock Existing Features

Only wiring, routing, registration, and configuration fixes. No new feature logic.

---

#### P1-A: Add Search to the App

**Files:** `yohpal_routes.dart`, `router.dart`, `app_shell.dart`  
**Effort:** 15 min | **Risk:** Low

Add route constant:

```dart
// yohpal_routes.dart
static const search = '/search';
```

Add router case:

```dart
// router.dart
case YohPalRoutes.search:
  return MaterialPageRoute(
    settings: settings,
    builder: (_) => ScreenFactory.search(),
  );
```

Add search icon to the Feed AppBar or "+" more menu in `app_shell.dart`:

```dart
ListTile(
  leading: const Icon(Icons.search, color: YohPalColors.primary),
  title: const Text('Search', style: TextStyle(color: YohPalColors.highContrastText)),
  onTap: () {
    Navigator.pop(ctx);
    Navigator.pushNamed(context, YohPalRoutes.search);
  },
),
```

---

#### P1-B: Add Upload Video to the "+" FAB

**Files:** `yohpal_routes.dart`, `router.dart`, `app_shell.dart`  
**Effort:** 15 min (+ 3 hr for P2-A to create the screen) | **Risk:** Low

Add route constant:

```dart
// yohpal_routes.dart
static const uploadVideo = '/upload-video';
```

Add FAB entry in `app_shell.dart:46`:

```dart
ListTile(
  leading: const Icon(Icons.upload, color: YohPalColors.primary),
  title: const Text('Upload Video', style: TextStyle(color: YohPalColors.highContrastText)),
  onTap: () {
    Navigator.pop(ctx);
    Navigator.pushNamed(context, YohPalRoutes.uploadVideo);
  },
),
```

Add router case (once `UploadVideoScreen` created in P2-A):

```dart
case YohPalRoutes.uploadVideo:
  return MaterialPageRoute(
    settings: settings,
    builder: (_) => ScreenFactory.uploadVideo(),
  );
```

---

#### P1-C: Add Purchase History Link to Wallet Screen

**File:** `lib/features/wallet_web/screens/wallet_status_screen.dart:139`  
**Effort:** 10 min | **Risk:** None

After the existing "Creator earnings" `GlassCard`, add:

```dart
const SizedBox(height: 12),
GlassCard(
  padding: EdgeInsets.zero,
  child: ListTile(
    leading: const Icon(Icons.receipt_long, color: YohPalColors.primary),
    title: const Text('My Purchases', style: TextStyle(color: YohPalColors.highContrastText)),
    trailing: const Icon(Icons.chevron_right, color: YohPalColors.mutedText),
    onTap: () => Navigator.pushNamed(context, YohPalRoutes.purchaseHistory),
  ),
),
```

---

#### P1-D: Add Merchant Dashboard to Business Tab

**File:** `lib/features/business_os/screens/business_dashboard_screen.dart:46`  
**Effort:** 10 min | **Risk:** None

Add a fourth `_ActionCard` after the existing three:

```dart
const SizedBox(height: YohPalSpacing.sm),
_ActionCard(
  title: 'Live Sales Dashboard',
  subtitle: 'View orders, revenue and settlements from your live sessions',
  icon: Icons.store_outlined,
  route: YohPalRoutes.merchantDashboard,
),
```

---

#### P1-E: Add Live Sessions Discovery to the Feed

**File:** `lib/features/feed/screens/suggested_feed_screen.dart:21`  
**Effort:** 45 min | **Risk:** Low

Add a horizontal "Live Now" scroll row above the `PageView`:

```dart
// At the top of PageView build, wrap in a Column:
Column(
  children: [
    // Live Now row
    StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('liveSessions')
          .where('status', isEqualTo: 'live')
          .orderBy('startedAt', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snap) {
        final sessions = snap.data?.docs ?? [];
        if (sessions.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: sessions.length,
            itemBuilder: (context, i) {
              final s = sessions[i].data() as Map<String, dynamic>;
              return GestureDetector(
                onTap: () => Navigator.pushNamed(
                  context,
                  YohPalRoutes.liveRtcViewer,
                  arguments: LiveRtcViewerArgs(sessionId: sessions[i].id),
                ),
                child: Container(
                  width: 130,
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [
                        Icon(Icons.circle, color: Colors.red, size: 8),
                        SizedBox(width: 4),
                        Text('LIVE', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                      ]),
                      const SizedBox(height: 4),
                      Text(
                        s['title'] as String? ?? 'Live Session',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    ),
    // Existing PageView
    Expanded(child: PageView.builder( ... )),
  ],
),
```

---

#### P1-F: Fix `LiveStartScreen._goLive()` Double Camera Start and Missing Status Update

**File:** `lib/features/live_rtc/screens/live_start_screen.dart:53–97`  
**Effort:** 20 min | **Risk:** Medium

**Step 1** — Separate camera preview from mediasoup host. Store the preview stream directly:

```dart
// Add field:
MediaStream? _previewStream;

// Replace _startPreview():
Future<void> _startPreview() async {
  final stream = await navigator.mediaDevices.getUserMedia({
    'video': {'facingMode': 'user'},
    'audio': true,
  });
  setState(() {
    _localRenderer.srcObject = stream;
    _previewStream = stream;
    _previewing = true;
  });
}
```

**Step 2** — In `_goLive()`, reuse the preview stream and add status update:

```dart
Future<void> _goLive() async {
  if (_titleCtrl.text.trim().isEmpty || _previewStream == null) return;
  try {
    _sessionId = await _repo.createLiveSession(
      creatorUserId: widget.userId,
      title: _titleCtrl.text.trim(),
    );
    final iceServers = await _iceConfigService.getIceServers();
    final signaling = MediasoupSignalingClient(url: AppConfig.rtcServerUrl);
    _host = MediasoupHostService(
      signaling: signaling,
      sessionId: _sessionId!,
      peerId: widget.userId,
    );
    // Assign the already-open camera stream instead of reopening
    _host!.localStream = _previewStream;
    await _host!.publish(iceServers);

    // Mark session as live in Firestore
    await _repo.updateStatus(_sessionId!, LiveSessionStatus.live);

    _heartbeat.start(_sessionId!, widget.userId);
    setState(() {
      _isLive = true;
      _connectionState = LiveConnectionState.connected;
    });
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to go live: $e')));
    }
  }
}
```

---

#### P1-G: Fix `LiveRtcSessionRepository` — Add `startedAt`

**File:** `lib/features/live_rtc/services/live_session_repository.dart:11`  
**Effort:** 5 min | **Risk:** None

```dart
final ref = await _db.collection('liveSessions').add({
  'creatorUserId': creatorUserId,
  'title': title,
  'status': LiveSessionStatus.starting.value,
  'viewerCount': 0,
  'startedAt': FieldValue.serverTimestamp(),   // ADD THIS
  'createdAt': FieldValue.serverTimestamp(),
});
```

---

#### P1-H: Fix `LiveChatOverlay` Display Name

**File:** `lib/features/live_rtc/widgets/live_chat_overlay.dart:74–83`  
**Effort:** 10 min | **Risk:** None

```dart
// Add import at top:
import '../../../../core/di/app_dependencies.dart';

// In _send():
FirebaseFirestore.instance
    .collection('liveSessions')
    .doc(widget.sessionId)
    .collection('chatMessages')
    .add({
  'userId': widget.userId,
  'displayName': AppDependencies.instance.senderDisplayName, // ADD
  'message': text,
  'createdAt': FieldValue.serverTimestamp(),
});
```

---

### Phase 2 — Complete Partially Wired Features

---

#### P2-A: Create `UploadVideoScreen`

**New file:** `lib/features/upload/screens/upload_video_screen.dart`  
**Also requires:** `image_picker: ^1.1.2` in `pubspec.yaml`  
**Effort:** 3 hours | **Risk:** Low

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/di/app_dependencies.dart';
import '../../../../core/routing/route_args.dart';
import '../../../../core/routing/yohpal_routes.dart';
import '../services/video_validation_service.dart';
import '../services/video_upload_service.dart';

class UploadVideoScreen extends StatefulWidget {
  const UploadVideoScreen({super.key});

  @override
  State<UploadVideoScreen> createState() => _UploadVideoScreenState();
}

class _UploadVideoScreenState extends State<UploadVideoScreen> {
  File? _selectedFile;
  double _progress = 0;
  bool _uploading = false;
  String? _error;

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final result = await picker.pickVideo(source: ImageSource.gallery);
    if (result == null) return;
    setState(() {
      _selectedFile = File(result.path);
      _error = null;
    });
  }

  Future<void> _upload() async {
    if (_selectedFile == null) return;
    setState(() { _uploading = true; _error = null; _progress = 0; });
    try {
      final deps = AppDependencies.instance;
      await VideoValidationService().validate(_selectedFile!);

      final idToken = await deps.firebaseAuth.currentUser!.getIdToken();
      final videoId = await VideoUploadService(
        backendBaseUrl: AppConfig.backendBaseUrl,
      ).uploadVideo(
        file: _selectedFile!,
        userId: deps.userId,
        idToken: idToken!,
        onProgress: (p) => setState(() => _progress = p),
      );

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          YohPalRoutes.videoProcessingStatus,
          arguments: VideoProcessingStatusArgs(videoId: videoId),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Video')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _uploading ? null : _pickVideo,
              icon: const Icon(Icons.video_library),
              label: Text(_selectedFile == null ? 'Select Video' : _selectedFile!.path.split('/').last),
            ),
            const SizedBox(height: 24),
            if (_uploading) ...[
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 8),
              Text('${(_progress * 100).toStringAsFixed(0)}%',
                  textAlign: TextAlign.center),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const Spacer(),
            ElevatedButton(
              onPressed: (_selectedFile == null || _uploading) ? null : _upload,
              child: const Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }
}
```

Add to `ScreenFactory`:
```dart
static Widget uploadVideo() => const UploadVideoScreen();
```

---

#### P2-B: Wire Live Commerce into `LiveRtcViewerScreen`

**File:** `lib/features/live_rtc/screens/live_rtc_viewer_screen.dart`  
**Effort:** 2 hours | **Risk:** Medium

Add to `_LiveRtcViewerScreenState`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../live_commerce/repositories/live_product_repository.dart';
import '../../live_commerce/widgets/live_pinned_product_card.dart';
import '../../live_commerce/widgets/live_payment_options_sheet.dart';
import '../../../../core/di/app_dependencies.dart';

// Add field:
final _productRepo = LiveProductRepository();

// Add to Stack children in build():
StreamBuilder<List<Map<String, dynamic>>>(
  stream: _productRepo.watchPinnedProducts(widget.sessionId),
  builder: (ctx, snap) {
    final products = snap.data ?? [];
    if (products.isEmpty) return const SizedBox.shrink();
    final product = products.first;
    return LivePinnedProductCard(
      product: product,
      onPayNow: () async {
        final deps = AppDependencies.instance;
        final idToken = await deps.firebaseAuth.currentUser!.getIdToken();
        final orderId = const Uuid().v4();
        await FirebaseFirestore.instance
            .collection('businessOrders')
            .doc(orderId)
            .set({
          'buyerUserId': widget.userId,
          'merchantUserId': product['merchantUserId'],
          'productName': product['name'],
          'amount': product['price'],
          'sessionId': widget.sessionId,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });
        if (!mounted) return;
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => LivePaymentOptionsSheet(
            orderId: orderId,
            amount: (product['price'] as num).toDouble(),
            buyerUserId: widget.userId,
            idToken: idToken!,
            backendBaseUrl: AppConfig.backendBaseUrl,
          ),
        );
      },
    );
  },
),
```

---

#### P2-C: Wire Product Pinning into `LiveStartScreen`

**File:** `lib/features/live_rtc/screens/live_start_screen.dart`  
**Effort:** 2 hours | **Risk:** Low

When session is live (`_isLive == true`), show a "Pin Product" FAB. On tap, show a bottom sheet for product name, price, and stock. On submit, call `LiveProductRepository().pinProduct(sessionId, product)`.

---

#### P2-D: Replace `CreatorProfileScreen` Stub

**File:** `lib/features/creator_profile/screens/creator_profile_screen.dart`  
**Effort:** 3–4 hours | **Risk:** Low

The screen currently shows only `"CreatorProfileScreen module"`. Replace with links to at minimum:
- Settings (`YohPalRoutes.settings`)
- Creator Earnings (`YohPalRoutes.earnings`)
- My Purchases (`YohPalRoutes.purchaseHistory`)
- Merchant Dashboard (`YohPalRoutes.merchantDashboard`)
- Upload Video (`YohPalRoutes.uploadVideo`)

And display the user's name and role from `AppDependencies.instance.appUser`.

---

#### P2-E: Add Tap Interactions to `SuggestedFeedScreen`

**File:** `lib/features/feed/screens/suggested_feed_screen.dart`  
**Effort:** 1 hour | **Risk:** Low

Add right-side action overlays (like, comment, share) and a tap-to-pause/resume `GestureDetector` on the video, following a standard short-video UI pattern.

---

### Phase 3 — Production Hardening

| # | Action | File | Effort | Priority |
|---|---|---|---|---|
| 1 | Set `APP_CHECK_ENFORCEMENT=true` in Functions config | Firebase console / CI | 30 min | Critical |
| 2 | Set `RTC_SERVER_URL` in Flutter build args (`--dart-define`) | CI / build scripts | 15 min | Critical |
| 3 | Set `BACKEND_BASE_URL` in Flutter build args | CI / build scripts | 15 min | Critical |
| 4 | Configure TURN credentials in Firebase Functions env | Firebase console | 30 min | Critical |
| 5 | Configure Daraja production credentials | Firebase Functions env | 1 hour | Critical |
| 6 | Add `image_picker: ^1.1.2` to `pubspec.yaml` | `pubspec.yaml` | 5 min | High (blocks P2-A) |
| 7 | Add Firestore index: `liveSessions where status orderBy startedAt` | `firestore/indexes/firestore.indexes.json` | 5 min | High |
| 8 | Wire live recorder start via `onLiveSessionCreated` Firebase Function | `src/live/onLiveSessionCreated.ts` | 1 hour | Medium |
| 9 | Remove dead `ScreenFactory.goLive()` method | `lib/core/factories/screen_factory.dart:48–52` | 5 min | Low |
| 10 | Replace `PublicVideoRepository()` inline in `SuggestedFeedScreen` with injected instance | `lib/features/feed/screens/suggested_feed_screen.dart:11` | 10 min | Low |
| 11 | Add auction bid UI to viewer screen | new widget | 3 hours | Medium |
| 12 | Add group-buy join UI to viewer screen | new widget | 2 hours | Medium |
| 13 | Complete `CreatorProfileScreen` with real data | `creator_profile_screen.dart` | 4 hours | Medium |

---

## Quick Fix Priority Table

| Priority | Fix | File | Lines | Effort |
|---|---|---|---|---|
| P0 | Fix `_goLive()` double camera start | `live_start_screen.dart` | 53–97 | 20 min |
| P0 | Add `updateStatus(live)` after publish | `live_start_screen.dart` | 88 | 2 min |
| P0 | Add `startedAt` to `createLiveSession` | `live_session_repository.dart` | 11 | 2 min |
| P1 | Add Upload entry to "+" FAB + route | `app_shell.dart`, `yohpal_routes.dart`, `router.dart` | 46 | 15 min |
| P1 | Create `UploadVideoScreen` | new file | — | 3 hr |
| P1 | Add "Live Now" row to Feed | `suggested_feed_screen.dart` | 21 | 45 min |
| P1 | Add search route + FAB entry | `yohpal_routes.dart`, `router.dart`, `app_shell.dart` | — | 20 min |
| P1 | Add purchase history link in Wallet | `wallet_status_screen.dart` | 139 | 10 min |
| P1 | Add merchant dashboard to Business tab | `business_dashboard_screen.dart` | 46 | 10 min |
| P1 | Fix display name in chat overlay | `live_chat_overlay.dart` | 76 | 10 min |
| P2 | Wire live commerce into viewer | `live_rtc_viewer_screen.dart` | — | 2 hr |
| P2 | Product pinning UI in `LiveStartScreen` | `live_start_screen.dart` | — | 2 hr |
| P3 | Replace `CreatorProfileScreen` stub | `creator_profile_screen.dart` | — | 4 hr |
