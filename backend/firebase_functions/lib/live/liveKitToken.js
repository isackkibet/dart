"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.createLiveKitToken = void 0;
const https_1 = require("firebase-functions/v2/https");
const livekit_server_sdk_1 = require("livekit-server-sdk");
exports.createLiveKitToken = (0, https_1.onRequest)({
    region: 'us-central1',
    cors: true,
    timeoutSeconds: 30,
    memory: '256MiB',
}, async (req, res) => {
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
    const token = new livekit_server_sdk_1.AccessToken(apiKey, apiSecret, {
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
});
