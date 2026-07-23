import { NextRequest, NextResponse } from 'next/server';
import { resolveModerationReport } from '@/lib/repositories/moderationRepository';
export async function GET(_:NextRequest,context:{params:Promise<{id:string}>}){const {id}=await context.params;await resolveModerationReport({reportId:id,action:'hide',actorUserId:'admin-placeholder'});return NextResponse.json({ok:true,reportId:id,action:'hide'})}
