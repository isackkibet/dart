enum YohPalUserRole {
  viewer,
  creator,
  moderator,
  operator,
  approver,
  finance,
  admin;

  static YohPalUserRole fromString(String? value) {
    return YohPalUserRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => YohPalUserRole.viewer,
    );
  }

  bool get canCreateLive {
    return this == YohPalUserRole.creator || this == YohPalUserRole.admin;
  }

  bool get canManageDestinations {
    return this == YohPalUserRole.creator ||
        this == YohPalUserRole.operator ||
        this == YohPalUserRole.admin;
  }

  bool get canApproveAutonomy {
    return this == YohPalUserRole.approver || this == YohPalUserRole.admin;
  }

  bool get canViewCommandCenter {
    return this == YohPalUserRole.operator ||
        this == YohPalUserRole.approver ||
        this == YohPalUserRole.admin;
  }

  bool get canManageFinance {
    return this == YohPalUserRole.finance || this == YohPalUserRole.admin;
  }

  bool get isAdmin => this == YohPalUserRole.admin;
}
