import '../../../core/errors/app_failure.dart';
import '../../../core/models/result.dart';
import '../../../core/network/api_client.dart';
import '../domain/ledger_entry.dart';
import '../domain/wallet_summary.dart';

class RevenueRepository {
  RevenueRepository({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<Result<void>> sendGift({
    required String sessionId,
    required String creatorId,
    required String giftType,
    required double amount,
    required String currency,
    required String idempotencyKey,
  }) async {
    final result = await _apiClient.postJson(
      '/revenue/gifts',
      body: {
        'sessionId': sessionId,
        'creatorId': creatorId,
        'giftType': giftType,
        'amount': amount,
        'currency': currency,
        'idempotencyKey': idempotencyKey,
      },
    );
    if (result is Failure<Map<String, dynamic>>) {
      return Failure(result.failure);
    }
    return const Success(null);
  }

  Future<Result<void>> createPaidMessage({
    required String sessionId,
    required String creatorId,
    required String message,
    required double amount,
    required String currency,
    required String idempotencyKey,
  }) async {
    final result = await _apiClient.postJson(
      '/revenue/paid-messages',
      body: {
        'sessionId': sessionId,
        'creatorId': creatorId,
        'message': message,
        'amount': amount,
        'currency': currency,
        'idempotencyKey': idempotencyKey,
      },
    );
    if (result is Failure<Map<String, dynamic>>) {
      return Failure(result.failure);
    }
    return const Success(null);
  }

  Future<Result<WalletSummary>> getWalletSummary(String creatorId) async {
    final result = await _apiClient.getJson('/revenue/wallets/$creatorId');
    if (result is Failure<Map<String, dynamic>>) {
      return Failure(result.failure);
    }
    final data = result.dataOrNull?['data'];
    if (data is! Map<String, dynamic>) {
      return const Failure(
        AppFailure(
          message: 'Invalid wallet summary response.',
          code: 'invalid_wallet_summary_response',
        ),
      );
    }
    return Success(WalletSummary.fromMap(data));
  }

  Future<Result<List<LedgerEntry>>> getLedgerEntries(String creatorId) async {
    final result = await _apiClient.getJson('/revenue/ledger/$creatorId');
    if (result is Failure<Map<String, dynamic>>) {
      return Failure(result.failure);
    }
    final data = result.dataOrNull?['data'];
    if (data is! Map<String, dynamic>) {
      return const Failure(
        AppFailure(
          message: 'Invalid ledger response.',
          code: 'invalid_ledger_response',
        ),
      );
    }
    final entries = data['entries'];
    if (entries is! List) {
      return const Success([]);
    }
    return Success(
      entries
          .whereType<Map<String, dynamic>>()
          .map((item) => LedgerEntry.fromMap(item['id']?.toString() ?? '', item))
          .toList(),
    );
  }
}
