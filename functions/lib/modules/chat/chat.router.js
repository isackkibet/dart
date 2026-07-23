"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.chatRouter = void 0;
const express_1 = require("express");
const firestore_1 = require("firebase-admin/firestore");
const requireAuth_1 = require("../../core/http/requireAuth");
const respond_1 = require("../../core/http/respond");
const chat_schema_1 = require("./chat.schema");
exports.chatRouter = (0, express_1.Router)();
const db = (0, firestore_1.getFirestore)();
// ── Paginated message history ──────────────────────────────────────────────────
exports.chatRouter.get("/sessions/:sessionId/messages", requireAuth_1.requireAuth, async (req, res) => {
    const uid = req.user?.uid;
    if (!uid)
        return (0, respond_1.fail)(res, 401, "missing_user", "Missing user.");
    const { sessionId } = req.params;
    const limit = Math.min(Number(req.query.limit) || 50, 100);
    const before = req.query.before;
    let query = db
        .collection("chatMessages")
        .where("sessionId", "==", sessionId)
        .where("isDeleted", "==", false)
        .orderBy("sentAt", "desc")
        .limit(limit);
    if (before) {
        const cursor = firestore_1.Timestamp.fromDate(new Date(before));
        query = query.startAfter(cursor);
    }
    const snap = await query.get();
    const messages = snap.docs
        .map((d) => ({ id: d.id, ...d.data() }))
        .reverse(); // Return oldest-first
    return (0, respond_1.ok)(res, { messages, total: messages.length });
});
// ── Send message ───────────────────────────────────────────────────────────────
exports.chatRouter.post("/sessions/:sessionId/messages", requireAuth_1.requireAuth, async (req, res) => {
    const uid = req.user?.uid;
    if (!uid)
        return (0, respond_1.fail)(res, 401, "missing_user", "Missing user.");
    const parsed = chat_schema_1.SendMessageSchema.safeParse(req.body);
    if (!parsed.success) {
        return (0, respond_1.fail)(res, 400, "invalid_message", "Invalid message payload.", parsed.error.flatten());
    }
    const { sessionId } = req.params;
    const { text, type } = parsed.data;
    // Check mute status
    const muteId = `${sessionId}_${uid}`;
    const muteDoc = await db.collection("chatMutes").doc(muteId).get();
    if (muteDoc.exists) {
        const muteData = muteDoc.data();
        const mutedUntil = muteData.mutedUntil?.toDate();
        if (mutedUntil && mutedUntil > new Date()) {
            return (0, respond_1.fail)(res, 403, "user_muted", "You are muted in this session.");
        }
        // Mute expired — clean it up
        await muteDoc.ref.delete();
    }
    // Server-side rate limit: max 1 message per second per user
    const oneSecondAgo = firestore_1.Timestamp.fromMillis(Date.now() - 1000);
    const recentSnap = await db
        .collection("chatMessages")
        .where("sessionId", "==", sessionId)
        .where("senderId", "==", uid)
        .where("sentAt", ">=", oneSecondAgo)
        .limit(1)
        .get();
    if (!recentSnap.empty) {
        return (0, respond_1.fail)(res, 429, "rate_limited", "You are sending messages too fast.");
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
        sentAt: firestore_1.FieldValue.serverTimestamp(),
    };
    const ref = await db.collection("chatMessages").add(messageData);
    return (0, respond_1.ok)(res, { id: ref.id, ...messageData }, 201);
});
// ── Pin message (creator only) ─────────────────────────────────────────────────
exports.chatRouter.post("/sessions/:sessionId/messages/:msgId/pin", requireAuth_1.requireAuth, async (req, res) => {
    const uid = req.user?.uid;
    if (!uid)
        return (0, respond_1.fail)(res, 401, "missing_user", "Missing user.");
    const { sessionId, msgId } = req.params;
    // Verify the session belongs to this creator
    const sessionDoc = await db.collection("streamSessions").doc(sessionId).get();
    if (!sessionDoc.exists) {
        return (0, respond_1.fail)(res, 404, "session_not_found", "Session not found.");
    }
    if (sessionDoc.data()?.creatorId !== uid && req.user?.admin !== true) {
        return (0, respond_1.fail)(res, 403, "forbidden", "Only the creator can pin messages.");
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
        return (0, respond_1.fail)(res, 404, "message_not_found", "Message not found.");
    }
    batch.update(msgRef, { isPinned: true });
    await batch.commit();
    return (0, respond_1.ok)(res, { id: msgId, isPinned: true });
});
// ── Delete message (creator/admin) ─────────────────────────────────────────────
exports.chatRouter.delete("/sessions/:sessionId/messages/:msgId", requireAuth_1.requireAuth, async (req, res) => {
    const uid = req.user?.uid;
    if (!uid)
        return (0, respond_1.fail)(res, 401, "missing_user", "Missing user.");
    const { sessionId, msgId } = req.params;
    // Creator or admin can delete
    const sessionDoc = await db.collection("streamSessions").doc(sessionId).get();
    const isSessionCreator = sessionDoc.data()?.creatorId === uid;
    if (!isSessionCreator && req.user?.admin !== true) {
        return (0, respond_1.fail)(res, 403, "forbidden", "Only the creator can delete messages.");
    }
    const msgRef = db.collection("chatMessages").doc(msgId);
    const msgDoc = await msgRef.get();
    if (!msgDoc.exists) {
        return (0, respond_1.fail)(res, 404, "message_not_found", "Message not found.");
    }
    // Soft delete — preserve for audit; hide from viewers via isDeleted flag
    await msgRef.update({
        isDeleted: true,
        isPinned: false,
        deletedAt: firestore_1.FieldValue.serverTimestamp(),
        deletedBy: uid,
    });
    return (0, respond_1.ok)(res, { id: msgId, isDeleted: true });
});
// ── Mute user (creator only) ───────────────────────────────────────────────────
exports.chatRouter.post("/sessions/:sessionId/mute", requireAuth_1.requireAuth, async (req, res) => {
    const uid = req.user?.uid;
    if (!uid)
        return (0, respond_1.fail)(res, 401, "missing_user", "Missing user.");
    const parsed = chat_schema_1.MuteUserSchema.safeParse(req.body);
    if (!parsed.success) {
        return (0, respond_1.fail)(res, 400, "invalid_mute", "Invalid mute payload.", parsed.error.flatten());
    }
    const { sessionId } = req.params;
    const { userId, durationSeconds } = parsed.data;
    // Verify creator
    const sessionDoc = await db.collection("streamSessions").doc(sessionId).get();
    if (!sessionDoc.exists) {
        return (0, respond_1.fail)(res, 404, "session_not_found", "Session not found.");
    }
    if (sessionDoc.data()?.creatorId !== uid && req.user?.admin !== true) {
        return (0, respond_1.fail)(res, 403, "forbidden", "Only the creator can mute users.");
    }
    const mutedUntil = new Date(Date.now() + durationSeconds * 1000);
    const muteId = `${sessionId}_${userId}`;
    await db.collection("chatMutes").doc(muteId).set({
        sessionId,
        mutedUserId: userId,
        mutedBy: uid,
        durationSeconds,
        mutedAt: firestore_1.FieldValue.serverTimestamp(),
        mutedUntil: firestore_1.Timestamp.fromDate(mutedUntil),
    });
    return (0, respond_1.ok)(res, { muteId, userId, mutedUntil: mutedUntil.toISOString() });
});
// ── List muted users (creator only) ───────────────────────────────────────────
exports.chatRouter.get("/sessions/:sessionId/muted", requireAuth_1.requireAuth, async (req, res) => {
    const uid = req.user?.uid;
    if (!uid)
        return (0, respond_1.fail)(res, 401, "missing_user", "Missing user.");
    const { sessionId } = req.params;
    const sessionDoc = await db.collection("streamSessions").doc(sessionId).get();
    if (!sessionDoc.exists) {
        return (0, respond_1.fail)(res, 404, "session_not_found", "Session not found.");
    }
    if (sessionDoc.data()?.creatorId !== uid && req.user?.admin !== true) {
        return (0, respond_1.fail)(res, 403, "forbidden", "Only the creator can view muted users.");
    }
    const snap = await db
        .collection("chatMutes")
        .where("sessionId", "==", sessionId)
        .orderBy("mutedAt", "desc")
        .get();
    const now = new Date();
    const rawMuted = snap.docs.map((d) => ({
        id: d.id,
        ...d.data(),
    }));
    const muted = rawMuted.filter((m) => {
        const until = m["mutedUntil"]?.toDate();
        return until && until > now;
    });
    return (0, respond_1.ok)(res, { muted, total: muted.length });
});
//# sourceMappingURL=chat.router.js.map