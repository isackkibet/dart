# YohPal Video Engine — Developer Evidence Template

**Instructions:** Complete every numbered item. Paste terminal output, API responses, or screenshots as directed. Partial submissions will not be accepted. Submit to the release approver alongside the completed `GO_NO_GO_DECISION_FORM.md`.

---

## Identity

**Developer Name:**  
**Date Submitted:**  
**Git Branch:**  
**Commit Hash:**  

---

## 1. Git Branch

```
Branch name:
```

## 2. Commit Hash

```
Full commit hash:
Last commit message:
```

## 3. Flutter Test Output

```
Paste full output of: flutter test
```

Pass/fail summary:

## 4. Backend Test Output

Paste for each service:

**video-pipeline:**
```

```

**video-intelligence:**
```

```

**release-control:**
```

```

## 5. Android Playback Proof

Paste screenshot filename or describe:

- Device model:
- Android version:
- Network type (WiFi / 4G / 3G):
- Video loaded: ✅ / ❌
- Audio playing: ✅ / ❌

## 6. iOS Playback Proof

- Device model:
- iOS version:
- Network type:
- Video loaded: ✅ / ❌
- Audio playing: ✅ / ❌

## 7. 360p / 480p / 720p Transcode Proof

Paste output of `ls -lh` on the transcode output directory:

```

```

Confirm each file has the faststart atom at the start (run `ffprobe` or `mp4info`):

```

```

## 8. Faststart MP4 Proof

```bash
# Command used:
ffprobe -v quiet -show_entries format_tags=major_brand -of default=noprint_wrappers=1 <path>
# Output:
```

## 9. HLS Manifest Proof

Paste the contents of `master.m3u8`:

```m3u8

```

Paste contents of `360p/index.m3u8`:

```m3u8

```

## 10. Origin Fallback Proof

```bash
# Feed API response with no CDN env vars set:
curl http://localhost:3000/feed
# Response (paste):
```

Confirm `provider: "origin"` in signed URL response.

## 11. CDN Abstraction Proof

```bash
# With CLOUDFLARE_CDN_DOMAIN set:
CLOUDFLARE_CDN_DOMAIN=cdn.example.com node -e "..."
# Output:
```

Confirm URL begins with `https://cdn.example.com/`.

## 12. Smart Feed API Sample

```json
// Paste one full YohPalFeedVideoResponse object from GET /feed:
```

Confirm the following fields are present:
- `hlsReady` ✅ / ❌
- `recommendedDelivery` ✅ / ❌
- `preloadPriority` ✅ / ❌
- `predictedWatchProbability` ✅ / ❌

## 13. Telemetry Ingestion Proof

```bash
# POST /video-telemetry/events response:
```

Expected: `{ "accepted": N }`

## 14. Offline Telemetry Sync Proof

Steps performed:
1. Put device in airplane mode.
2. Played 3 videos.
3. Confirmed events stored in SharedPreferences.
4. Restored connectivity.
5. Confirmed sync triggered.

Result:
```

```

## 15. Performance Dashboard Screenshot

Session ID used:  
Screenshot filename or description:  

Paste the certification API response:

```json

```

`certifiedForControlledRelease`: ✅ true / ❌ false  
`blockers`: (list or "none")

## 16. Release Lock Proof

```bash
# POST /video-release/evaluate response with all gates passing:
```

Expected: `{ "allowed": true, "blockers": [] }`

```bash
# POST /video-release/evaluate response with one gate failing:
```

Expected: `{ "allowed": false, "blockers": ["..."] }`

## 17. 30-Minute Android Stability Result

- Test duration: 30 minutes
- Videos watched:
- Errors encountered:
- Memory at start:
- Memory at end:
- App crashed: ✅ never / ❌ crashed (describe)
- `thirtyMinuteStabilityPassed`: ✅ / ❌

## 18. 30-Minute iOS Stability Result

- Test duration: 30 minutes
- Videos watched:
- Errors encountered:
- App crashed: ✅ never / ❌ crashed (describe)
- `thirtyMinuteStabilityPassed`: ✅ / ❌

## 19. Known Limitations

List any known issues, edge cases, or incomplete items:

1.
2.
3.

## 20. Final Recommendation

```
[ ] RECOMMEND GO — All evidence submitted, all gates passed, no blocking issues.
[ ] RECOMMEND NO-GO — Issues found (described above).
[ ] RECOMMEND CONDITIONAL GO — Internal users only; specific limitation noted.
```

Notes:


---

*Evidence submitted by:*  
*Date:*  
*Reviewer:*  
*Review outcome:*
