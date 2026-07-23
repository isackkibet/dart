"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.retryMultistreamDestination = exports.stopMultistreamFanOut = exports.startMultistreamFanOut = void 0;
const https_1 = require("firebase-functions/v2/https");
const firebaseAdmin_1 = require("../shared/firebaseAdmin");
const livekit_server_sdk_1 = require("livekit-server-sdk");
const LIVEKIT_URL = 'wss://yohpal-live-ln8xib3c.livekit.cloud';
function getEgressClient() {
    const key = process.env.LIVEKIT_API_KEY ?? '';
    const secret = process.env.LIVEKIT_API_SECRET ?? '';
    return new livekit_server_sdk_1.EgressClient(LIVEKIT_URL, key, secret);
}
exports.startMultistreamFanOut = (0, https_1.onRequest)({
    region: 'us-central1',
    cors: true,
    timeoutSeconds: 120,
    memory: '512MiB',
}, async (req, res) => {
    if (req.method !== 'POST') {
        res.status(405).json({ error: 'POST required' });
        return;
    }
    const { multistreamSessionId, liveSessionId } = req.body || {};
    if (!multistreamSessionId || !liveSessionId) {
        res.status(400).json({
            error: 'multistreamSessionId and liveSessionId are required',
        });
        return;
    }
    const liveSessionDoc = await firebaseAdmin_1.db
        .collection('liveSessions')
        .doc(liveSessionId)
        .get();
    if (!liveSessionDoc.exists) {
        res.status(404).json({ error: 'liveSession not found' });
        return;
    }
    const roomName = liveSessionDoc.data()?.roomName;
    if (!roomName) {
        res.status(400).json({ error: 'liveSession has no roomName' });
        return;
    }
    const sessionRef = firebaseAdmin_1.db
        .collection('multistreamSessions')
        .doc(multistreamSessionId);
    const destinationsSnap = await sessionRef.collection('destinations').get();
    await sessionRef.update({
        status: 'connecting',
        liveSessionId,
        updatedAt: firebaseAdmin_1.FieldValue.serverTimestamp(),
    });
    const client = getEgressClient();
    let liveCount = 0;
    for (const doc of destinationsSnap.docs) {
        const dest = doc.data();
        const rtmpUrl = dest.rtmpUrl;
        const streamKey = dest.streamKey;
        if (!rtmpUrl || !streamKey) {
            await doc.ref.update({
                status: 'error',
                error: 'Missing rtmpUrl or streamKey',
                updatedAt: firebaseAdmin_1.FieldValue.serverTimestamp(),
            });
            continue;
        }
        await doc.ref.update({
            status: 'connecting',
            updatedAt: firebaseAdmin_1.FieldValue.serverTimestamp(),
        });
        try {
            const egressInfo = await client.startRoomCompositeEgress(roomName, new livekit_server_sdk_1.StreamOutput({
                protocol: livekit_server_sdk_1.StreamProtocol.RTMP,
                urls: [`${rtmpUrl}/${streamKey}`],
            }));
            await doc.ref.update({
                status: 'live',
                egressId: egressInfo.egressId,
                updatedAt: firebaseAdmin_1.FieldValue.serverTimestamp(),
            });
            liveCount++;
        }
        catch (err) {
            const msg = err instanceof Error ? err.message : String(err);
            await doc.ref.update({
                status: 'error',
                error: msg,
                updatedAt: firebaseAdmin_1.FieldValue.serverTimestamp(),
            });
        }
    }
    await sessionRef.update({
        status: liveCount > 0 ? 'live' : 'error',
        updatedAt: firebaseAdmin_1.FieldValue.serverTimestamp(),
    });
    await firebaseAdmin_1.db.collection('multistreamAuditLogs').add({
        multistreamSessionId,
        liveSessionId,
        roomName,
        action: 'MULTISTREAM_STARTED',
        destinationCount: destinationsSnap.size,
        liveCount,
        createdAt: firebaseAdmin_1.FieldValue.serverTimestamp(),
    });
    res.json({ ok: true, liveCount, total: destinationsSnap.size });
});
exports.stopMultistreamFanOut = (0, https_1.onRequest)({
    region: 'us-central1',
    cors: true,
    timeoutSeconds: 60,
    memory: '256MiB',
}, async (req, res) => {
    const { multistreamSessionId } = req.body || {};
    if (!multistreamSessionId) {
        res.status(400).json({ error: 'multistreamSessionId required' });
        return;
    }
    const sessionRef = firebaseAdmin_1.db
        .collection('multistreamSessions')
        .doc(multistreamSessionId);
    const destinationsSnap = await sessionRef.collection('destinations').get();
    const client = getEgressClient();
    for (const doc of destinationsSnap.docs) {
        const egressId = doc.data().egressId;
        if (egressId) {
            try {
                await client.stopEgress(egressId);
            }
            catch {
                // Egress may already be stopped — not fatal
            }
        }
        await doc.ref.update({
            status: 'ended',
            updatedAt: firebaseAdmin_1.FieldValue.serverTimestamp(),
        });
    }
    await sessionRef.update({
        status: 'ended',
        updatedAt: firebaseAdmin_1.FieldValue.serverTimestamp(),
    });
    await firebaseAdmin_1.db.collection('multistreamAuditLogs').add({
        multistreamSessionId,
        action: 'MULTISTREAM_STOPPED',
        createdAt: firebaseAdmin_1.FieldValue.serverTimestamp(),
    });
    res.json({ ok: true });
});
exports.retryMultistreamDestination = (0, https_1.onRequest)({
    region: 'us-central1',
    cors: true,
    timeoutSeconds: 60,
    memory: '256MiB',
}, async (req, res) => {
    const { multistreamSessionId, destinationId } = req.body || {};
    if (!multistreamSessionId || !destinationId) {
        res.status(400).json({
            error: 'multistreamSessionId and destinationId required',
        });
        return;
    }
    const sessionRef = firebaseAdmin_1.db
        .collection('multistreamSessions')
        .doc(multistreamSessionId);
    const sessionDoc = await sessionRef.get();
    const liveSessionId = sessionDoc.data()?.liveSessionId;
    if (!liveSessionId) {
        res.status(400).json({ error: 'multistreamSession has no liveSessionId' });
        return;
    }
    const liveSessionDoc = await firebaseAdmin_1.db
        .collection('liveSessions')
        .doc(liveSessionId)
        .get();
    const roomName = liveSessionDoc.data()?.roomName;
    if (!roomName) {
        res.status(400).json({ error: 'liveSession has no roomName' });
        return;
    }
    const destRef = sessionRef
        .collection('destinations')
        .doc(destinationId);
    const destDoc = await destRef.get();
    const dest = destDoc.data();
    if (!dest) {
        res.status(404).json({ error: 'destination not found' });
        return;
    }
    const client = getEgressClient();
    if (dest.egressId) {
        try {
            await client.stopEgress(dest.egressId);
        }
        catch {
            // May already be stopped
        }
    }
    await destRef.update({
        status: 'connecting',
        error: null,
        updatedAt: firebaseAdmin_1.FieldValue.serverTimestamp(),
    });
    try {
        const egressInfo = await client.startRoomCompositeEgress(roomName, new livekit_server_sdk_1.StreamOutput({
            protocol: livekit_server_sdk_1.StreamProtocol.RTMP,
            urls: [`${dest.rtmpUrl}/${dest.streamKey}`],
        }));
        await destRef.update({
            status: 'live',
            egressId: egressInfo.egressId,
            updatedAt: firebaseAdmin_1.FieldValue.serverTimestamp(),
        });
    }
    catch (err) {
        const msg = err instanceof Error ? err.message : String(err);
        await destRef.update({
            status: 'error',
            error: msg,
            updatedAt: firebaseAdmin_1.FieldValue.serverTimestamp(),
        });
        res.status(500).json({ ok: false, error: msg });
        return;
    }
    await firebaseAdmin_1.db.collection('multistreamAuditLogs').add({
        multistreamSessionId,
        destinationId,
        action: 'MULTISTREAM_DESTINATION_RETRIED',
        createdAt: firebaseAdmin_1.FieldValue.serverTimestamp(),
    });
    res.json({ ok: true });
});
