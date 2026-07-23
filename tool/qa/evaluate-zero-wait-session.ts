import fs from "node:fs";
import type { ZeroWaitSwipeResult } from "./zero-wait-swipe-result";

interface Thresholds {
  maximumTtffMs: number;
  maximumSpinnerRate: number;
  minimumCacheHitRate: number;
  maximumControllers: number;
}

interface Evaluation {
  decision: "PASS" | "FAIL";
  failures: string[];
  swipeCount: number;
  spinnerRate: number;
  cacheHitRate: number;
  maximumTtffMs: number;
  minimumRunway: number;
  maximumControllerCount: number;
}

function evaluate(
  results: ZeroWaitSwipeResult[],
  thresholds: Thresholds,
): Evaluation {
  const failures: string[] = [];

  if (results.length !== 100) {
    failures.push(`Expected 100 swipes; received ${results.length}.`);
  }

  const spinnerCount = results.filter((r) => r.spinnerShown).length;
  const cacheHitCount = results.filter(
    (r) =>
      r.cacheSource === "hot-controller" || r.cacheSource === "disk-cache",
  ).length;

  const spinnerRate =
    results.length === 0 ? 1 : spinnerCount / results.length;
  const cacheHitRate =
    results.length === 0 ? 0 : cacheHitCount / results.length;
  const maximumTtffMs = Math.max(0, ...results.map((r) => r.ttffMs));
  const minimumRunway = Math.min(
    Number.MAX_SAFE_INTEGER,
    ...results.map((r) => r.remainingAhead),
  );
  const maximumControllerCount = Math.max(
    0,
    ...results.map(
      (r) => r.activeControllerCount + r.initializingControllerCount,
    ),
  );

  if (minimumRunway < 100) {
    failures.push(`Prepared runway dropped to ${minimumRunway}.`);
  }

  if (maximumTtffMs > thresholds.maximumTtffMs) {
    failures.push(
      `Maximum TTFF ${maximumTtffMs}ms exceeds ${thresholds.maximumTtffMs}ms.`,
    );
  }

  if (spinnerRate > thresholds.maximumSpinnerRate) {
    failures.push(
      `Spinner rate ${(spinnerRate * 100).toFixed(2)}% exceeds target.`,
    );
  }

  if (cacheHitRate < thresholds.minimumCacheHitRate) {
    failures.push(
      `Cache-hit rate ${(cacheHitRate * 100).toFixed(2)}% is below target.`,
    );
  }

  if (maximumControllerCount > thresholds.maximumControllers) {
    failures.push(
      `Controller count reached ${maximumControllerCount}.`,
    );
  }

  for (const result of results) {
    if (result.status === "FAIL") {
      failures.push(
        `Swipe ${result.swipeNumber} failed${
          result.defectId ? ` (${result.defectId})` : ""
        }.`,
      );
    }
  }

  return {
    decision: failures.length === 0 ? "PASS" : "FAIL",
    failures,
    swipeCount: results.length,
    spinnerRate,
    cacheHitRate,
    maximumTtffMs,
    minimumRunway,
    maximumControllerCount,
  };
}

function main(): void {
  const inputPath = process.argv[2];
  const profile = process.argv[3];

  if (!inputPath || !profile) {
    console.error(
      "Usage: evaluate-zero-wait-session <results.json> <profile>",
    );
    process.exit(64);
  }

  const thresholdsByProfile: Record<string, Thresholds> = {
    "wifi-strong": {
      maximumTtffMs: 400,
      maximumSpinnerRate: 0.01,
      minimumCacheHitRate: 0.98,
      maximumControllers: 8,
    },
    "5g": {
      maximumTtffMs: 400,
      maximumSpinnerRate: 0.01,
      minimumCacheHitRate: 0.98,
      maximumControllers: 8,
    },
    "4g": {
      maximumTtffMs: 700,
      maximumSpinnerRate: 0.03,
      minimumCacheHitRate: 0.95,
      maximumControllers: 6,
    },
    "3g": {
      maximumTtffMs: 1200,
      maximumSpinnerRate: 0.08,
      minimumCacheHitRate: 0.85,
      maximumControllers: 4,
    },
    constrained: {
      maximumTtffMs: 1200,
      maximumSpinnerRate: 0.08,
      minimumCacheHitRate: 0.85,
      maximumControllers: 2,
    },
  };

  const thresholds = thresholdsByProfile[profile];
  if (!thresholds) {
    console.error(`Unknown profile: ${profile}`);
    process.exit(65);
  }

  const results = JSON.parse(
    fs.readFileSync(inputPath, "utf8"),
  ) as ZeroWaitSwipeResult[];

  const evaluation = evaluate(results, thresholds);
  console.log(JSON.stringify(evaluation, null, 2));
  process.exit(evaluation.decision === "PASS" ? 0 : 1);
}

main();
