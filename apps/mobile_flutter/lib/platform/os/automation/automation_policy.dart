class AutomationPolicy {
  final String id;
  final String name;
  final String triggerType;
  final String actionType;
  final bool requiresApproval;
  final String minimumApproverRole;
  final bool enabled;

  const AutomationPolicy({
    required this.id,
    required this.name,
    required this.triggerType,
    required this.actionType,
    this.requiresApproval = true,
    this.minimumApproverRole = 'admin',
    this.enabled = true,
  });
}
