import { NextRequest, NextResponse } from 'next/server';
import { updatePayoutStatus } from '@/lib/repositories/financeRepository';
export async function GET(_:NextRequest,context:{params:Promise<{id:string}>}){const {id}=await context.params;await updatePayoutStatus({payoutId:id,status:'held',actorUserId:'admin-placeholder',reason:'Held for manual review from admin web'});return NextResponse.json({ok:true,payoutId:id,status:'held'})}
