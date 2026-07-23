# Admin Web Run-to-Green

Run:

```bash
npm install
npm run typecheck
npm run lint
npm run build
npm run dev
```

Manual checks:
- `/dashboard` opens
- `/finance` opens
- `/finance/payouts` opens
- `/advertiser` opens
- `/polls` opens
- `/moderation` opens
- Firestore metrics load or safely fallback to 0
- Moderation queue reads `moderationReports`
- Payout queue reads `walletPayouts`

Production hardening:
1. Replace placeholder action actor with `requireAdmin()`.
2. Change GET actions to POST server actions.
3. Complete Firebase Auth session cookie login.
4. Add e2e tests.
