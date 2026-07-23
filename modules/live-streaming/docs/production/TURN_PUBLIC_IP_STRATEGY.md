# TURN Public IP Strategy

## Purpose

TURN is required when direct UDP paths fail.

## Production TURN requirements

- public static IP
- stable DNS record
- UDP 3478 open
- TCP 3478 open
- optional TLS TURN on 5349
- relay port range open
- monitored bandwidth
- long-term credential mechanism
- rotated credentials

## Example DNS

```text
turn.yohpal.com
```

### Example client config

```json
{
  "urls": "turn:turn.yohpal.com:3478",
  "username": "<short-lived-turn-username>",
  "credential": "<short-lived-turn-password>"
}
```

## Security rule

Do not hardcode production TURN credentials in Flutter. YohPal backend must issue temporary TURN credentials.

## Capacity warning

TURN relays media traffic and can become expensive. Monitor:
- relay bandwidth
- allocation count
- failed allocations
- packet loss
- CPU/memory
