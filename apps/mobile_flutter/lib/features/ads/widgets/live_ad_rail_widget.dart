import 'dart:async';
import 'package:flutter/material.dart';
import '../models/rewarded_ad_model.dart';

class LiveAdRailWidget extends StatefulWidget {
  final List<RewardedAdModel> ads;
  final void Function(RewardedAdModel ad) onOpenAd;

  const LiveAdRailWidget({
    super.key,
    required this.ads,
    required this.onOpenAd,
  });

  @override
  State<LiveAdRailWidget> createState() => _LiveAdRailWidgetState();
}

class _LiveAdRailWidgetState extends State<LiveAdRailWidget> {
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (widget.ads.isEmpty) return;
      setState(() {
        _index = (_index + 1) % widget.ads.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.ads.isEmpty) return const SizedBox.shrink();
    final ad = widget.ads[_index];
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.24,
        padding: const EdgeInsets.all(10),
        color: const Color(0xEE050816),
        child: Row(
          children: [
            if (ad.mediaUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  ad.mediaUrl,
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => widget.onOpenAd(ad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sponsored',
                        style: TextStyle(color: Colors.amber, fontSize: 11)),
                    Text(ad.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(ad.caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70)),
                    const Text('Read more',
                        style: TextStyle(color: Colors.cyanAccent)),
                    const Spacer(),
                    const Row(
                      children: [
                        Icon(Icons.thumb_up_alt_outlined,
                            color: Colors.white, size: 18),
                        SizedBox(width: 14),
                        Icon(Icons.comment_outlined,
                            color: Colors.white, size: 18),
                        SizedBox(width: 14),
                        Icon(Icons.share, color: Colors.white, size: 18),
                        SizedBox(width: 14),
                        Icon(Icons.shopping_cart_outlined,
                            color: Colors.white, size: 18),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
