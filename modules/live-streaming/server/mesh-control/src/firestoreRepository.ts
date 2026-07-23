import crypto from 'node:crypto';
import type { Firestore } from 'firebase-admin/firestore';
import type { ProductionSnapshot } from '@yohpal/contracts';
import { clone, createSnapshot, type ProductionRepository } from './repository.js';
export class FirestoreProductionRepository implements ProductionRepository {
 constructor(private db:Firestore){}
 private ref(id:string){return this.db.collection('meshLiveProductions').doc(id);}
 async create(title:string,ownerId:string){const p=createSnapshot(crypto.randomUUID(),title,ownerId);await this.ref(p.id).set(p);return p;}
 async get(id:string){const s=await this.ref(id).get();if(!s.exists)throw new Error('PRODUCTION_NOT_FOUND');return s.data() as ProductionSnapshot;}
 async list(ownerId?:string){let q:any=this.db.collection('meshLiveProductions');if(ownerId)q=q.where('ownerId','==',ownerId);const s=await q.get();return s.docs.map((d:any)=>d.data() as ProductionSnapshot);}
 async save(p:ProductionSnapshot){await this.ref(p.id).set(clone(p),{merge:false});return p;}
 async appendAudit(productionId:string,actorId:string,event:string,details:Record<string,unknown>){await this.ref(productionId).collection('audit').doc().set({actorId,event,details,at:new Date().toISOString()});}
 async listAudit(productionId:string){const s=await this.ref(productionId).collection('audit').orderBy('at','asc').get();return s.docs.map((d:any)=>({id:d.id,...d.data()}));}
}
