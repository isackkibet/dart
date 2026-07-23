# Incident Response Playbook

## Incident types

### Media outage

Symptoms:
- broadcasts start but viewers see black screen
- audio/video missing
- consume failures spike

Actions:
1. check SFU health
2. check TURN health
3. check nginx WSS
4. check worker logs
5. disable new live sessions if widespread

### Signaling outage

Symptoms:
- joinRoom fails
- WebSocket disconnects
- request timeouts

Actions:
1. check WSS domain
2. check nginx logs
3. check signaling server process
4. check JWT validation errors

### TURN failure

Symptoms:
- works on same Wi-Fi but fails on restricted networks
- relay candidate missing
- mobile viewers fail more often

Actions:
1. check coturn service
2. check UDP/TCP ports
3. check credentials
4. check relay bandwidth

### Security incident

Symptoms:
- unauthorized creators go live
- token abuse
- room hijack

Actions:
1. revoke token issuer/key if needed
2. disable live sessions
3. inspect auth logs
4. rotate secrets
5. prepare incident report
