#!/usr/bin/env python3
import csv
import sys
from collections import Counter
from pathlib import Path

path = Path(sys.argv[1])
if not path.exists():
    raise SystemExit(f"FAIL: file does not exist: {path}")

with path.open(newline="", encoding="utf-8") as source:
    rows = list(csv.DictReader(source))

video_ids = []
for row in rows:
    video_id = row.get("videoId", "").strip()
    if video_id:
        video_ids.append(video_id)

counts = Counter(video_ids)
duplicates = {
    video_id: count
    for video_id, count in counts.items()
    if count > 1
}

print(f"Total rows: {len(rows)}")
print(f"Video IDs: {len(video_ids)}")
print(f"Unique IDs: {len(counts)}")

if duplicates:
    print("FAIL: duplicate videos detected")
    for video_id, count in sorted(duplicates.items()):
        print(f"{video_id}: {count}")
    raise SystemExit(1)

if len(video_ids) < 100:
    raise SystemExit(
        f"FAIL: expected at least 100 videos; received {len(video_ids)}"
    )

print("PASS: 100-video feed contains no duplicate IDs")
