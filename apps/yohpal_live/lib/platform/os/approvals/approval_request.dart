class ApprovalRequest {
  final String id;
  final String action;
  final String module;
  final String status;
  final String requestedBy;
  final String? approvedBy;
  final DateTime createdAt;
  const ApprovalRequest({
    required this.id,
    required this.action,
    required this.module,
    required this.status,
    required this.requestedBy,
    this.approvedBy,
    required this.createdAt,
  });
}
