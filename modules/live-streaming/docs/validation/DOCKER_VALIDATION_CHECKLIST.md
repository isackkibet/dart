# Docker Validation Checklist

## Before start
- [ ] `.env` exists
- [ ] `ANNOUNCED_IP` set
- [ ] `LAN_IP` set
- [ ] certs generated
- [ ] TURN config generated

## Start

```bash
npm run docker:up
```

## Validate

```bash
docker compose -f docker/docker-compose.yml --env-file .env ps
curl -k https://<LAN_IP>/health
curl -k -I https://<LAN_IP>/test-client/
```

## Expected

- mediasoup container running
- turn container running
- nginx container running
- /health returns JSON
- /test-client/ returns HTML
