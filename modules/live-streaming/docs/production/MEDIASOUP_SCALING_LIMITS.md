# mediasoup Scaling Limits

## Important principle

mediasoup is powerful but not unlimited. A mediasoup Worker maps to a single CPU core. A Router lives inside a Worker. Room placement must account for this.

## Initial production strategy

Start with vertical scaling:
- one SFU node
- multiple mediasoup workers
- room assignment by round-robin
- strict room caps
- observability per room/worker

## Recommended launch caps

For controlled pilot:
- one broadcaster per room
- limited viewers per room
- no recording
- no simulcast
- no adaptive bitrate
- no multi-host rooms

## Metrics needed before scaling

Track:
- workers count
- rooms per worker
- transports per worker
- producers per worker
- consumers per worker
- bitrate per worker
- packet loss
- CPU usage
- memory usage
- reconnect events

## Future scaling

Later versions may require:
- room sharding
- multiple SFU nodes
- regional SFU placement
- router piping
- dedicated TURN nodes
- autoscaling strategy
