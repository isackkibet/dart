# Go / No-Go Launch Checklist

## Architecture

- [ ] YohPal Live backend owns stream sessions
- [ ] Flutter does not mint production tokens
- [ ] production TLS is valid
- [ ] WSS domain is reachable
- [ ] TURN public IP/domain is reachable
- [ ] mediasoup announced IP is public/reachable

## Security

- [ ] JWT issuer validated
- [ ] JWT audience validated
- [ ] JWT expiry validated
- [ ] broadcaster role authorization enforced
- [ ] viewer authorization enforced
- [ ] secrets stored outside repo
- [ ] production TURN credentials not hardcoded

## Operations

- [ ] health endpoint monitored
- [ ] worker death alert configured
- [ ] room failure alert configured
- [ ] signaling error alert configured
- [ ] TURN usage monitored
- [ ] CPU/memory monitored

## Device certification

- [ ] Android supported-device matrix passed
- [ ] iOS supported-device matrix passed
- [ ] browser test baseline passed
- [ ] 30-minute live test passed
- [ ] restrictive network/TURN fallback passed

## Product

- [ ] creator can start live session
- [ ] viewer can join live session
- [ ] stream ended state works
- [ ] abuse/report pathway exists
- [ ] moderation responsibility assigned
- [ ] support team has failure playbook

## Decision

- [ ] GO
- [ ] NO-GO
- [ ] CONTROLLED PILOT ONLY
