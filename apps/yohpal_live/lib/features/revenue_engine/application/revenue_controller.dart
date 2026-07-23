import 'package:flutter/foundation.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/models/result.dart';
import '../data/revenue_repository.dart';
import '../domain/ledger_entry.dart';
import '../domain/wallet_summary.dart';

class RevenueController extends ChangeNotifier {
  RevenueController({
    required RevenueRepository repository,
  }) : _repository = repository;

  final RevenueRepository _repository;
  WalletSummary? _summary;
  List<LedgerEntry> _ledger = const [];
  bool _isLoading = false;
  AppFailure? _failure;

  WalletSummary? get summary => _summary;
  List<LedgerEntry> get ledger => _ledger;
  bool get isLoading => _isLoading;
  AppFailure? get failure => _failure;

  Future<void> load(String creatorId) async {
    _isLoading = true;
    _failure = null;
    notifyListeners();
    final summaryResult = await _repository.getWalletSummary(creatorId);
    final ledgerResult = await _repository.getLedgerEntries(creatorId);
    if (summaryResult is Success<WalletSummary>) {
      _summary = summaryResult.data;
    } else if (summaryResult is Failure<WalletSummary>) {
      _failure = summaryResult.failure;
    }
    if (ledgerResult is Success<List<LedgerEntry>>) {
      _ledger = ledgerResult.data;
    } else if (ledgerResult is Failure<List<LedgerEntry>>) {
      _failure = ledgerResult.failure;
    }
    _isLoading = false;
    notifyListeners();
  }
}
