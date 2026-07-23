# Production Environment Template

```env
NODE_ENV=production

API_PORT=3000
WS_PORT=3001

PUBLIC_SIGNALING_DOMAIN=live-api.yohpal.com
PUBLIC_TURN_DOMAIN=turn.yohpal.com
ANNOUNCED_IP=<PUBLIC_SFU_IP>

RTC_MIN_PORT=10000
RTC_MAX_PORT=20000

JWT_ISSUER=yohpal-live
JWT_AUDIENCE=yohpal-live-streaming
JWT_PUBLIC_KEY_PATH=/run/secrets/live_jwt_public_key.pem

TURN_REALM=yohpal.com
TURN_STATIC_AUTH_SECRET=<secret-from-secret-manager>

LOG_LEVEL=info
METRICS_ENABLED=true
```

## Secret handling

Do not commit production secrets. Use:
- secret manager
- encrypted environment variables
- deployment platform secrets
