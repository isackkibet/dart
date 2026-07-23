import { Router } from "express";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { v4 as uuidv4 } from "uuid";
import { AuthenticatedRequest, requireAuth } from "../../core/http/requireAuth";
import { fail, ok } from "../../core/http/respond";
import {
  CreateCampaignSchema,
  RecordClickSchema,
  RecordImpressionSchema,
  UpdateCampaignSchema,
} from "./ads.schema";

export const adsRouter = Router();
const db = getFirestore();

// ── List campaigns ─────────────────────────────────────────────────────────────
adsRouter.get(
  "/campaigns",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const uid = req.user?.uid;
    if (!uid) return fail(res, 401, "missing_user", "Missing user.");

    const statusFilter = req.query.status as string | undefined;
    let query = db
      .collection("adCampaigns")
      .where("advertiserId", "==", uid)
      .orderBy("createdAt", "desc")
      .limit(50);

    if (statusFilter) {
      query = db
        .collection("adCampaigns")
        .where("advertiserId", "==", uid)
        .where("status", "==", statusFilter)
        .orderBy("createdAt", "desc")
        .limit(50);
    }

    const snap = await query.get();
    const campaigns = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
    return ok(res, { campaigns, total: campaigns.length });
  },
);

// ── Get single campaign ────────────────────────────────────────────────────────
adsRouter.get(
  "/campaigns/:id",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const uid = req.user?.uid;
    if (!uid) return fail(res, 401, "missing_user", "Missing user.");

    const doc = await db.collection("adCampaigns").doc(req.params.id).get();
    if (!doc.exists) return fail(res, 404, "campaign_not_found", "Campaign not found.");
    if (doc.data()?.advertiserId !== uid && req.user?.admin !== true) {
      return fail(res, 403, "forbidden", "Access denied.");
    }
    return ok(res, { id: doc.id, ...doc.data() });
  },
);

// ── Create campaign ────────────────────────────────────────────────────────────
adsRouter.post(
  "/campaigns",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const uid = req.user?.uid;
    if (!uid) return fail(res, 401, "missing_user", "Missing user.");

    const parsed = CreateCampaignSchema.safeParse(req.body);
    if (!parsed.success) {
      return fail(res, 400, "invalid_campaign", "Invalid campaign payload.", parsed.error.flatten());
    }

    const data = {
      ...parsed.data,
      advertiserId: uid,
      status: "draft",
      spentCents: 0,
      impressionCount: 0,
      clickCount: 0,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      createdBy: uid,
      updatedBy: uid,
    };

    const ref = await db.collection("adCampaigns").add(data);
    return ok(res, { id: ref.id, ...data }, 201);
  },
);

// ── Update campaign ────────────────────────────────────────────────────────────
adsRouter.patch(
  "/campaigns/:id",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const uid = req.user?.uid;
    if (!uid) return fail(res, 401, "missing_user", "Missing user.");

    const parsed = UpdateCampaignSchema.safeParse(req.body);
    if (!parsed.success) {
      return fail(res, 400, "invalid_update", "Invalid update payload.", parsed.error.flatten());
    }

    const ref = db.collection("adCampaigns").doc(req.params.id);
    const doc = await ref.get();
    if (!doc.exists) return fail(res, 404, "campaign_not_found", "Campaign not found.");
    if (doc.data()?.advertiserId !== uid && req.user?.admin !== true) {
      return fail(res, 403, "forbidden", "Access denied.");
    }

    await ref.update({
      ...parsed.data,
      updatedAt: FieldValue.serverTimestamp(),
      updatedBy: uid,
    });
    return ok(res, { id: req.params.id, updated: true });
  },
);

// ── Pause campaign ─────────────────────────────────────────────────────────────
adsRouter.patch(
  "/campaigns/:id/pause",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const uid = req.user?.uid;
    if (!uid) return fail(res, 401, "missing_user", "Missing user.");

    const ref = db.collection("adCampaigns").doc(req.params.id);
    const doc = await ref.get();
    if (!doc.exists) return fail(res, 404, "campaign_not_found", "Campaign not found.");
    if (doc.data()?.advertiserId !== uid && req.user?.admin !== true) {
      return fail(res, 403, "forbidden", "Access denied.");
    }
    if (doc.data()?.status !== "active") {
      return fail(res, 400, "not_active", "Only active campaigns can be paused.");
    }
    await ref.update({
      status: "paused",
      updatedAt: FieldValue.serverTimestamp(),
      updatedBy: uid,
    });
    return ok(res, { id: req.params.id, status: "paused" });
  },
);

// ── Resume campaign ────────────────────────────────────────────────────────────
adsRouter.patch(
  "/campaigns/:id/resume",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const uid = req.user?.uid;
    if (!uid) return fail(res, 401, "missing_user", "Missing user.");

    const ref = db.collection("adCampaigns").doc(req.params.id);
    const doc = await ref.get();
    if (!doc.exists) return fail(res, 404, "campaign_not_found", "Campaign not found.");
    if (doc.data()?.advertiserId !== uid && req.user?.admin !== true) {
      return fail(res, 403, "forbidden", "Access denied.");
    }
    if (doc.data()?.status !== "paused") {
      return fail(res, 400, "not_paused", "Only paused campaigns can be resumed.");
    }
    await ref.update({
      status: "active",
      updatedAt: FieldValue.serverTimestamp(),
      updatedBy: uid,
    });
    return ok(res, { id: req.params.id, status: "active" });
  },
);

