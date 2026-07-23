import { NextRequest, NextResponse } from 'next/server';
import { db, FieldValue } from '@/lib/firebaseAdmin';

export async function POST(request: NextRequest) {
  const body = await request.json();
  const result = body.Result || {};
  const conversationId = result.ConversationID;
  const resultCode = Number(result.ResultCode);

  const payoutSnap = await db
    .collection('walletPayouts')
    .where('mpesaConversationId', '==', conversationId)
    .limit(1)
    .get();

  if (!payoutSnap.empty) {
    await payoutSnap.docs[0].ref.update({
      status: resultCode === 0 ? 'paid' : 'disbursement_failed',
      mpesaResultCode: resultCode,
      mpesaResultDescription: result.ResultDesc || '',
      mpesaRawResult: body,
      ...(resultCode === 0 ? { paidAt: FieldValue.serverTimestamp() } : {}),
      updatedAt: FieldValue.serverTimestamp(),
    });
  }

  await db.collection('mpesaB2CResults').add({
    conversationId,
    resultCode,
    raw: body,
    createdAt: FieldValue.serverTimestamp(),
  });

  return NextResponse.json({ ok: true });
}
