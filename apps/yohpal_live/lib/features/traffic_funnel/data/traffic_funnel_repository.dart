import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/models/result.dart';
import '../domain/conversion_event.dart';
import '../domain/traffic_campaign.dart';

class TrafficFunnelRepository {
  TrafficFunnelRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _campaigns =>
      _firestore.collection('trafficCampaigns');

  CollectionReference<Map<String, dynamic>> get _conversions =>
      _firestore.collection('conversionEvents');

  Stream<List<TrafficCampaign>> watchCampaigns(String creatorId) {
    return _campaigns
        .where('creatorId', isEqualTo: creatorId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TrafficCampaign.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<Result<TrafficCampaign>> createCampaign(
    TrafficCampaign campaign,
  ) async {
    try {
      final doc = _campaigns.doc();
      await doc.set({
        ...campaign.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': campaign.creatorId,
        'updatedBy': campaign.creatorId,
      });
      return Success(
        TrafficCampaign(
          id: doc.id,
          creatorId: campaign.creatorId,
          sessionId: campaign.sessionId,
          name: campaign.name,
          sourcePlatform: campaign.sourcePlatform,
          campaignCode: campaign.campaignCode,
          status: campaign.status,
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        ),
      );
    } catch (error) {
      return Failure(
        AppFailure(
          message: 'Failed to create traffic campaign.',
          code: 'traffic_campaign_create_failed',
          details: error,
        ),
      );
    }
  }

  Future<Result<void>> captureConversion(ConversionEvent event) async {
    try {
      await _conversions.add({
        ...event.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      return const Success(null);
    } catch (error) {
      return Failure(
        AppFailure(
          message: 'Failed to capture conversion.',
          code: 'conversion_capture_failed',
          details: error,
        ),
      );
    }
  }
}
