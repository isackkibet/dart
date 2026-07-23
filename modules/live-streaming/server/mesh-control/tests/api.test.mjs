import test from 'node:test';import assert from 'node:assert/strict';import {spawn} from 'node:child_process';
const port=18080;let child;const auth={'content-type':'application/json','authorization':'Bearer owner-1'};
async function wait(){for(let i=0;i<80;i++){try{const r=await fetch(`http://127.0.0.1:${port}/health`);if(r.ok)return;}catch{}await new Promise(r=>setTimeout(r,100));}throw new Error('server did not start');}
test.before(async()=>{child=spawn('node',['dist/server.js'],{env:{...process.env,PORT:String(port),AUTH_MODE:'test',PERSISTENCE_MODE:'memory',SFU_CONTROL_URL:'',PAIRING_SECRET:'test-secret-that-is-longer-than-thirty-two-characters'},stdio:['ignore','pipe','pipe']});await wait();});
test.after(()=>child?.kill('SIGTERM'));
test('requires authentication',async()=>{const r=await fetch(`http://127.0.0.1:${port}/v1/productions`);assert.equal(r.status,401);});
test('canonical owner lifecycle and audit',async()=>{let r=await fetch(`http://127.0.0.1:${port}/v1/productions`,{method:'POST',headers:auth,body:JSON.stringify({title:'Campus Live'})});assert.equal(r.status,201);const p=await r.json();assert.equal(p.ownerId,'owner-1');assert.equal(p.maxCameras,2);
for(const role of ['DIRECTOR','CAMERA','CAMERA']){r=await fetch(`http://127.0.0.1:${port}/v1/productions/${p.id}/pairing-token`,{method:'POST',headers:auth,body:JSON.stringify({role,label:role})});assert.equal(r.status,200);assert.ok((await r.json()).token.includes('.'));}
r=await fetch(`http://127.0.0.1:${port}/v1/productions/${p.id}/status`,{method:'POST',headers:auth,body:JSON.stringify({status:'LIVE'})});assert.equal(r.status,200);assert.equal((await r.json()).status,'LIVE');
r=await fetch(`http://127.0.0.1:${port}/v1/productions/${p.id}/audit`,{headers:auth});assert.equal(r.status,200);assert.ok((await r.json()).length>=5);});
test('owner boundary is enforced',async()=>{let r=await fetch(`http://127.0.0.1:${port}/v1/productions`,{method:'POST',headers:auth,body:JSON.stringify({title:'Private Live'})});const p=await r.json();r=await fetch(`http://127.0.0.1:${port}/v1/productions/${p.id}`,{headers:{authorization:'Bearer owner-2'}});assert.equal(r.status,403);});
