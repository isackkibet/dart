# YohPal Live v2 Developer Execution Manual

## 1. No-conflict rule
Do not patch random legacy files. Build module by module using this pack as the source of truth.

## 2. Execution order
1. Firebase setup and rules.
2. Flutter core app shell.
3. Video feed foundation.
4. Upload + Cloud Run transcoding.
5. Creator profiles.
6. Engagement events.
7. AI creator studio.
8. Live streaming.
9. Multistreaming.
10. Contacts growth.
11. Affiliate engine.
12. Monetisation + wallet web.
13. Poll overlays.
14. Ads engine.
15. Chat integration.
16. Search.
17. Admin dashboards.

## 3. Run-to-green
Run:

```bash
bash scripts/setup_local.sh
bash scripts/run_to_green.sh
```

## 4. MVP acceptance
- First video plays fast.
- Broken videos are hidden.
- Likes/comments/bookmarks work.
- Creator profile stats update.
- AI jobs process.
- Live stream can start.
- Wallet opens on web.
- Affiliate attribution records.
- Poll votes are idempotent.
- Ads record impressions.
- Chat opens from creator profile/live.
- Search returns videos and creators.
