import 'package:flutter/material.dart';

enum VideoOverflowAction {
  askAi,
  chatWithCreator,
  report,
  notInterested,
  save,
  copyLink,
}

Future<void> showVideoOverflowSheet({
  required BuildContext context,
  required String videoId,
  required String creatorId,
}) async {
  final action = await showModalBottomSheet<VideoOverflowAction>(
    context: context,
    useSafeArea: true,
    builder: (ctx) {
      return Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.auto_awesome_outlined),
            title: const Text('Ask AI about this video'),
            onTap: () => Navigator.pop(ctx, VideoOverflowAction.askAi),
          ),
          ListTile(
            leading: const Icon(Icons.chat_bubble_outline),
            title: const Text('Chat with creator'),
            onTap: () =>
                Navigator.pop(ctx, VideoOverflowAction.chatWithCreator),
          ),
          ListTile(
            leading: const Icon(Icons.bookmark_border),
            title: const Text('Save'),
            onTap: () => Navigator.pop(ctx, VideoOverflowAction.save),
          ),
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('Copy link'),
            onTap: () => Navigator.pop(ctx, VideoOverflowAction.copyLink),
          ),
          ListTile(
            leading: const Icon(Icons.visibility_off_outlined),
            title: const Text('Not interested'),
            onTap: () =>
                Navigator.pop(ctx, VideoOverflowAction.notInterested),
          ),
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: const Text('Report'),
            onTap: () => Navigator.pop(ctx, VideoOverflowAction.report),
          ),
        ],
      );
    },
  );

  if (!context.mounted || action == null) return;

  switch (action) {
    case VideoOverflowAction.askAi:
      Navigator.pushNamed(context, '/ai/video', arguments: videoId);
    case VideoOverflowAction.chatWithCreator:
      Navigator.pushNamed(context, '/chat/creator', arguments: creatorId);
    case VideoOverflowAction.report:
      Navigator.pushNamed(context, '/report/video', arguments: videoId);
    case VideoOverflowAction.notInterested:
      Navigator.pushNamed(context, '/not-interested', arguments: videoId);
    case VideoOverflowAction.save:
    case VideoOverflowAction.copyLink:
      break;
  }
}
