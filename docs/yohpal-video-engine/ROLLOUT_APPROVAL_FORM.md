# YohPal Video Engine — Rollout Approval Form

**Version:** V12  
**Service:** `services/release-control/` — `POST /video-release/evaluate`  
**Rule:** Rollout percentage must be set explicitly. Default is 0. There is no automatic progression between stages.

---

## Controlled Rollout Stages

| Stage | Label | Percentage | Audience | Gate Requirement |
|---|---|---|---|---|
| 1 | Internal users | 1% | Engineering team, QA, founders | All critical blockers closed |
| 2 | Pilot users | 5% | Selected beta testers | Stage 1 stable for 48 hours |
| 3 | Creators | 10% | Verified YohPal creators | Stage 2 stable for 72 hours, no regressions |
| 4 | General (25%) | 25% | General user base | Stage 3 stable for 1 week |
| 5 | General (50%) | 50% | General user base | No increase in error rate at Stage 4 |
| 6 | Full release | 100% | All users | Performance gates still passing at 50% |

---

## Stage 1 Approval (Required before any rollout)

**Current Stage:** Pre-launch  
**Target Stage:** Stage 1 — 1% Internal  

### Certification Sessions Required

| Session | Session ID | Certified | Confirmed By |
|---|---|---|---|
| Android 30-minute | | ⬜ | |
| iOS 30-minute | | ⬜ | |
| No-CDN playback | | ⬜ | |

### Gate Results

| Gate | Result | Pass/Fail |
|---|---|---|
| P95 startup ≤ 1,500 ms | TBD | ⬜ |
| Avg buffering ≤ 1,000 ms | TBD | ⬜ |
| Scroll FPS ≥ 55 | TBD | ⬜ |
| Memory ≤ 700 MB | TBD | ⬜ |
| Error rate ≤ 2% | TBD | ⬜ |
| 30-min stability | TBD | ⬜ |

### Release Lock Configuration

```json
{
  "releaseId": "",
  "version": "",
  "certificationSessionId": "",
  "androidPassed": false,
  "iosPassed": false,
  "noCdnPassed": false,
  "startupPassed": false,
  "bufferingPassed": false,
  "memoryPassed": false,
  "cachePassed": false,
  "stabilityPassed": false,
  "approverName": "",
  "approverRole": "",
  "approvedAt": "",
  "rolloutPercentage": 1,
  "killSwitchEnabled": false,
  "status": "LOCKED"
}
```

### Stage 1 Sign-Off

| Role | Name | Approved | Date |
|---|---|---|---|
| Lead Developer | | ⬜ | |
| Release Approver | | ⬜ | |

---

## Stage Progression Log

| Date | Stage From | Stage To | Approved By | Notes |
|---|---|---|---|---|
| — | — | — | — | — |

---

## Kill Switch Record

The kill switch can be activated at any time via `POST /video-release/kill-switch/enable` with a reason.

| Date | Action | Reason | Activated By |
|---|---|---|---|
| — | — | — | — |

---

## Rollout Eligibility Check

Use this endpoint to verify a specific user's eligibility at the current rollout percentage:

```bash
curl -X POST http://localhost:3002/video-release/eligible/{userId} \
  -H "Content-Type: application/json" \
  -d '{ "lock": { ... } }'
```

Expected response (eligible):
```json
{ "userId": "abc123", "eligible": true, "blockers": [] }
```

Expected response (blocked):
```json
{ "userId": "xyz789", "eligible": false, "blockers": ["Kill switch is enabled"] }
```
