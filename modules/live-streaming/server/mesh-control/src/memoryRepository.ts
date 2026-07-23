import crypto from 'node:crypto';
import type { ProductionSnapshot } from '@yohpal/contracts';
import { clone, createSnapshot, type ProductionRepository } from './repository.js';
export class MemoryProductionRepository implements ProductionRepository {
 private productions=new Map<string,ProductionSnapshot>(); private audits=new Map<string,unknown[]>();
 async create(title:string,ownerId:string){const p=createSnapshot(crypto.randomUUID(),title,ownerId);this.productions.set(p.id,p);return clone(p);}
 async get(id:string){const p=this.productions.get(id);if(!p)throw new Error('PRODUCTION_NOT_FOUND');return clone(p);}
 async list(ownerId?:string){return [...this.productions.values()].filter(x=>!ownerId||x.ownerId===ownerId).map(clone);}
 async save(p:ProductionSnapshot){this.productions.set(p.id,clone(p));return clone(p);}
 async appendAudit(productionId:string,actorId:string,event:string,details:Record<string,unknown>){const list=this.audits.get(productionId)??[];list.push({id:crypto.randomUUID(),productionId,actorId,event,details,at:new Date().toISOString()});this.audits.set(productionId,list);}
 async listAudit(productionId:string){return clone(this.audits.get(productionId)??[]);}
}
