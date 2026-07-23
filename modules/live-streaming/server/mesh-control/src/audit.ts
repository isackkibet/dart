import crypto from 'node:crypto';
export interface AuditEntry { id:string; productionId:string; actorId:string; action:string; details:Record<string,unknown>; at:string }
const entries: AuditEntry[] = [];
export function audit(productionId:string, actorId:string, action:string, details:Record<string,unknown> = {}) {
  entries.push({id:crypto.randomUUID(), productionId, actorId, action, details, at:new Date().toISOString()});
}
export function listAudit(productionId:string) { return entries.filter(e => e.productionId === productionId); }
