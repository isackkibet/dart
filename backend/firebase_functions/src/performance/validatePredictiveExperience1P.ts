import { onCall, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

const db = admin.firestore();

export const validatePredictiveExperience1P = onCall(
  { region: 'europe-west2' },
  async (request) => {
    if (!request.auth?.token.admin) {
      throw new HttpsError('permission-denied', 'Admin only');
    }

    const diagnostics = await db
      .collection('appPerformanceDiagnostics')
      .orderBy('createdAt', 'desc')
      .limit(100)
      .get();

    const samples = diagnostics.docs.map((doc) => doc.data());

    const screenTransitionSamples = samples
      .filter((s) => s.metricName === 'screen_transition_latency')
      .map((s) => Number(s.valueMs ?? 0))
      .filter((v) => v > 0);

    const averageScreenTransitionMs =
      screenTransitionSamples.length === 0
        ? null
        : Math.round(
            screenTransitionSamples.reduce((a, b) => a + b, 0) /
              screenTransitionSamples.length,
          );

    return {
      ok: true,
      diagnosticsChecked: diagnostics.size,
      averageScreenTransitionMs,
      readyForPilot:
        averageScreenTransitionMs !== null &&
        averageScreenTransitionMs <= 300,
    };
  },
);
