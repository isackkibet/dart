abstract class YohPalApprovalService {
  Future<String> requestApproval({
    required String action,
    required String module,
    required String requestedBy,
    required Map<String, dynamic> payload,
  });

  Future<void> approve({
    required String approvalId,
    required String approvedBy,
  });

  Future<void> reject({
    required String approvalId,
    required String rejectedBy,
    required String reason,
  });
}
