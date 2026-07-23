import { Router } from "express";
import { FieldValue, getFirestore, Timestamp } from "firebase-admin/firestore";
import { AuthenticatedRequest, requireAuth } from "../../core/http/requireAuth";
import { fail, ok } from "../../core/http/respond";
import { MuteUserSchema, SendMessageSchema } from "./chat.schema";

export const chatRouter = Router();
const db = getFirestore();

// ── Paginated message history ──────────────────────────────────────────────────
chatRouter.get(
  "/sessions/:sessionId/messages",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const uid = req.user?.uid;
    if (!uid) return fail(res, 401, "missing_user", "Missing user.");

    const { sessionId } = req.params;
    const limit = Math.min(Number(req.query.limit) || 50, 100);
    const before = req.query.before as string | undefined;

    let query = db
      .collection("chatMessages")
      .where("sessionId", "==", sessionId)
      .where("isDeleted", "==", false)
      .orderBy("sentAt", "desc")
      .limit(limit);

    if (before) {
      const cursor = Timestamp.fromDate(new Date(before));
      query = query.startAfter(cursor);
    }

    const snap = await query.get();
    const messages = snap.docs
      .map((d) => ({ id: d.id, ...d.data() }))
      .reverse(); // Return oldest-first

    return ok(res, { messages, total: messages.length });
  },
);

// ── Send message ───────────────────────────────────────────────────────────────
chatRouter.post(
  "/sessions/:sessionId/messages",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const uid = req.user?.uid;
    if (!uid) return fail(res, 401, "missing_user", "Missing user.");

    const parsed = SendMessageSchema.safeParse(req.body);
    if (!parsed.success) {
      return fail(res, 400, "invalid_message", "Invalid message payload.", parsed.error.flatten());
    }

    const { sessionId } = req.params;
    const { text, type } = parsed.data;

    // Check mute status
    const muteId = `${sessionId}_${uid}`;
    const muteDoc = await db.collection("chatMutes").doc(muteId).get();
    if (muteDoc.exists) {
      const muteData = muteDoc.data()!;
      const mutedUntil = (muteData.mutedUntil as Timestamp)?.toDate();
      if (mutedUntil && mutedUntil > new Date()) {
        return fail(res, 403, "user_muted", "You are muted in this session.");
      }
      // Mute expired — clean it up
      await muteDoc.ref.delete();
    }

    // Server-side rate limit: max 1 message per second per user
    const oneSecondAgo = Timestamp.fromMillis(Date.now() - 1000);
    const recentSnap = await db
      .collection("chatMessages")
      .where("sessionId", "==", sessionId)
      .where("senderId", "==", uid)
      .where("sentAt", ">=", oneSecondAgo)
      .limit(1)
      .get();

    if (!recentSnap.empty) {
      return fail(res, 429, "rate_limited", "You are sending messages too fast.");
    }

    // Fetch sender display name from Firestore profile
    const profileDoc = await db.collection("creatorProfiles").doc(uid).get();
    const senderName = profileDoc.data()?.displayName?.toString() ?? "Viewer";
    const senderAvatarUrl = profileDoc.data()?.avatarUrl?.toString() ?? null;

    const messageData = {
      sessionId,
      senderId: uid,
      senderName,
      senderAvatarUrl,
      text,
      type,
      isPinned: false,
      isDeleted: false,
      sentAt: FieldValue.serverTimestamp(),
    };

    const ref = await db.collection("chatMessages").add(messageData);
    return ok(res, { id: ref.id, ...messageData }, 201);
  },
);

// ── Pin message (creator only) ─────────────────────────────────────────────────
chatRouter.post(
  "/sessions/:sessionId/messages/:msgId/pin",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const uid = req.user?.uid;
    if (!uid) return fail(res, 401, "missing_user", "Missing user.");

    const { sessionId, msgId } = req.params;

    // Verify the session belongs to this creator
    const sessionDoc = await db.collection("streamSessions").doc(sessionId).get();
    if (!sessionDoc.exists) {
      return fail(res, 404, "session_not_found", "Session not found.");
    }
    if (sessionDoc.data()?.creatorId !== uid && req.user?.admin !== true) {
      return fail(res, 403, "forbidden", "Only the creator can pin messages.");
    }

    // Unpin any existing pinned messages for this session
    const pinnedSnap = await db
      .collection("chatMessages")
      .where("sessionId", "==", sessionId)
      .where("isPinned", "==", true)
      .get();

    const batch = db.batch();
    for (const doc of pinnedSnap.docs) {
      batch.update(doc.ref, { isPinned: false });
    }

    // Pin the target message
    const msgRef = db.collection("chatMessages").doc(msgId);
    const msgDoc = await msgRef.get();
    if (!msgDoc.exists) {
      return fail(res, 404, "message_not_found", "Message not found.");
    }
    batch.update(msgRef, { isPinned: true });
    await batch.commit();

    return ok(res, { id: msgId, isPinned: true });
  },
);

