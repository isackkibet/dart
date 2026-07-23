#!/usr/bin/env bash
set -euo pipefail

echo "AI STUDIO LIVE MODE VERIFICATION"

echo "Required Firebase secrets:"
echo "- YOHPAL_BRAIN_API_KEY"
echo "- YOHPAL_BRAIN_API_URL"

firebase functions:secrets:access YOHPAL_BRAIN_API_KEY >/dev/null
firebase functions:secrets:access YOHPAL_BRAIN_API_URL >/dev/null
echo "Secrets exist."

echo "Redeploying AI function..."
firebase deploy --only functions:processAiVideoJob

echo "Now verify inside app:"
echo "1. AI Captions"
echo "2. AI Hooks"
echo "3. AI Hashtags"
echo "4. Viral Score"
echo "5. Thumbnail Ideas"
echo "Confirm Mark Ready unlocks."
