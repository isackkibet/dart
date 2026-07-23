import type { ParticipantSnapshot, ProductionSnapshot, ProgramLayout } from '@yohpal/contracts';

export interface ProductionRepository {
  create(title:string, ownerId:string): Promise<ProductionSnapshot>;
  get(id:string): Promise<ProductionSnapshot>;
  list(ownerId?:string): Promise<ProductionSnapshot[]>;
  save(production:ProductionSnapshot): Promise<ProductionSnapshot>;
  appendAudit(productionId:string, actorId:string, event:string, details:Record<string,unknown>): Promise<void>;
  listAudit(productionId:string): Promise<unknown[]>;
}

export type MutableProduction = ProductionSnapshot;
export function nowIso(){return new Date().toISOString();}
export function clone<T>(value:T):T{return JSON.parse(JSON.stringify(value));}
export function createSnapshot(id:string,title:string,ownerId:string):ProductionSnapshot {
  const now=nowIso();
  return {id,title,ownerId,status:'DRAFT',plan:'FREE',maxCameras:2,layout:'SINGLE',activeCameraIds:[],participants:[],createdAt:now,updatedAt:now};
}
export function applyParticipant(p:ProductionSnapshot, participant:ParticipantSnapshot):ProductionSnapshot {
  const next=clone(p); const existing=next.participants.find(x=>x.participantId===participant.participantId);
  if(existing) Object.assign(existing,participant,{connected:true,lastSeenAt:nowIso()});
  else {
    if(participant.role==='DIRECTOR'&&next.participants.some(x=>x.role==='DIRECTOR'&&x.connected)) throw new Error('DIRECTOR_ALREADY_CONNECTED');
    if(participant.role==='CAMERA'&&next.participants.filter(x=>x.role==='CAMERA'&&x.connected).length>=next.maxCameras) throw new Error('FREE_PLAN_CAMERA_LIMIT');
    next.participants.push(participant);
  }
  next.updatedAt=nowIso(); return next;
}
export function applyDisconnect(p:ProductionSnapshot, participantId:string):ProductionSnapshot {
  const next=clone(p); const x=next.participants.find(v=>v.participantId===participantId); if(x){x.connected=false;x.lastSeenAt=nowIso();} next.updatedAt=nowIso(); return next;
}
export function applyLayout(p:ProductionSnapshot,layout:ProgramLayout,cameraIds:string[]):ProductionSnapshot {
  const next=clone(p); const connected=new Set(next.participants.filter(x=>x.role==='CAMERA'&&x.connected).map(x=>x.participantId));
  if(layout==='SINGLE'&&cameraIds.length!==1) throw new Error('SINGLE_REQUIRES_ONE_CAMERA');
  if(layout==='SPLIT_SCREEN'&&cameraIds.length!==2) throw new Error('SPLIT_REQUIRES_TWO_CAMERAS');
  if(cameraIds.some(x=>!connected.has(x))) throw new Error('CAMERA_NOT_CONNECTED');
  next.layout=layout;next.activeCameraIds=[...cameraIds];next.updatedAt=nowIso();return next;
}
