import http from 'node:http';
import crypto from 'node:crypto';
import express from 'express';
import cors from 'cors';
import { Server } from 'socket.io';
import { z } from 'zod';
import { config } from './config.js';
import { signClaims, verifyClaims } from './token.js';
import { configureAuth, requireAuth, requireOwner } from './auth.js';
import { MemoryProductionRepository } from './memoryRepository.js';
import { FirestoreProductionRepository } from './firestoreRepository.js';
import { applyDisconnect, applyLayout, applyParticipant, nowIso, type ProductionRepository } from './repository.js';
import { publishProgramLayout } from './sfuProgramAdapter.js';

await configureAuth();
const repository:ProductionRepository=await createRepository();
async function createRepository():Promise<ProductionRepository>{
 if(config.PERSISTENCE_MODE==='memory')return new MemoryProductionRepository();
 const [{getApps,initializeApp},{getFirestore}]=await Promise.all([import('firebase-admin/app'),import('firebase-admin/firestore')]);
 if(!getApps().length)initializeApp({projectId:config.FIREBASE_PROJECT_ID||undefined});
 return new FirestoreProductionRepository(getFirestore());
}
const app=express();
app.disable('x-powered-by');
app.use(cors({origin:config.CORS_ORIGINS==='*'?true:config.CORS_ORIGINS.split(',').map(v=>v.trim()).filter(Boolean),credentials:true}));
app.use(express.json({limit:'256kb'}));
const buckets=new Map<string,{count:number;resetAt:number}>();
app.use((req,res,next)=>{const key=req.ip||'unknown';const now=Date.now();const b=buckets.get(key);if(!b||b.resetAt<=now){buckets.set(key,{count:1,resetAt:now+60000});return next();}if(++b.count>120)return res.status(429).json({error:'RATE_LIMITED'});next();});
const asyncRoute=(fn:any)=>(req:any,res:any,next:any)=>Promise.resolve(fn(req,res,next)).catch(next);
app.get('/health',(_req,res)=>res.json({status:'ok',service:'yohpal-mesh-live-api',version:'1.0.2',persistence:config.PERSISTENCE_MODE,auth:config.AUTH_MODE}));
app.get('/v1/productions',requireAuth,asyncRoute(async(req:any,res:any)=>res.json(await repository.list(req.auth.uid))));
app.post('/v1/productions',requireAuth,asyncRoute(async(req:any,res:any)=>{const body=z.object({title:z.string().min(3)}).parse(req.body);const p=await repository.create(body.title,req.auth.uid);await repository.appendAudit(p.id,req.auth.uid,'PRODUCTION_CREATED',{title:p.title});res.status(201).json(p);}));
app.get('/v1/productions/:id',requireAuth,asyncRoute(async(req:any,res:any)=>{const p=await repository.get(req.params.id);requireOwner(p.ownerId,req);res.json(p);}));
app.post('/v1/productions/:id/status',requireAuth,asyncRoute(async(req:any,res:any)=>{const {status}=z.object({status:z.enum(['DRAFT','LIVE','ENDED'])}).parse(req.body);const p=await repository.get(req.params.id);requireOwner(p.ownerId,req);p.status=status;p.updatedAt=nowIso();await repository.save(p);await repository.appendAudit(p.id,req.auth.uid,'STATUS_CHANGED',{status});io.to(`production:${p.id}`).emit('production-state',p);res.json(p);}));
app.post('/v1/productions/:id/pairing-token',requireAuth,asyncRoute(async(req:any,res:any)=>{const b=z.object({role:z.enum(['DIRECTOR','CAMERA','VIEWER']),label:z.string().min(1),venue:z.string().optional(),participantId:z.string().optional()}).parse(req.body);const p=await repository.get(req.params.id);requireOwner(p.ownerId,req);const participantId=b.participantId??crypto.randomUUID();const exp=Math.floor(Date.now()/1000)+config.TOKEN_TTL_SECONDS;const token=signClaims({productionId:p.id,role:b.role,participantId,label:b.label,venue:b.venue,exp});await repository.appendAudit(p.id,req.auth.uid,'PAIRING_TOKEN_ISSUED',{role:b.role,participantId});res.json({token,participantId,expiresAt:new Date(exp*1000).toISOString(),pairingUrl:`${config.PUBLIC_BASE_URL}/pair?token=${encodeURIComponent(token)}`});}));
app.post('/v1/productions/:id/layout',requireAuth,asyncRoute(async(req:any,res:any)=>{const b=z.object({layout:z.enum(['SINGLE','SPLIT_SCREEN']),cameraIds:z.array(z.string())}).parse(req.body);const current=await repository.get(req.params.id);requireOwner(current.ownerId,req);const p=applyLayout(current,b.layout,b.cameraIds);await repository.save(p);const delivery=await publishProgramLayout(p);await repository.appendAudit(p.id,req.auth.uid,'LAYOUT_CHANGED',{layout:b.layout,cameraIds:b.cameraIds,delivery});io.to(`production:${p.id}`).emit('program-layout',p);res.json({...p,programDelivery:delivery});}));
app.get('/v1/productions/:id/audit',requireAuth,asyncRoute(async(req:any,res:any)=>{const p=await repository.get(req.params.id);requireOwner(p.ownerId,req);res.json(await repository.listAudit(p.id));}));
app.get('/v1/config/webrtc',(_req,res)=>res.json({iceServers:JSON.parse(process.env.ICE_SERVERS_JSON??'[{"urls":["stun:stun.l.google.com:19302"]}]'),sfuConfigured:Boolean(config.SFU_CONTROL_URL)}));

