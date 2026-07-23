import { onCall, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

const db = admin.firestore();

export const validateContextIntelligence1R = onCall(
  { region: 'europe-west2' },
  async (request) => {
    if (!request.auth?.token.admin) {
      throw new HttpsError('permission-denied', 'Admin only');
    }

    const events = await db
      .collection('contextActionEvents')
      .orderBy('createdAt', 'desc')
      .limit(200)
      .get();

    const docs = events.docs.map((doc) => doc.data());
    const impressions = docs.filter((e) => e['eventType'] === 'impression').length;
    const acceptances = docs.filter((e) => e['eventType'] === 'acceptance').length;
    const dismissals  = docs.filter((e) => e['eventType'] === 'dismissal').length;

    return {
      ok: true,
      eventsChecked: events.size,
      impressions,
      acceptances,
      dismissals,
      readyForPilot: impressions > 0,
    };
  },
);
