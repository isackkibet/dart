export type TestStatus = "PASS" | "FAIL" | "BLOCKED";

export interface ZeroWaitSwipeResult {
  sessionId: string;
  testCaseId: string;
  platform: "android" | "ios";
  deviceId: string;
  deviceClass: "low-memory" | "standard" | "high-performance";
  networkClass:
    | "wifi-strong"
    | "wifi-weak"
    | "5g"
    | "4g"
    | "3g"
    | "constrained";
  buildNumber: string;
  commitHash: string;
  releaseTag: string;
  swipeNumber: number;
  videoId: string;
  feedIndex: number;
  ttffMs: number;
  spinnerShown: boolean;
  cacheSource: "hot-controller" | "disk-cache" | "network";
  inventoryCount: number;
  remainingAhead: number;
  activeControllerCount: number;
  initializingControllerCount: number;
  memoryMb: number;
  batteryPercent: number;
  thermalState: string;
  status: TestStatus;
  defectId?: string;
}