const server=http.createServer(app);const io=new Server(server,{cors:{origin:true,credentials:true},transports:['websocket','polling']});
io.use((socket,next)=>{try{const token=String(socket.handshake.auth.token??'');socket.data.claims=verifyClaims(token);next();}catch(e){next(new Error((e as Error).message));}});
io.on('connection',async(socket)=>{const c=socket.data.claims as ReturnType<typeof verifyClaims>;try{const current=await repository.get(c.productionId);const p=applyParticipant(current,{participantId:c.participantId,role:c.role,label:c.label,venue:c.venue,connected:true,lastSeenAt:nowIso()});await repository.save(p);socket.join(`production:${c.productionId}`);socket.join(`participant:${c.participantId}`);await repository.appendAudit(c.productionId,c.participantId,'PARTICIPANT_CONNECTED',{role:c.role});io.to(`production:${c.productionId}`).emit('production-state',p);if(c.role==='VIEWER')socket.emit('program-layout',p);}catch(e){socket.emit('fatal-error',{code:(e as Error).message});socket.disconnect(true);return;}
 socket.on('signal',(raw:any)=>{const parsed=z.object({productionId:z.string(),fromParticipantId:z.string(),toParticipantId:z.string(),type:z.enum(['offer','answer','ice']),payload:z.unknown()}).safeParse(raw);if(!parsed.success)return socket.emit('signal-error',{error:'INVALID_SIGNAL'});const msg=parsed.data;if(msg.productionId!==c.productionId||msg.fromParticipantId!==c.participantId)return socket.emit('signal-error',{error:'SIGNAL_SCOPE_MISMATCH'});io.to(`participant:${msg.toParticipantId}`).emit('signal',msg);});
 socket.on('telemetry',(raw:any)=>{const parsed=z.object({battery:z.number().min(0).max(100).optional(),network:z.string().max(32).optional(),bitrateKbps:z.number().nonnegative().max(100000).optional()}).safeParse(raw);if(parsed.success)io.to(`production:${c.productionId}`).emit('participant-telemetry',{participantId:c.participantId,...parsed.data,at:nowIso()});});
 socket.on('director-command',async(payload:any)=>{if(c.role!=='DIRECTOR')return;io.to(`production:${c.productionId}`).emit('director-command',{...payload,actorId:c.participantId});await repository.appendAudit(c.productionId,c.participantId,'DIRECTOR_COMMAND',payload??{});});
 socket.on('disconnect',async()=>{try{const current=await repository.get(c.productionId);const p=applyDisconnect(current,c.participantId);await repository.save(p);await repository.appendAudit(c.productionId,c.participantId,'PARTICIPANT_DISCONNECTED',{});io.to(`production:${c.productionId}`).emit('production-state',p);}catch{}});
});
app.use((err:any,_req:any,res:any,_next:any)=>{const message=err?.message??'INTERNAL_ERROR';const status=message==='FORBIDDEN'?403:message==='PRODUCTION_NOT_FOUND'?404:400;res.status(status).json({error:message});});
server.listen(config.PORT,()=>console.log(JSON.stringify({event:'server_started',port:config.PORT,version:'1.0.2'})));
