# YohPal Live Streaming LS-2A — Test Inventory

## Flutter Tests

### UI Tests
| Test ID | Description | Status |
|---------|-------------|--------|
| LS2A-UI-12 | Chat failure retains message and shows retry | PENDING |
| LS2A-UI-13 | Gift failure displays clear feedback | PENDING |

### Widget Tests
- [ ] LiveChatPanel renders correctly
- [ ] LiveGiftButton renders gift options
- [ ] Broadcaster controls appear for broadcaster role
- [ ] Viewer controls appear for viewer role

### Integration Tests
- [ ] Chat message send and receive
- [ ] Gift send and receipt
- [ ] Broadcaster start/stop
- [ ] Viewer join/leave
- [ ] Signaling timeout handling
- [ ] Reconnect on network drop

## Server Tests
- [ ] Live session creation
- [ ] Broadcaster registration
- [ ] Viewer registration
- [ ] DTLS handshake
- [ ] Media forwarding
- [ ] Chat message broadcast
- [ ] Gift transaction
- [ ] Session cleanup

## Physical Device Tests (Post-Board Acceptance)
### Android Broadcaster
- [ ] Broadcast start
- [ ] Broadcast stop
- [ ] Background/Foreground recovery
- [ ] 30-minute stability

### Android Viewer
- [ ] Join broadcast
- [ ] Leave broadcast
- [ ] Chat send/receive
- [ ] Gift send

### iPhone Broadcaster
- [ ] Broadcast start
- [ ] Broadcast stop
- [ ] Background/Foreground recovery
- [ ] 30-minute stability

### iPhone Viewer
- [ ] Join broadcast
- [ ] Leave broadcast
- [ ] Chat send/receive
- [ ] Gift send

### Cross-Device
- [ ] Android broadcaster → iPhone viewer
- [ ] iPhone broadcaster → Android viewer
- [ ] Android ↔ iPhone media delivery

### Performance
- [ ] DTLS handshake under 2 seconds
- [ ] Audio/video synchronization
- [ ] Network drop and reconnect
- [ ] Multiple viewers (5, 10, 20)

### Observability
- [ ] Crashlytics visibility
- [ ] Analytics events
- [ ] Session metrics
