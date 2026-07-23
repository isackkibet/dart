import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/ads_controller.dart';
import '../models/ad_campaign_model.dart';

class InFeedAdWidget extends StatefulWidget {
  final AdCampaignModel ad;

  const InFeedAdWidget({
    super.key,
    required this.ad,
  });

  @override
  State<InFeedAdWidget> createState() => _InFeedAdWidgetState();
}

class _InFeedAdWidgetState extends State<InFeedAdWidget> {
  bool _impressionTracked = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_trackImpression);
  }

  Future<void> _trackImpression() async {
    if (_impressionTracked || !mounted) return;
    _impressionTracked = true;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await context.read<AdsController>().trackImpression(
          campaignId: widget.ad.id,
          userId: user.uid,
          cost: widget.ad.costPerImpression,
        );
  }

  Future<void> _openAd() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && mounted) {
      await context.read<AdsController>().trackClick(
            campaignId: widget.ad.id,
            userId: user.uid,
            cost: widget.ad.costPerClick,
          );
    }
    final url = Uri.parse(widget.ad.clickUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openAd,
      child: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Sponsored',
              style: TextStyle(color: Colors.amberAccent, fontSize: 12),
            ),
            const SizedBox(height: 12),
            if (widget.ad.mediaUrl.isNotEmpty)
              Expanded(
                child: Image.network(widget.ad.mediaUrl, fit: BoxFit.cover),
              ),
            const SizedBox(height: 12),
            Text(
              widget.ad.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.ad.description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _openAd,
              child: const Text('Learn More'),
            ),
          ],
        ),
      ),
    );
  }
}