// ── Ad serving ─────────────────────────────────────────────────────────────────
adsRouter.get(
  "/serve",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const { sessionId, tags } = req.query;
    if (!sessionId) return fail(res, 400, "missing_session", "sessionId is required.");

    const tagList: string[] = tags
      ? (tags as string).split(",").map((t) => t.trim()).filter(Boolean)
      : [];

    const now = new Date();

    // Find best-matching active campaign with remaining budget
    let query = db
      .collection("adCampaigns")
      .where("status", "==", "active")
      .orderBy("cpmCents", "desc")
      .limit(20);

    const snap = await query.get();
    const candidates = snap.docs
      .map((d) => ({ id: d.id, ...d.data() } as Record<string, unknown>))
      .filter((c) => {
        const budget = (c.budgetCents as number) ?? 0;
        const spent = (c.spentCents as number) ?? 0;
        if (budget <= spent) return false;
        // Basic date window check
        if (c.startDate && new Date(c.startDate as string) > now) return false;
        if (c.endDate && new Date(c.endDate as string) < now) return false;
        return true;
      });

    if (candidates.length === 0) {
      return ok(res, { data: null });
    }

    // Tag affinity scoring: prefer campaigns whose tags overlap with session tags
    const scored = candidates.map((c) => {
      const campTags = (c.targetingTags as string[]) ?? [];
      const overlap = campTags.filter((t) => tagList.includes(t)).length;
      return { campaign: c, score: overlap };
    });

    scored.sort((a, b) => b.score - a.score);
    const best = scored[0].campaign;

    const placement = {
      placementId: uuidv4(),
      campaignId: best.id as string,
      advertiserId: best.advertiserId as string,
      creativeType: best.creativeType as string,
      creativeRef: best.creativeRef as string,
      ctaLabel: best.ctaLabel as string,
      ctaUrl: best.ctaUrl as string,
      durationSeconds: 15,
      impressionToken: Buffer.from(
        JSON.stringify({ placementId: uuidv4(), ts: Date.now() })
      ).toString("base64"),
    };

    return ok(res, { data: placement });
  },
);

// ── Record impression ──────────────────────────────────────────────────────────
adsRouter.post(
  "/impressions",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const uid = req.user?.uid;
    if (!uid) return fail(res, 401, "missing_user", "Missing user.");

    const parsed = RecordImpressionSchema.safeParse(req.body);
    if (!parsed.success) {
      return fail(res, 400, "invalid_impression", "Invalid impression payload.", parsed.error.flatten());
    }

    const { placementId, impressionToken, sessionId } = parsed.data;

    // Idempotency: one impression per viewer per placement
    const impressionId = `${placementId}_${uid}`;
    const ref = db.collection("adImpressions").doc(impressionId);
    const existing = await ref.get();
    if (existing.exists) {
      return ok(res, { recorded: false, reason: "already_recorded" });
    }

    // Decode campaignId from token (simplified — production uses HMAC verification)
    let campaignId: string | null = null;
    try {
      const decoded = JSON.parse(Buffer.from(impressionToken, "base64").toString());
      campaignId = decoded.campaignId ?? null;
    } catch {
      // Token parsing failed — still record impression
    }

    await db.runTransaction(async (txn) => {
      txn.set(ref, {
        placementId,
        sessionId,
        viewerId: uid,
        impressionToken,
        createdAt: FieldValue.serverTimestamp(),
      });

      if (campaignId) {
        const campRef = db.collection("adCampaigns").doc(campaignId);
        const campDoc = await txn.get(campRef);
        if (campDoc.exists) {
          const cpmCents = (campDoc.data()?.cpmCents as number) ?? 0;
          const costPerImpression = Math.round(cpmCents / 1000);
          txn.update(campRef, {
            impressionCount: FieldValue.increment(1),
            spentCents: FieldValue.increment(costPerImpression),
            updatedAt: FieldValue.serverTimestamp(),
          });
        }
      }
    });

    return ok(res, { recorded: true, placementId });
  },
);

// ── Record click ───────────────────────────────────────────────────────────────
adsRouter.post(
  "/clicks",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const uid = req.user?.uid;
    if (!uid) return fail(res, 401, "missing_user", "Missing user.");

    const parsed = RecordClickSchema.safeParse(req.body);
    if (!parsed.success) {
      return fail(res, 400, "invalid_click", "Invalid click payload.", parsed.error.flatten());
    }

    const { placementId, impressionToken, sessionId } = parsed.data;
    const clickId = `${placementId}_${uid}`;
    const ref = db.collection("adClicks").doc(clickId);
    const existing = await ref.get();
    if (existing.exists) {
      return ok(res, { recorded: false, reason: "already_recorded" });
    }

    await ref.set({
      placementId,
      sessionId,
      viewerId: uid,
      impressionToken,
      createdAt: FieldValue.serverTimestamp(),
    });

    // Increment clickCount on the campaign (best-effort, no transaction needed)
    try {
      const decoded = JSON.parse(Buffer.from(impressionToken, "base64").toString());
      if (decoded.campaignId) {
        await db.collection("adCampaigns").doc(decoded.campaignId).update({
          clickCount: FieldValue.increment(1),
          updatedAt: FieldValue.serverTimestamp(),
        });
      }
    } catch {
      // Non-critical — click still recorded
    }

    return ok(res, { recorded: true, placementId });
  },
);
