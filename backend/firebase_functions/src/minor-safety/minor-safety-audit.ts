import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { onCall } from "firebase-functions/v2/https";
import { HttpsError } from "firebase-functions/v2/https";

const db = getFirestore();

export type AuditAction =
  | "creator_verification_approved"
  | "creator_verification_rejected"
  | "creator_verification_suspended"
  | "guardian_consent_granted"
  | "guardian_consent_revoked"
  | "manual_review_passed"
  | "manual_review_failed"
  | "content_classification_updated"
  | "minor_content_published"
  | "minor_content_removed";

export interface MinorSafetyAuditEntry {
  action: AuditAction;
  subjectType: "creator" | "video" | "consent";
  subjectId: string;
  actorId: string;
  notes?: string;
  metadata?: Record<string, unknown>;
}

export const writeMinorSafetyAudit = onCall(async (request) => {
  const actorId = request.auth?.uid;
  if (!actorId) {
    throw new HttpsError("unauthenticated", "Authentication is required.");
  }

  const entry: MinorSafetyAuditEntry = {
    action: request.data?.action,
    subjectType: request.data?.subjectType,
    subjectId: String(request.data?.subjectId ?? ""),
    actorId,
    notes: request.data?.notes,
    metadata: request.data?.metadata,
  };

  if (!entry.action || !entry.subjectType || !entry.subjectId) {
    throw new HttpsError(
      "invalid-argument",
      "action, subjectType and subjectId are required."
    );
  }

  await db.collection("minorSafetyAuditLog").add({
    ...entry,
    createdAt: FieldValue.serverTimestamp(),
    ip: request.rawRequest?.ip ?? null,
  });

  return { written: true };
});

export async function appendAuditTrail(
  collection: string,
  docId: string,
  entry: Omit<MinorSafetyAuditEntry, "subjectId">
): Promise<void> {
  await db
    .collection(collection)
    .doc(docId)
    .update({
      auditTrail: FieldValue.arrayUnion({
        ...entry,
        timestamp: new Date().toISOString(),
      }),
    });
}
