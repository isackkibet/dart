import { config } from './config.js';
import type { ProductionSnapshot } from '@yohpal/contracts';
export async function publishProgramLayout(p:ProductionSnapshot){
 if(!config.SFU_CONTROL_URL)return {delivered:false,reason:'SFU_CONTROL_URL_NOT_CONFIGURED'};
 const response=await fetch(`${config.SFU_CONTROL_URL}/internal/v1/rooms/${encodeURIComponent(p.id)}/program`,{method:'PUT',headers:{'content-type':'application/json','x-internal-token':config.SFU_CONTROL_TOKEN},body:JSON.stringify({layout:p.layout,activeCameraIds:p.activeCameraIds,updatedAt:p.updatedAt})});
 if(!response.ok)throw new Error(`SFU_PROGRAM_UPDATE_FAILED_${response.status}`);
 return {delivered:true};
}
