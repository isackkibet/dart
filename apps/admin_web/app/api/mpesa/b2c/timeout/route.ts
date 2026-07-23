import { NextRequest, NextResponse } from 'next/server';
import { db, FieldValue } from '@/lib/firebaseAdmin';

export async function POST(request: NextRequest) {
  const body = await request.json();
  await db.collection('mpesaB2CTimeouts').add({
    raw: body,
    createdAt: FieldValue.serverTimestamp(),
  });
  return NextResponse.json({ ok: true });
}
