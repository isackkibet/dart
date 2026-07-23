import { onRequest } from 'firebase-functions/v2/https';
import { db, FieldValue } from '../shared/firebaseAdmin';
import { EgressClient, StreamOutput, StreamProtocol } from 'livekit-server-sdk';

const LIVEKIT_URL = 'wss://yohpal-live-ln8xib3c.livekit.cloud';

function getEgressClient(): EgressClient {
  const key = process.env.LIVEKIT_API_KEY ?? '';
  const secret = process.env.LIVEKIT_API_SECRET ?? '';
  return new EgressClient(LIVEKIT_URL, key, secret);
}

export const startMultistreamFanOut = onRequest(
  {
    region: 'us-central1',
    cors: true,
    timeoutSeconds: 120,
    memory: '512MiB',
  },
  async (req, res) => {
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

    const liveSessionDoc = await db
      .collection('liveSessions')
      .doc(liveSessionId as string)
      .get();
    if (!liveSessionDoc.exists) {
      res.status(404).json({ error: 'liveSession not found' });
      return;
    }
    const roomName = liveSessionDoc.data()?.roomName as string | undefined;
    if (!roomName) {
      res.status(400).json({ error: 'liveSession has no roomName' });
      return;
    }

    const sessionRef = db
      .collection('multistreamSessions')
      .doc(multistreamSessionId as string);
    const destinationsSnap = await sessionRef.collection('destinations').get();

    await sessionRef.update({
      status: 'connecting',
      liveSessionId,
      updatedAt: FieldValue.serverTimestamp(),
    });

    const client = getEgressClient();
    let liveCount = 0;

    for (const doc of destinationsSnap.docs) {
      const dest = doc.data();
      const rtmpUrl = dest.rtmpUrl as string | undefined;
      const streamKey = dest.streamKey as string | undefined;

      if (!rtmpUrl || !streamKey) {
        await doc.ref.update({
          status: 'error',
          error: 'Missing rtmpUrl or streamKey',
          updatedAt: FieldValue.serverTimestamp(),
        });
        continue;
      }

      await doc.ref.update({
        status: 'connecting',
        updatedAt: FieldValue.serverTimestamp(),
      });

      try {
        const egressInfo = await client.startRoomCompositeEgress(
          roomName,
          new StreamOutput({
            protocol: StreamProtocol.RTMP,
            urls: [`${rtmpUrl}/${streamKey}`],
          }),
        );
        await doc.ref.update({
          status: 'live',
          egressId: egressInfo.egressId,
          updatedAt: FieldValue.serverTimestamp(),
        });
        liveCount++;
      } catch (err: unknown) {
        const msg = err instanceof Error ? err.message : String(err);
        await doc.ref.update({
          status: 'error',
          error: msg,
          updatedAt: FieldValue.serverTimestamp(),
        });
      }
    }

    await sessionRef.update({
      status: liveCount > 0 ? 'live' : 'error',
      updatedAt: FieldValue.serverTimestamp(),
    });

    await db.collection('multistreamAuditLogs').add({
      multistreamSessionId,
      liveSessionId,
      roomName,
      action: 'MULTISTREAM_STARTED',
      destinationCount: destinationsSnap.size,
      liveCount,
      createdAt: FieldValue.serverTimestamp(),
    });

    res.json({ ok: true, liveCount, total: destinationsSnap.size });
  },
);

export const stopMultistreamFanOut = onRequest(
  {
    region: 'us-central1',
    cors: true,
    timeoutSeconds: 60,
    memory: '256MiB',
  },
  async (req, res) => {
    const { multistreamSessionId } = req.body || {};
    if (!multistreamSessionId) {
      res.status(400).json({ error: 'multistreamSessionId required' });
      return;
    }

    const sessionRef = db
      .collection('multistreamSessions')
      .doc(multistreamSessionId as string);
    const destinationsSnap = await sessionRef.collection('destinations').get();

    const client = getEgressClient();

    for (const doc of destinationsSnap.docs) {
      const egressId = doc.data().egressId as string | undefined;
      if (egressId) {
        try {
          await client.stopEgress(egressId);
        } catch {
          // Egress may already be stopped — not fatal
        }
      }
      await doc.ref.update({
        status: 'ended',
        updatedAt: FieldValue.serverTimestamp(),
      });
    }

    await sessionRef.update({
      status: 'ended',
      updatedAt: FieldValue.serverTimestamp(),
    });

    await db.collection('multistreamAuditLogs').add({
      multistreamSessionId,
      action: 'MULTISTREAM_STOPPED',
      createdAt: FieldValue.serverTimestamp(),
    });

    res.json({ ok: true });
  },
);

export const retryMultistreamDestination = onRequest(
  {
    region: 'us-central1',
    cors: true,
    timeoutSeconds: 60,
    memory: '256MiB',
  },
  async (req, res) => {
    const { multistreamSessionId, destinationId } = req.body || {};
    if (!multistreamSessionId || !destinationId) {
      res.status(400).json({
        error: 'multistreamSessionId and destinationId required',
      });
      return;
    }

    const sessionRef = db
      .collection('multistreamSessions')
      .doc(multistreamSessionId as string);
    const sessionDoc = await sessionRef.get();
    const liveSessionId = sessionDoc.data()?.liveSessionId as
      | string
      | undefined;

    if (!liveSessionId) {
      res.status(400).json({ error: 'multistreamSession has no liveSessionId' });
      return;
    }

    const liveSessionDoc = await db
      .collection('liveSessions')
      .doc(liveSessionId)
      .get();
    const roomName = liveSessionDoc.data()?.roomName as string | undefined;
    if (!roomName) {
      res.status(400).json({ error: 'liveSession has no roomName' });
      return;
    }

    const destRef = sessionRef
      .collection('destinations')
      .doc(destinationId as string);
    const destDoc = await destRef.get();
    const dest = destDoc.data();

    if (!dest) {
      res.status(404).json({ error: 'destination not found' });
      return;
    }

    const client = getEgressClient();

    if (dest.egressId) {
      try {
        await client.stopEgress(dest.egressId as string);
      } catch {
        // May already be stopped
      }
    }

    await destRef.update({
      status: 'connecting',
      error: null,
      updatedAt: FieldValue.serverTimestamp(),
    });

    try {
      const egressInfo = await client.startRoomCompositeEgress(
        roomName,
        new StreamOutput({
          protocol: StreamProtocol.RTMP,
          urls: [`${dest.rtmpUrl}/${dest.streamKey}`],
        }),
      );
      await destRef.update({
        status: 'live',
        egressId: egressInfo.egressId,
        updatedAt: FieldValue.serverTimestamp(),
      });
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      await destRef.update({
        status: 'error',
        error: msg,
        updatedAt: FieldValue.serverTimestamp(),
      });
      res.status(500).json({ ok: false, error: msg });
      return;
    }

    await db.collection('multistreamAuditLogs').add({
      multistreamSessionId,
      destinationId,
      action: 'MULTISTREAM_DESTINATION_RETRIED',
      createdAt: FieldValue.serverTimestamp(),
    });

    res.json({ ok: true });
  },
);
