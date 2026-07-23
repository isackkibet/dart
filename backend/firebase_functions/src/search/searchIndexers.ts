import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { db, FieldValue } from '../shared/firebaseAdmin';
import { generateSearchKeywords } from './searchKeywordsGenerator';

async function indexDocument(
  collection: string,
  docId: string,
  data: Record<string, unknown>,
): Promise<void> {
  const searchKeywords = generateSearchKeywords(data);
  await db.collection(collection).doc(docId).set(
    { searchKeywords, searchIndexedAt: FieldValue.serverTimestamp() },
    { merge: true },
  );
  await db.collection('searchIndexAuditLogs').add({
    collection,
    docId,
    keywordCount: searchKeywords.length,
    action: 'indexed',
    createdAt: FieldValue.serverTimestamp(),
  });
}

function shouldSkip(change: { before: FirebaseFirestore.DocumentSnapshot; after: FirebaseFirestore.DocumentSnapshot }): boolean {
  if (!change.after.exists) return true;
  const after = change.after.data();
  if (!after) return true;
  if (!change.before.exists) return false;

  const before = change.before.data()!;
  // Strip indexing fields before comparing — prevents infinite write loop
  // when our own set({ searchKeywords }) re-triggers this function.
  const strip = (d: Record<string, unknown>) => {
    const { searchKeywords: _k, searchIndexedAt: _i, ...rest } = d;
    return rest;
  };
  return JSON.stringify(strip(before)) === JSON.stringify(strip(after));
}

export const videoSearchIndexer = onDocumentWritten(
  'videos/{videoId}',
  async (event) => {
    if (shouldSkip(event.data!)) return;
    await indexDocument('videos', event.params.videoId, event.data?.after.data() ?? {});
  },
);

export const creatorSearchIndexer = onDocumentWritten(
  'creatorProfiles/{creatorId}',
  async (event) => {
    if (shouldSkip(event.data!)) return;
    await indexDocument('creatorProfiles', event.params.creatorId, event.data?.after.data() ?? {});
  },
);

export const liveSearchIndexer = onDocumentWritten(
  'liveSessions/{sessionId}',
  async (event) => {
    if (shouldSkip(event.data!)) return;
    await indexDocument('liveSessions', event.params.sessionId, event.data?.after.data() ?? {});
  },
);

export const businessSearchIndexer = onDocumentWritten(
  'businessAccounts/{businessId}',
  async (event) => {
    if (shouldSkip(event.data!)) return;
    await indexDocument('businessAccounts', event.params.businessId, event.data?.after.data() ?? {});
  },
);
