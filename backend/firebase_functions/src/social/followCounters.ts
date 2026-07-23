import { onDocumentCreated, onDocumentDeleted } from 'firebase-functions/v2/firestore';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';

const db = () => getFirestore();

/**
 * Increments creatorProfiles/{creatorUid}.followerCount when a follow doc is created.
 * Admin SDK bypasses Firestore security rules, so the follower does not need
 * write access to the creator's profile document.
 */
export const onFollowCreated = onDocumentCreated(
  'follows/{followId}',
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    const creatorUid = data.creatorUid as string | undefined;
    if (!creatorUid) return;

    await db()
      .collection('creatorProfiles')
      .doc(creatorUid)
      .set(
        {
          followerCount: FieldValue.increment(1),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
  },
);

/**
 * Decrements creatorProfiles/{creatorUid}.followerCount when a follow doc is deleted.
 * Clamps to 0 so the counter never goes negative from duplicate deletes.
 */
export const onFollowDeleted = onDocumentDeleted(
  'follows/{followId}',
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    const creatorUid = data.creatorUid as string | undefined;
    if (!creatorUid) return;

    const ref = db().collection('creatorProfiles').doc(creatorUid);
    await db().runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      const current = (snap.data()?.followerCount as number) ?? 0;
      tx.set(
        ref,
        {
          followerCount: Math.max(0, current - 1),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    });
  },
);
