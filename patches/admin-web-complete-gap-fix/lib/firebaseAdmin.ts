import * as admin from 'firebase-admin';
function key(){ return process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g,'\n'); }
if(!admin.apps.length){
 const projectId=process.env.FIREBASE_PROJECT_ID, clientEmail=process.env.FIREBASE_CLIENT_EMAIL, privateKey=key();
 if(projectId&&clientEmail&&privateKey) admin.initializeApp({credential:admin.credential.cert({projectId,clientEmail,privateKey})});
 else admin.initializeApp();
}
export const db=admin.firestore();
export const auth=admin.auth();
export const FieldValue=admin.firestore.FieldValue;
