#!/usr/bin/env bash
set -e
test -f tsconfig.json
test -f app/layout.tsx
test -f "app/(admin)/dashboard/page.tsx"
test -f "app/(admin)/finance/page.tsx"
test -f "app/(admin)/finance/payouts/page.tsx"
test -f "app/(admin)/advertiser/page.tsx"
test -f "app/(admin)/polls/page.tsx"
test -f "app/(admin)/moderation/page.tsx"
test -f lib/firebaseAdmin.ts
test -f lib/auth.ts
echo "Admin Web complete gap-fix structure OK."
