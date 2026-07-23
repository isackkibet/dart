# YohPal Live Streaming Overlay — Run-to-Green Checklist & Developer Evidence Report

> **Developer:** \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_
> **Date:** \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_
> **PR/Branch:** \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_
> **Overlay version:** \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_

---

## Instructions

Run each step in order. Paste command outputs below each section. If a step fails, document the failure and do not proceed until resolved.

---

## 1. Environment check

**Command:**
```
cd modules/live-streaming
npm run doctor
```

**Output:**
```
(paste output here)
```

**Pass / Fail:** \_\_\_\_\_\_\_\_\_\_

---

## 2. Required files validation

**Command:**
```
npm run ci:required-files
```

**Output:**
```
(paste output here)
```

**Pass / Fail:** \_\_\_\_\_\_\_\_\_\_

---

## 3. Foundation overwrite check

**Command:**
```
npm run ci:no-overwrite
```

**Output:**
```
(paste output here)
```

**Pass / Fail:** \_\_\_\_\_\_\_\_\_\_

---

## 4. Local LAN IP check

**Command:**
```
npm run lan:check
```

**Output:**
```
(paste output here)
```

**LAN_IP configured:** \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_

**Pass / Fail:** \_\_\_\_\_\_\_\_\_\_

---

## 5. Docker stack status

**Command:**
```
npm run docker:ps
```

**Output:**
```
(paste output here)
```

**Expected services running:**
- [ ] yohpal-live-mediasoup
- [ ] yohpal-live-turn
- [ ] yohpal-live-nginx

**Pass / Fail:** \_\_\_\_\_\_\_\_\_\_

---

## 6. Local endpoint check

**Command:**
```
npm run endpoints:check
```

**Output:**
```
(paste output here)
```

**Endpoints verified:**
- [ ] https://<LAN_IP>/health returns 200
- [ ] https://<LAN_IP>/test-client/ loads

**Pass / Fail:** \_\_\_\_\_\_\_\_\_\_

---

## 7. Node server smoke tests

**Command:**
```
cd server/mediasoup
npm run test:smoke
```

**Output:**
```
(paste output here)
```

**Pass / Fail:** \_\_\_\_\_\_\_\_\_\_

---

## 8. Signaling contract tests

**Command:**
```
npm run test:contract
```

**Output:**
```
(paste output here)
```

**Pass / Fail:** \_\_\_\_\_\_\_\_\_\_

---

## 9. Browser test client

**URL tested:** https://<LAN_IP>/test-client/

**Validation results:**
- [ ] WSS connects successfully
- [ ] joinRoom succeeds
- [ ] routerRtpCapabilities received
- [ ] listProducers returns response
- [ ] local camera preview works

**Screenshot attached:** Yes / No

**Pass / Fail:** \_\_\_\_\_\_\_\_\_\_

**Notes (if any):**
```
(observations, issues, workarounds)
```

---

## 10. Flutter analyzer

**Command:**
```
cd <yohpal-live-flutter-project>
flutter analyze
```

**Output:**
```
(paste output here)
```

**Pass / Fail:** \_\_\_\_\_\_\_\_\_\_

---

## 11. Android device validation

**Device model:** \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_
**Android version:** \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_
**Wi-Fi network:** \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_

**Checklist:**
- [ ] Same Wi-Fi as dev machine confirmed
- [ ] Dev certificate installed and trusted
- [ ] health endpoint opens in browser
- [ ] Camera permission granted
- [ ] Microphone permission granted
- [ ] Preview visible
- [ ] WSS join succeeds
- [ ] send transport created
- [ ] Audio/video producer request sent
- [ ] Cleanup works on stream end

**Screenshots attached:** Yes / No

**Pass / Fail:** \_\_\_\_\_\_\_\_\_\_

**Notes (if any):**
```
(observations, crashes, permission issues, workarounds)
```

---

## 12. iOS device validation

**Device model:** \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_
**iOS version:** \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_
**Wi-Fi network:** \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_

**Checklist:**
- [ ] Same Wi-Fi as dev machine confirmed
- [ ] Dev certificate installed and trusted
- [ ] health endpoint opens in Safari
- [ ] Camera permission granted
- [ ] Microphone permission granted
- [ ] Preview visible
- [ ] WSS join succeeds
- [ ] Receive transport flow reaches server
- [ ] Cleanup works on stream end

**Screenshots attached:** Yes / No

**Pass / Fail:** \_\_\_\_\_\_\_\_\_\_

**Notes (if any):**
```
(observations, crashes, permission issues, workarounds)
```

---

## 13. Full CI run

**Command:**
```
npm run ci
```

**Output:**
```
(paste output here)
```

**Pass / Fail:** \_\_\_\_\_\_\_\_\_\_

---

## 14. Known failures / limitations

List any issues that remain unresolved:

| # | Issue | Severity | Workaround | Acceptable for merge? |
|---|-------|----------|------------|-----------------------|
| 1 | | | | |
| 2 | | | | |
| 3 | | | | |

---

## 15. Final merge readiness decision

- [ ] **READY FOR MERGE** — All steps passed. No known blocking issues.
- [ ] **MERGE WITH EXCEPTIONS** — All critical steps passed. Non-blocking issues documented above.
- [ ] **NOT READY** — Blocking issues remain. Do not merge.

**Developer signature:** \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_

**Reviewer signature:** \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_

**Date:** \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_
