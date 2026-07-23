class PipEmergencySwitch {
  static bool disabledByOperations = false;
  static bool canRun(bool featureFlag) {
    return featureFlag && !disabledByOperations;
  }
}
