import type { NextFunction, Request, Response } from 'express';
import { config } from './config.js';
export type AuthUser={uid:string;claims:Record<string,unknown>};
declare global { namespace Express { interface Request { auth?:AuthUser } } }
let verifier:((token:string)=>Promise<AuthUser>)|null=null;
export async function configureAuth(){
 if(config.AUTH_MODE==='test'){verifier=async token=>({uid:token||'test-owner',claims:{admin:true}});return;}
 const [{getApps,initializeApp},{getAuth}]=await Promise.all([import('firebase-admin/app'),import('firebase-admin/auth')]);
 if(!getApps().length)initializeApp();
 verifier=async token=>{const decoded=await getAuth().verifyIdToken(token,true);return{uid:decoded.uid,claims:decoded as Record<string,unknown>};};
}
export async function requireAuth(req:Request,res:Response,next:NextFunction){try{const raw=req.header('authorization')??'';const token=raw.startsWith('Bearer ')?raw.slice(7):'';if(!token||!verifier)return res.status(401).json({error:'UNAUTHENTICATED'});req.auth=await verifier(token);next();}catch{return res.status(401).json({error:'INVALID_ID_TOKEN'});}}
export function requireOwner(ownerId:string|undefined,req:Request){if(!req.auth||!ownerId||req.auth.uid!==ownerId)throw new Error('FORBIDDEN');}
