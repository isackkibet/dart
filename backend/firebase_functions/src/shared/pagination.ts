import * as admin from "firebase-admin";

export function encodeCursor(
  timestamp: admin.firestore.Timestamp | undefined
): string {
  if (!timestamp) return "";
  return Buffer.from(timestamp.toMillis().toString()).toString("base64");
}

export function decodeCursor(cursor: string): admin.firestore.Timestamp {
  const millis = parseInt(Buffer.from(cursor, "base64").toString("utf8"), 10);
  return admin.firestore.Timestamp.fromMillis(millis);
}
