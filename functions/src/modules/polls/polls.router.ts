import { Router } from "express";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { v4 as uuidv4 } from "uuid";
import { AuthenticatedRequest, requireAuth } from "../../core/http/requireAuth";
import { fail, ok } from "../../core/http/respond";
import { CastVoteSchema, CreatePollSchema } from "./polls.schema";

export const pollsRouter = Router();
const db = getFirestore();

// ── List polls for a session ───────────────────────────────────────────────────
pollsRouter.get(
  "/session/:sessionId",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const uid = req.user?.uid;
    if (!uid) return fail(res, 401, "missing_user", "Missing user.");

    const { sessionId } = req.params;
    const snap = await db
      .collection("polls")
      .where("sessionId", "==", sessionId)
      .where("status", "!=", "archived")
      .orderBy("status")
      .orderBy("createdAt", "desc")
      .get();

    const polls = snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
    return ok(res, { polls, total: polls.length });
  },
);

// ── Get single poll ────────────────────────────────────────────────────────────
pollsRouter.get(
  "/:pollId",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const uid = req.user?.uid;
    if (!uid) return fail(res, 401, "missing_user", "Missing user.");

    const doc = await db.collection("polls").doc(req.params.pollId).get();
    if (!doc.exists) {
      return fail(res, 404, "poll_not_found", "Poll not found.");
    }
    return ok(res, { id: doc.id, ...doc.data() });
  },
);

// ── Create poll (creator only) ─────────────────────────────────────────────────
pollsRouter.post(
  "/session/:sessionId",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const uid = req.user?.uid;
    if (!uid) return fail(res, 401, "missing_user", "Missing user.");

    const parsed = CreatePollSchema.safeParse(req.body);
    if (!parsed.success) {
      return fail(
        res,
        400,
        "invalid_poll_payload",
        "Invalid poll payload.",
        parsed.error.flatten(),
      );
    }

    const { question, options, durationSeconds, allowMultipleVotes } =
      parsed.data;
    const { sessionId } = req.params;

    // Build option objects with stable IDs
    const optionObjects = options.map((label) => ({
      id: uuidv4(),
      label,
      voteCount: 0,
    }));

    const pollData = {
      sessionId,
      creatorId: uid,
      question,
      options: optionObjects,
      durationSeconds,
      allowMultipleVotes,
      status: "open",
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      closedAt: null,
      createdBy: uid,
      updatedBy: uid,
    };

    const ref = await db.collection("polls").add(pollData);

    // Auto-close after durationSeconds via a scheduled update is handled by the
    // Flutter countdown + creator closing manually. The backend honours explicit close.
    return ok(res, { id: ref.id, ...pollData }, 201);
  },
);

// ── Cast vote (idempotent) ─────────────────────────────────────────────────────
pollsRouter.post(
  "/:pollId/vote",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const uid = req.user?.uid;
    if (!uid) return fail(res, 401, "missing_user", "Missing user.");

    const parsed = CastVoteSchema.safeParse(req.body);
    if (!parsed.success) {
      return fail(
        res,
        400,
        "invalid_vote_payload",
        "Invalid vote payload.",
        parsed.error.flatten(),
      );
    }

    const { sessionId, optionIds } = parsed.data;
    const { pollId } = req.params;

    // Fetch the poll
    const pollRef = db.collection("polls").doc(pollId);
    const pollDoc = await pollRef.get();
    if (!pollDoc.exists) {
      return fail(res, 404, "poll_not_found", "Poll not found.");
    }
    const poll = pollDoc.data()!;
    if (poll.status !== "open") {
      return fail(res, 400, "poll_closed", "This poll is no longer accepting votes.");
    }

    // Validate optionIds exist in poll
    const validOptionIds = (poll.options as { id: string }[]).map((o) => o.id);
    const invalidIds = optionIds.filter((id) => !validOptionIds.includes(id));
    if (invalidIds.length > 0) {
      return fail(res, 400, "invalid_option_ids", "One or more option IDs are invalid.");
    }
    if (!poll.allowMultipleVotes && optionIds.length > 1) {
      return fail(res, 400, "multi_vote_not_allowed", "This poll does not allow multiple selections.");
    }

    // Idempotency — one vote per user per poll
    const voteId = `${pollId}_${uid}`;
    const voteRef = db.collection("pollVotes").doc(voteId);
    const existingVote = await voteRef.get();
    if (existingVote.exists) {
      return fail(res, 409, "already_voted", "You have already voted in this poll.");
    }

    // Atomic transaction: write vote + increment option voteCount(s)
    await db.runTransaction(async (txn) => {
      // Write vote document
      txn.set(voteRef, {
        pollId,
        sessionId,
        voterId: uid,
        optionIds,
        votedAt: FieldValue.serverTimestamp(),
      });

      // Increment voteCount for each selected option
      const options = poll.options as { id: string; label: string; voteCount: number }[];
      const updatedOptions = options.map((opt) => ({
        ...opt,
        voteCount: optionIds.includes(opt.id) ? opt.voteCount + 1 : opt.voteCount,
      }));

      txn.update(pollRef, {
        options: updatedOptions,
        updatedAt: FieldValue.serverTimestamp(),
        updatedBy: uid,
      });
    });

    return ok(res, { voted: true, pollId, optionIds });
  },
);

// ── Close poll (creator only) ──────────────────────────────────────────────────
pollsRouter.patch(
  "/:pollId/close",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const uid = req.user?.uid;
    if (!uid) return fail(res, 401, "missing_user", "Missing user.");

    const ref = db.collection("polls").doc(req.params.pollId);
    const doc = await ref.get();
    if (!doc.exists) {
      return fail(res, 404, "poll_not_found", "Poll not found.");
    }
    if (doc.data()?.creatorId !== uid && req.user?.admin !== true) {
      return fail(res, 403, "forbidden", "Only the creator can close this poll.");
    }
    if (doc.data()?.status !== "open") {
      return fail(res, 400, "poll_not_open", "Only open polls can be closed.");
    }

    await ref.update({
      status: "closed",
      closedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      updatedBy: uid,
    });

    return ok(res, { id: req.params.pollId, status: "closed" });
  },
);

// ── Delete poll (creator only) ─────────────────────────────────────────────────
pollsRouter.delete(
  "/:pollId",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const uid = req.user?.uid;
    if (!uid) return fail(res, 401, "missing_user", "Missing user.");

    const ref = db.collection("polls").doc(req.params.pollId);
    const doc = await ref.get();
    if (!doc.exists) {
      return fail(res, 404, "poll_not_found", "Poll not found.");
    }
    if (doc.data()?.creatorId !== uid && req.user?.admin !== true) {
      return fail(res, 403, "forbidden", "Only the creator can delete this poll.");
    }

    // Soft delete — archive instead of hard delete to preserve vote history
    await ref.update({
      status: "archived",
      updatedAt: FieldValue.serverTimestamp(),
      updatedBy: uid,
    });

    return ok(res, { id: req.params.pollId, status: "archived" });
  },
);