// ── Delete message (creator/admin) ─────────────────────────────────────────────
chatRouter.delete(
  "/sessions/:sessionId/messages/:msgId",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const uid = req.user?.uid;
    if (!uid) return fail(res, 401, "missing_user", "Missing user.");

    const { sessionId, msgId } = req.params;

    // Creator or admin can delete
    const sessionDoc = await db.collection("streamSessions").doc(sessionId).get();
    const isSessionCreator = sessionDoc.data()?.creatorId === uid;
    if (!isSessionCreator && req.user?.admin !== true) {
      return fail(res, 403, "forbidden", "Only the creator can delete messages.");
    }

    const msgRef = db.collection("chatMessages").doc(msgId);
    const msgDoc = await msgRef.get();
    if (!msgDoc.exists) {
      return fail(res, 404, "message_not_found", "Message not found.");
    }

    // Soft delete — preserve for audit; hide from viewers via isDeleted flag
    await msgRef.update({
      isDeleted: true,
      isPinned: false,
      deletedAt: FieldValue.serverTimestamp(),
      deletedBy: uid,
    });

    return ok(res, { id: msgId, isDeleted: true });
  },
);

// ── Mute user (creator only) ───────────────────────────────────────────────────
chatRouter.post(
  "/sessions/:sessionId/mute",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const uid = req.user?.uid;
    if (!uid) return fail(res, 401, "missing_user", "Missing user.");

    const parsed = MuteUserSchema.safeParse(req.body);
    if (!parsed.success) {
      return fail(res, 400, "invalid_mute", "Invalid mute payload.", parsed.error.flatten());
    }

    const { sessionId } = req.params;
    const { userId, durationSeconds } = parsed.data;

    // Verify creator
    const sessionDoc = await db.collection("streamSessions").doc(sessionId).get();
    if (!sessionDoc.exists) {
      return fail(res, 404, "session_not_found", "Session not found.");
    }
    if (sessionDoc.data()?.creatorId !== uid && req.user?.admin !== true) {
      return fail(res, 403, "forbidden", "Only the creator can mute users.");
    }

    const mutedUntil = new Date(Date.now() + durationSeconds * 1000);
    const muteId = `${sessionId}_${userId}`;

    await db.collection("chatMutes").doc(muteId).set({
      sessionId,
      mutedUserId: userId,
      mutedBy: uid,
      durationSeconds,
      mutedAt: FieldValue.serverTimestamp(),
      mutedUntil: Timestamp.fromDate(mutedUntil),
    });

    return ok(res, { muteId, userId, mutedUntil: mutedUntil.toISOString() });
  },
);

// ── List muted users (creator only) ───────────────────────────────────────────
chatRouter.get(
  "/sessions/:sessionId/muted",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const uid = req.user?.uid;
    if (!uid) return fail(res, 401, "missing_user", "Missing user.");

    const { sessionId } = req.params;

    const sessionDoc = await db.collection("streamSessions").doc(sessionId).get();
    if (!sessionDoc.exists) {
      return fail(res, 404, "session_not_found", "Session not found.");
    }
    if (sessionDoc.data()?.creatorId !== uid && req.user?.admin !== true) {
      return fail(res, 403, "forbidden", "Only the creator can view muted users.");
    }

    const snap = await db
      .collection("chatMutes")
      .where("sessionId", "==", sessionId)
      .orderBy("mutedAt", "desc")
      .get();

    const now = new Date();
    const rawMuted: Array<Record<string, unknown>> = snap.docs.map((d) => ({
      id: d.id,
      ...d.data(),
    }));
    const muted = rawMuted.filter((m) => {
      const until = (m["mutedUntil"] as Timestamp | undefined)?.toDate();
      return until && until > now;
    });

    return ok(res, { muted, total: muted.length });

  },
);
