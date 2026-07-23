import 'package:flutter/material.dart';

import '../gifts/live_gift_service.dart';

class LiveGiftButton extends StatefulWidget {
  const LiveGiftButton({
    super.key,
    required this.liveSessionId,
    this.service,
  });

  final String liveSessionId;
  final LiveGiftContract? service;

  @override
  State<LiveGiftButton> createState() => _LiveGiftButtonState();
}

class _LiveGiftButtonState extends State<LiveGiftButton> {
  late final LiveGiftContract _service =
      widget.service ?? FirebaseLiveGiftService();

  bool _sending = false;

  Future<void> _selectAndSend() async {
    final giftId = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => const _GiftPicker(),
    );

    if (giftId == null || _sending) return;

    setState(() => _sending = true);

    try {
      final receipt = await _service.sendGift(
        liveSessionId: widget.liveSessionId,
        giftId: giftId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gift sent \u2014 ${receipt.currency} '
            '${receipt.amount}',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Gift could not be sent. Check your wallet and try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: _sending ? null : _selectAndSend,
      icon: const Icon(Icons.card_giftcard),
      label: Text(
        _sending ? 'Sending\u2026' : 'Gift',
      ),
    );
  }
}

class _GiftPicker extends StatelessWidget {
  const _GiftPicker();

  @override
  Widget build(BuildContext context) {
    const gifts = [
      ('rose', 'Rose'),
      ('star', 'Star'),
      ('crown', 'Crown'),
    ];

    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: gifts
            .map(
              (gift) => ListTile(
                leading: const Icon(Icons.card_giftcard),
                title: Text(gift.$2),
                onTap: () => Navigator.of(context).pop(gift.$1),
              ),
            )
            .toList(),
      ),
    );
  }
}
