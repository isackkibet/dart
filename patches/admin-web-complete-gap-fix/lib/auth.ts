import { cookies } from 'next/headers';
import { auth, db } from './firebaseAdmin';
export type AdminRole='owner'|'moderator'|'finance'|'advertiser'|'polls'|'support'|'viewer';
export type AdminUser={uid:string;email?:string;role:AdminRole;permissions:string[]};
export const rolePermissions:Record<AdminRole,string[]>={owner:['*'],moderator:['moderation:read','moderation:write'],finance:['finance:read','finance:approve','wallet:read'],advertiser:['ads:read','ads:write'],polls:['polls:read','polls:write'],support:['dashboard:read','moderation:read'],viewer:['dashboard:read']};
export function hasPermission(u:AdminUser,p:string){return u.permissions.includes('*')||u.permissions.includes(p)}
export async function getCurrentAdmin():Promise<AdminUser|null>{
 const c=await cookies(); const token=c.get(process.env.ADMIN_SESSION_COOKIE_NAME||'yohpal_admin_session')?.value; if(!token)return null;
 try{const decoded=await auth.verifySessionCookie(token,true); const doc=await db.collection('admins').doc(decoded.uid).get(); if(!doc.exists)return null; const d=doc.data()||{}; const role=(d.role||'viewer') as AdminRole; return {uid:decoded.uid,email:decoded.email,role,permissions:d.permissions||rolePermissions[role]||[]};}catch{return null}
}
