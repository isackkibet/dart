class FloatingPermissions {
  final bool enabled;
  final bool autoFloating;
  final bool allowCellular;
  final bool batterySaverBlocked;
  final bool emergencyDisabled;
  const FloatingPermissions({
    required this.enabled,
    required this.autoFloating,
    required this.allowCellular,
    required this.batterySaverBlocked,
    required this.emergencyDisabled,
  });
  bool get canUseFloating {
    return enabled && !emergencyDisabled && !batterySaverBlocked;
  }
}
