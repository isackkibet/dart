# Observability Requirements

## Required logs

Log these events:
- roomCreated
- peerJoined
- peerLeft
- transportCreated
- transportConnected
- producerCreated
- producerClosed
- consumerCreated
- consumerResumed
- signalingError
- workerDied
- workerRespawned

## Required metrics

Capture:
- active rooms
- active broadcasters
- active viewers
- transports count
- producers count
- consumers count
- worker CPU
- worker memory
- average session duration
- failed join attempts
- failed consume attempts
- reconnect attempts
- TURN usage ratio

## Required correlation IDs

Every session should have:
- roomId
- sessionId
- creatorUserId
- requestId
- peerId
- transportId
- producerId
- consumerId

## Production dashboard

Minimum dashboard:
- live sessions now
- failed sessions
- average startup time
- media failure rate
- TURN usage
- top failing device models
