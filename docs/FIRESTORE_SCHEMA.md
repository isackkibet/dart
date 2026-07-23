# Firestore Schema

## users/{uid}
profile, onboarding, privacy, referralCode, interests.

## creatorProfiles/{uid}
displayName, bio, followerCount, totalViews, totalVideos, monetisationEligible, trustScore.

## videos/{videoId}
ownerId, caption, tags, hlsUrl, thumbnailUrl, status, broken, views, likes, shares, rankingScore.

## videoEvents/{eventId}
type, userId, videoId, watchMs, createdAt.

## aiVideoJobs/{jobId}
videoId, type, status, output, error.

## liveSessions/{id}
creatorId, status, streamKey, playbackUrl, startedAt, endedAt.

## walletSessions/{id}
userId, purpose, amountKes, status. Backend-only completion.
