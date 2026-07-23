import { db, FieldValue } from '../firebaseAdmin';
import { paginateQuery } from '../pagination';
export type ModerationReport={id:string;targetType?:string;targetId?:string;reason?:string;status?:string;reporterUserId?:string};
export async function getModerationReports(cursor?: string) {
  return paginateQuery(
    db.collection('moderationReports').where('status', '==', 'open'),
    cursor,
  );
}
export async function resolveModerationReport({reportId,action,actorUserId}:{reportId:string;action:'hide'|'approve'|'reject';actorUserId:string}){const r=db.collection('moderationReports').doc(reportId), a=db.collection('moderationAuditLogs').doc();await db.runTransaction(async tx=>{const rd=await tx.get(r); const data=rd.data()||{}; tx.update(r,{status:action==='hide'?'hidden':'closed',action,reviewedBy:actorUserId,reviewedAt:FieldValue.serverTimestamp()}); if(action==='hide'&&data.targetType==='video'&&data.targetId){tx.update(db.collection('videos').doc(data.targetId),{visibility:'hidden',hiddenBy:actorUserId,hiddenAt:FieldValue.serverTimestamp()})} tx.set(a,{reportId,targetType:data.targetType||'',targetId:data.targetId||'',action,actorUserId,createdAt:FieldValue.serverTimestamp()})});return{ok:true}}
