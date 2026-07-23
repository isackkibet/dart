# Secure Token Issuance

## Local prototype

Local prototype uses:
```bash
npm run token:broadcaster
npm run token:viewer
```

This is not production-safe.

## Production token owner

YohPal Live backend must issue tokens. Flutter must never sign stream JWTs locally.

## Required JWT claims

Recommended claims:

```json
{
  "iss": "yohpal-live",
  "aud": "yohpal-live-streaming",
  "sub": "<userId>",
  "roomId": "<roomId>",
  "role": "broadcaster",
  "iat": 0,
  "exp": 0,
  "jti": "<unique-token-id>"
}
```

## Token rules

- short-lived access token
- validate signature
- validate issuer
- validate audience
- validate expiry
- validate room ID
- validate role
- validate user is allowed to broadcast/view
- do not include sensitive business data in token

## Suggested expiry

Controlled pilot: 5–15 minutes. Renew using backend session endpoint if needed.

## Backend endpoints

Suggested:
```
POST /live/sessions
POST /live/sessions/{sessionId}/stream-token
POST /live/sessions/{sessionId}/viewer-token
POST /live/sessions/{sessionId}/end
```
