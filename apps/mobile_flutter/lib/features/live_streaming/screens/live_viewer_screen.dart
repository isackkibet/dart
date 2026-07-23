import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/live_stream_controller.dart';
import '../models/live_session_model.dart';
import '../repositories/live_repository.dart';
import '../repositories/live_commerce_repository.dart';
import '../widgets/live_chat_panel.dart';
import '../widgets/live_gift_panel.dart';
import '../widgets/live_product_card.dart';
import '../widgets/live_video_view.dart';

class LiveViewerScreen extends StatefulWidget {
  final String sessionId;

  const LiveViewerScreen({super.key, required this.sessionId});

  static const routeName = '/live-viewer';

  @override
  State<LiveViewerScreen> createState() => _LiveViewerScreenState();
}

class _LiveViewerScreenState extends State<LiveViewerScreen> {
  bool _joined = false;

  Future<void> _join(LiveSessionModel session) async {
    if (_joined) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _joined = true;
    await context.read<LiveStreamController>().joinLive(
          session: session,
          viewerId: user.uid,
        );
  }

  @override
  void dispose() {
    if (_joined) {
      context.read<LiveStreamController>().leaveLive();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = context.read<LiveRepository>();
    final live = context.watch<LiveStreamController>();
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title:
            Text('Live', style: TextStyle(color: theme.colorScheme.onSurface)),
      ),
      body: StreamBuilder<LiveSessionModel?>(
        stream: repo.watchLiveSession(widget.sessionId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final session = snapshot.data;
          if (session == null) {
            return Center(
              child: Text(
                'Live session not found',
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
            );
          }
          if (session.status != 'live') {
            return Center(
              child: Text(
                'Live is ${session.status}',
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
            );
          }
          if (!_joined) {
            Future.microtask(() => _join(session));
          }
          if (live.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (live.error != null) {
            return Center(
              child: Text(
                live.error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            );
          }
          if (live.room == null) {
            return Center(
              child: Text(
                'Joining live...',
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
            );
          }
          return Stack(
            children: [
              Positioned.fill(child: LiveVideoView(room: live.room!)),
              if (live.connectionState == LiveConnectionState.reconnecting)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.orange.shade700,
                    padding:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Reconnecting…',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                top: 20,
                left: 16,
                child: Text(
                  '${session.title} · ${session.viewerCount} watching',
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 390,
                child: StreamBuilder(
                  stream: context
                      .read<LiveCommerceRepository>()
                      .watchPinnedProduct(session.id),
                  builder: (context, productSnapshot) {
                    final product = productSnapshot.data;
                    if (product == null) return const SizedBox.shrink();
                    return LiveProductCard(
                      product: product,
                      repository: context.read<LiveCommerceRepository>(),
                    );
                  },
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 110,
                height: 260,
                child: LiveChatPanel(sessionId: session.id),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 20,
                child: LiveGiftPanel(
                  sessionId: session.id,
                  creatorId: session.creatorId,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
