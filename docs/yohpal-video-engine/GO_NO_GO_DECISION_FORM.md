# YohPal Video Engine — Production GO / NO-GO Decision Form

**Version:** V12  
**Rule:** This form must be completed and all sign-offs obtained before `rolloutPercentage` is set above 0.

---

## Release Information

| Field | Value |
|---|---|
| Release Version | |
| Git Branch | |
| Commit Hash | |
| Certification Session ID (Android) | |
| Certification Session ID (iOS) | |
| Release Date | |
| Service Port (video-pipeline) | 3000 |
| Service Port (video-intelligence) | 3001 |
| Service Port (release-control) | 3002 |

---

## Certification Decision

Select one:

- [ ] **GO** — Approved for controlled rollout at Stage 1 (1% internal users)
- [ ] **NO-GO** — Blocked from release. Blockers must be resolved before re-submission.
- [ ] **CONDITIONAL GO** — Approved only for internal engineering users (0.1% equivalent). Public rollout remains blocked until all critical blockers are closed.

---

## Certification Gate Summary

| Gate | Android Result | Android | iOS Result | iOS |
|---|---|---|---|---|
| P95 startup ≤ 1,500 ms | TBD | ⬜ | TBD | ⬜ |
| Avg buffering ≤ 1,000 ms | TBD | ⬜ | TBD | ⬜ |
| Scroll FPS ≥ 55 | TBD | ⬜ | TBD | ⬜ |
| Memory ≤ 700 MB | TBD | ⬜ | TBD | ⬜ |
| Error rate ≤ 2% | TBD | ⬜ | TBD | ⬜ |
| 30-minute stability | TBD | ⬜ | TBD | ⬜ |
| No-CDN playback | TBD | ⬜ | TBD | ⬜ |
| Kill switch OFF | TBD | ⬜ | N/A | — |

---

## Blocker Status

All blockers from `BLOCKER_REGISTER.md` must be listed here with their current status.

| Blocker ID | Description | Severity | Status |
|---|---|---|---|
| YVE-B001 | Android certification missing | Critical | 🔴 Open |
| YVE-B002 | iOS certification missing | Critical | 🔴 Open |
| YVE-B003 | No-CDN playback not proven | Critical | 🔴 Open |
| YVE-B004 | 30-minute stability not proven | Critical | 🔴 Open |
| YVE-B005 | Release approval missing | Critical | 🔴 Open |
| YVE-B009 | Rollout percentage not set | Critical | 🔴 Open |

---

## Required Sign-Off

All four roles must sign before a GO decision takes effect.

| Role | Name | Decision | Date |
|---|---|---|---|
| Lead Developer | | ⬜ GO / ⬜ NO-GO | |
| QA Lead | | ⬜ GO / ⬜ NO-GO | |
| Product Owner | | ⬜ GO / ⬜ NO-GO | |
| Release Approver | | ⬜ GO / ⬜ NO-GO | |

---

## Rollout Percentage Authorised

Select one stage. No user receives YohPal Live above this percentage until the next sign-off cycle.

- [ ] **Stage 1 — 1%** Internal users only
- [ ] **Stage 2 — 5%** Pilot users
- [ ] **Stage 3 — 10%** Creators
- [ ] **Stage 4 — 25%** General users
- [ ] **Stage 5 — 50%** General users
- [ ] **Stage 6 — 100%** Full release

---

## Final Decision Notes

```
Decision:
Authorised rollout percentage:
Date effective:
Notes:


```

---

## Re-submission

If this form is returned as NO-GO, re-submission requires:
1. All Critical blockers resolved and evidence accepted in `BLOCKER_REGISTER.md`.
2. New certification session IDs (re-run, not reused).
3. All four sign-offs obtained again.
