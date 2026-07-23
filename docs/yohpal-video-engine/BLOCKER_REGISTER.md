# YohPal Video Engine — Blocker Register

**Version:** V12  
**Last Updated:** 2026-07-07  
**Rule:** All Critical blockers must be CLOSED before GO decision is signed.

---

## Active Blockers

| ID | Blocker | Severity | Owner | Required Fix | Status |
|---|---|---|---|---|---|
| YVE-B001 | Android certification session not submitted | Critical | Developer | Run 30-minute Android test; submit session to `/video-performance/metrics`; confirm `certifiedForControlledRelease: true` | 🔴 Open |
| YVE-B002 | iOS certification session not submitted | Critical | Developer | Run 30-minute iOS test on physical device; submit session; confirm certification | 🔴 Open |
| YVE-B003 | No-CDN playback not proven | Critical | Backend / Flutter | Confirm origin provider returns signed URLs; confirm Flutter plays without CDN env vars set | 🔴 Open |
| YVE-B004 | 30-minute stability not proven on either platform | Critical | QA | Run a continuous 30-minute feed scroll on Android and iOS; report `thirtyMinuteStabilityPassed: true` | 🔴 Open |
| YVE-B005 | Release approval missing | Critical | Product / Admin | Fill and sign `GO_NO_GO_DECISION_FORM.md`; populate `approverName` and `approverRole` in the `YohPalVideoReleaseLock` | 🔴 Open |
| YVE-B006 | HLS master manifest not verified | High | Backend | Confirm `master.m3u8` is generated after transcode and is a valid HLS playlist | 🔴 Open |
| YVE-B007 | Telemetry ingestion not end-to-end proven | High | Backend / Flutter | Confirm events flow from Flutter → `/video-telemetry/events` → aggregate → ranking score update | 🔴 Open |
| YVE-B008 | iOS auth error on simulator (stale Keychain) | Medium | Developer | Uninstall app from simulator; re-test login; report error code from `[${e.code}]` prefix added to auth error message | 🟡 Under Investigation |
| YVE-B009 | Rollout percentage not set | Critical | Product | Set `rolloutPercentage` to 1 (Stage 1 — internal users) in the release lock before any rollout | 🔴 Open |
| YVE-B010 | Kill switch default state not confirmed | High | DevOps | Confirm `YohPalVideoKillSwitchService.isEnabled()` returns `false` at cold start; confirm enable/disable cycle works | 🔴 Open |

---

## Closed Blockers

| ID | Blocker | Resolution | Closed Date |
|---|---|---|---|
| — | — | — | — |

---

## Severity Definitions

| Severity | Definition |
|---|---|
| Critical | Blocks GO decision entirely. Must be closed before any rollout. |
| High | Must be closed before Stage 3+ rollout (≥ 10% users). |
| Medium | Must be closed before full release (100%). |
| Low | Tracked but does not block rollout stages. |

---

## Blocker Lifecycle

```
OPEN → UNDER INVESTIGATION → RESOLVED → CLOSED
                           ↓
                        REJECTED (evidence not accepted)
```

A blocker is CLOSED only when the reviewer has accepted the submitted evidence and updated this register.
