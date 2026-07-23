# Physical-Device Certification Checklist

Record device models, OS versions, commit SHA, network, date and reviewer.

- Director joins using signed token.
- Camera 1 and Camera 2 join from separate physical phones.
- Camera 3 is rejected under FREE plan.
- Director receives both live previews.
- Manual Camera 1 → Camera 2 switching reaches YohPal Live viewers.
- Two-feed split screen reaches viewers with synchronized audio policy.
- Wi-Fi to mobile-data handoff reconnects within configured grace period.
- Director disconnect/reconnect restores control without duplicate participant.
- TURN-only test passes after blocking direct UDP paths.
- 30-minute thermal, battery and memory stability run passes.
- Live chat, moderation and viewer count remain functional.
- Audit export contains pairing, joins, disconnects, layout changes and status changes.
- YohPal Live SFU/WHIP ingest starts, sustains and ends cleanly.

Certification outcome: PASS / CONDITIONAL PASS / FAIL
