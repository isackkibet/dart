import test from 'node:test';import assert from 'node:assert/strict';import {spawn} from 'node:child_process';
const port=18080;let child;
async function wait(){for(let i=0;i<60;i++){try{const r=await fetch(`http://127.0.0.1:${port}/health`);if(r.ok)return;}catch{}await new Promise(r=>setTimeout(r,100));}throw new Error('server did not start');}
test.before(async()=>{child=spawn('node',['apps/api/dist/server.js'],{env:{...process.env,PORT:String(port),PAIRING_SECRET:'test-secret-that-is-longer-than-thirty-two-characters'},stdio:'ignore'});await wait();});
test.after(()=>child?.kill('SIGTERM'));
test('health and free production lifecycle',async()=>{let r=await fetch(`http://127.0.0.1:${port}/health`);assert.equal(r.status,200);
r=await fetch(`http://127.0.0.1:${port}/v1/productions`,{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({title:'Campus Live',ownerId:'owner-1'})});assert.equal(r.status,201);const p=await r.json();assert.equal(p.maxCameras,2);assert.equal(p.plan,'FREE');
for(const role of ['DIRECTOR','CAMERA','CAMERA']){r=await fetch(`http://127.0.0.1:${port}/v1/productions/${p.id}/pairing-token`,{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({role,label:role,actorId:'owner-1'})});assert.equal(r.status,200);const t=await r.json();assert.ok(t.token.includes('.'));}
r=await fetch(`http://127.0.0.1:${port}/v1/productions/${p.id}/status`,{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({status:'LIVE',actorId:'owner-1'})});assert.equal(r.status,200);assert.equal((await r.json()).status,'LIVE');
r=await fetch(`http://127.0.0.1:${port}/v1/productions/${p.id}/audit`);const audit=await r.json();assert.ok(audit.length>=5);});
