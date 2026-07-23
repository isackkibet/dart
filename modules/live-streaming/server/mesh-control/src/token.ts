import crypto from 'node:crypto';
import type { PairingClaims } from '@yohpal/contracts';
import { config } from './config.js';
const b64 = (value: string | Buffer) => Buffer.from(value).toString('base64url');
export function signClaims(claims: PairingClaims): string {
  const payload = b64(JSON.stringify(claims));
  const signature = crypto.createHmac('sha256', config.PAIRING_SECRET).update(payload).digest('base64url');
  return `${payload}.${signature}`;
}
export function verifyClaims(token: string): PairingClaims {
  const [payload, signature] = token.split('.');
  if (!payload || !signature) throw new Error('Malformed token');
  const expected = crypto.createHmac('sha256', config.PAIRING_SECRET).update(payload).digest();
  const actual = Buffer.from(signature, 'base64url');
  if (expected.length !== actual.length || !crypto.timingSafeEqual(expected, actual)) throw new Error('Invalid token');
  const claims = JSON.parse(Buffer.from(payload, 'base64url').toString('utf8')) as PairingClaims;
  if (claims.exp <= Math.floor(Date.now() / 1000)) throw new Error('Expired token');
  return claims;
}
