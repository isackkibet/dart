# Root Repository Integration

1. Import `packages/contracts` into the root shared-contracts package.
2. Merge `apps/api/src` into the canonical API gateway / mesh-session / signaling service ownership boundaries.
3. Replace in-memory production and audit stores with the root Prisma repositories and event bus.
4. Replace local owner identity with root JWT/SSO claims.
5. Configure root TURN credentials and the YohPal Live SFU/WHIP ingest adapter.
6. Import the Flutter feature folders into `apps/mobile_flutter` and route them through canonical authentication and navigation.
7. Run root migrations, typecheck, tests, security scans and physical-device certification.

No database migration is included because the canonical root schema was not supplied with this request.
