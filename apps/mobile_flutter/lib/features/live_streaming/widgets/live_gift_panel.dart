import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/gift_service.dart';

/// Gift tiers must match the server-side catalog in
/// backend/firebase_functions/src/revenue/validatedGiftPurchase.ts exactly —
/// the amount shown here is display-only; the server decides what a
/// `giftType` actually costs and debits. There is no "Custom" tier anymore:
/// letting a user type an arbitrary amount straight into a Firestore write
/// (with no balance check) was the exact vulnerability this patch closes.
/// A validated variable-amount gift can be reintroduced later, but it needs
/// a server-enforced min/max, not a raw client-supplied integer.
const _giftCatalog = <(String emoji, String label, String type, int amountKes)>[
  ('\u{1F44F}', 'Clap', 'clap', 10),
  ('\u{1F339}', 'Rose', 'rose', 50),
  ('\u{1F525}', 'Fire', 'fire', 100),
  ('\u{1F451}', 'Crown', 'crown', 500),
];

class LiveGiftPanel extends StatefulWidget {
  final String sessionId;
  final String creatorId;

  const LiveGiftPanel({
    super.key,
    required this.sessionId,
    required this.creatorId,
  });

  @override
  State<LiveGiftPanel> createState() => _LiveGiftPanelState();
}

class _LiveGiftPanelState extends State<LiveGiftPanel> {
  bool _sending = false;

  Future<void> _sendGift(String giftType) async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      await context.read<GiftService>().sendGift(
            sessionId: widget.sessionId,
            creatorId: widget.creatorId,
            giftType: giftType,
          );
    } on GiftPurchaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That gift could not be sent. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (emoji, label, type, amount) in _giftCatalog)
          ElevatedButton(
            onPressed: _sending ? null : () => _sendGift(type),
            child: Text('$emoji $label KES $amount'),
          ),
        if (_sending)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      ],
    );
  }
}
