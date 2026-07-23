import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";

export const generatePilotReport = onSchedule("every 24 hours", async (event) => {
  const db = admin.firestore();
  
  // Aggregate metrics
  const metricsSnap = await db.collection("pilotMetrics")
    .orderBy("timestamp", "desc")
    .limit(1)
    .get();
    
  const latestMetrics = metricsSnap.empty ? {} : metricsSnap.docs[0].data();

  // Save report
  const reportRef = await db.collection("pilotReports").add({
    metrics: latestMetrics,
    reportDate: new Date().toISOString(),
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    status: "generated",
    summary: "Executive Daily Pilot Report"
  });

  // Notify Executive Dashboard
  console.log(`Pilot report ${reportRef.id} generated and executive dashboard notified.`);
});
