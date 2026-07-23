import { onRequest } from 'firebase-functions/v2/https';
import { AccessToken } from 'livekit-server-sdk';

export const createLiveKitToken = onRequest(
  {
    region: 'us-central1',
    cors: true,
    timeoutSeconds: 30,
    memory: '256MiB',
  },
  async (req, res) => {
    if (req.method !== 'POST') {
      res.status(405).json({ error: 'POST required' });
      return;
    }

    const { roomName, identity, role } = req.body || {};
    if (!roomName || !identity || !role) {
      res.status(400).json({
        error: 'roomName, identity, and role are required',
      });
      return;
    }

    const apiKey = process.env.LIVEKIT_API_KEY;
    const apiSecret = process.env.LIVEKIT_API_SECRET;
    if (!apiKey || !apiSecret) {
      res.status(500).json({
        error: 'LiveKit credentials are not configured',
      });
      return;
    }

    const token = new AccessToken(apiKey, apiSecret, {
      identity,
      ttl: '2h',
    });
    token.addGrant({
      room: roomName,
      roomJoin: true,
      canPublish: role === 'host',
      canSubscribe: true,
      canPublishData: true,
    });

    const jwt = await token.toJwt();
    res.json({ token: jwt, roomName, role });
    return;
  },
);
