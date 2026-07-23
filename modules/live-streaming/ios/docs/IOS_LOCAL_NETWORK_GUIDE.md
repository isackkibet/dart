# iOS Local Network Guide

For physical iPhone testing, the phone cannot use `localhost` to reach the development machine.

Use:

```text
wss://<HOST_LAN_IP>/ws
https://<HOST_LAN_IP>/health
turn:<HOST_LAN_IP>:3478
```

Example:

```text
wss://192.168.1.10/ws
```

## Same Wi-Fi required

The iPhone and development machine must be on the same Wi-Fi network.

## Router restrictions

Some routers block device-to-device traffic.

If testing fails:
- try a mobile hotspot
- disable guest Wi-Fi isolation
- confirm firewall allows inbound traffic
- test `https://<LAN_IP>/health` in Safari first
