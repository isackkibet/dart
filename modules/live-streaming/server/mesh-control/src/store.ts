import crypto from 'node:crypto';
import type { ParticipantSnapshot, ProductionSnapshot, ProgramLayout } from '@yohpal/contracts';

type InternalProduction = ProductionSnapshot & { disconnectedAt: Map<string, number> };
const productions = new Map<string, InternalProduction>();

export function createProduction(title:string, ownerId:string): ProductionSnapshot {
  const now = new Date().toISOString();
  const p: InternalProduction = {id:crypto.randomUUID(), title, ownerId, status:'DRAFT', plan:'FREE', maxCameras:2, layout:'SINGLE', activeCameraIds:[], participants:[], createdAt:now, updatedAt:now, disconnectedAt:new Map()};
  productions.set(p.id,p); return snapshot(p);
}
export function getInternal(id:string): InternalProduction { const p=productions.get(id); if(!p) throw new Error('Production not found'); return p; }
export function getProduction(id:string): ProductionSnapshot { return snapshot(getInternal(id)); }
export function listProductions(): ProductionSnapshot[] { return [...productions.values()].map(snapshot); }
export function setStatus(id:string,status:'DRAFT'|'LIVE'|'ENDED'):ProductionSnapshot { const p=getInternal(id); p.status=status;p.updatedAt=new Date().toISOString();return snapshot(p); }
export function addOrReconnectParticipant(id:string, participant:ParticipantSnapshot):ProductionSnapshot {
  const p=getInternal(id); const existing=p.participants.find(x=>x.participantId===participant.participantId);
  if(existing){Object.assign(existing,participant,{connected:true,lastSeenAt:new Date().toISOString()});p.disconnectedAt.delete(participant.participantId);}
  else {
    if(participant.role==='DIRECTOR' && p.participants.some(x=>x.role==='DIRECTOR'&&x.connected)) throw new Error('Director already connected');
    if(participant.role==='CAMERA' && p.participants.filter(x=>x.role==='CAMERA'&&x.connected).length>=p.maxCameras) throw new Error('FREE_PLAN_CAMERA_LIMIT');
    p.participants.push(participant);
  }
  p.updatedAt=new Date().toISOString(); return snapshot(p);
}
export function disconnectParticipant(id:string,participantId:string):ProductionSnapshot { const p=getInternal(id);const x=p.participants.find(v=>v.participantId===participantId);if(x){x.connected=false;x.lastSeenAt=new Date().toISOString();p.disconnectedAt.set(participantId,Date.now());}return snapshot(p); }
export function pruneDisconnected(id:string,graceMs:number):ProductionSnapshot { const p=getInternal(id);const now=Date.now();p.participants=p.participants.filter(x=>x.connected || now-(p.disconnectedAt.get(x.participantId)??now)<=graceMs);return snapshot(p); }
export function setLayout(id:string,layout:ProgramLayout,cameraIds:string[]):ProductionSnapshot {
  const p=getInternal(id); const connected=new Set(p.participants.filter(x=>x.role==='CAMERA'&&x.connected).map(x=>x.participantId));
  if(layout==='SINGLE' && cameraIds.length!==1) throw new Error('SINGLE_REQUIRES_ONE_CAMERA');
  if(layout==='SPLIT_SCREEN' && cameraIds.length!==2) throw new Error('SPLIT_REQUIRES_TWO_CAMERAS');
  if(cameraIds.some(x=>!connected.has(x))) throw new Error('CAMERA_NOT_CONNECTED');
  p.layout=layout;p.activeCameraIds=[...cameraIds];p.updatedAt=new Date().toISOString();return snapshot(p);
}
function snapshot(p:InternalProduction):ProductionSnapshot { const {disconnectedAt:_,...safe}=p;return JSON.parse(JSON.stringify(safe)); }
