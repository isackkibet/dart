const nodeEnv = process.env.NODE_ENV ?? 'development';
function requiredSecret(name:string, fallbackForTest?:string):string {
  const value=process.env[name] ?? (nodeEnv==='test'?fallbackForTest:undefined);
  if(!value || value.length<32) throw new Error(`${name}_MUST_BE_AT_LEAST_32_CHARACTERS`);
  return value;
}
export const config={
 NODE_ENV:nodeEnv,
 PORT:Number(process.env.PORT??8080),
 CORS_ORIGINS:process.env.CORS_ORIGINS??(nodeEnv==='production'?'':'*'),
 PUBLIC_BASE_URL:process.env.PUBLIC_BASE_URL??'http://localhost:8080',
 PAIRING_SECRET:requiredSecret('PAIRING_SECRET','test-pairing-secret-012345678901234567890123'),
 TOKEN_TTL_SECONDS:Number(process.env.TOKEN_TTL_SECONDS??600),
 RECONNECT_GRACE_SECONDS:Number(process.env.RECONNECT_GRACE_SECONDS??30),
 AUTH_MODE:process.env.AUTH_MODE??'firebase',
 PERSISTENCE_MODE:process.env.PERSISTENCE_MODE??'firestore',
 FIREBASE_PROJECT_ID:process.env.FIREBASE_PROJECT_ID??'',
 SFU_CONTROL_URL:process.env.SFU_CONTROL_URL??'http://mediasoup:3000',
 SFU_CONTROL_TOKEN:requiredSecret('SFU_CONTROL_TOKEN','test-sfu-control-token-012345678901234567890'),
};
if(config.NODE_ENV==='production' && (!config.CORS_ORIGINS || config.CORS_ORIGINS==='*')) throw new Error('CORS_ORIGINS_REQUIRED_IN_PRODUCTION');
