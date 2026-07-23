"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.adsRouter = void 0;
const express_1 = require("express");
const firestore_1 = require("firebase-admin/firestore");
const uuid_1 = require("uuid");
const requireAuth_1 = require("../../core/http/requireAuth");
const respond_1 = require("../../core/http/respond");
const ads_schema_1 = require("./ads.schema");
exports.adsRouter = (0, express_1.Router)();
const db = (0, firestore_1.getFirestore)();
// ── List campaigns ─────────────────────────────────────────────────────────────
exports.adsRouter.get("/campaigns", requireAuth_1.requireAuth, async (req, res) => {
    const uid = req.user?.uid;
    if (!uid)
        return (0, respond_1.fail)(res, 401, "missing_user", "Missing user.");
    const statusFilter = req.query.status;
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
    return (0, respond_1.ok)(res, { campaigns, total: campaigns.length });
});
// ── Get single campaign ────────────────────────────────────────────────────────
exports.adsRouter.get("/campaigns/:id", requireAuth_1.requireAuth, async (req, res) => {
    const uid = req.user?.uid;
    if (!uid)
        return (0, respond_1.fail)(res, 401, "missing_user", "Missing user.");
    const doc = await db.collection("adCampaigns").doc(req.params.id).get();
    if (!doc.exists)
        return (0, respond_1.fail)(res, 404, "campaign_not_found", "Campaign not found.");
    if (doc.data()?.advertiserId !== uid && req.user?.admin !== true) {
        return (0, respond_1.fail)(res, 403, "forbidden", "Access denied.");
    }
    return (0, respond_1.ok)(res, { id: doc.id, ...doc.data() });
});
// ── Create campaign ────────────────────────────────────────────────────────────
exports.adsRouter.post("/campaigns", requireAuth_1.requireAuth, async (req, res) => {
    const uid = req.user?.uid;
    if (!uid)
        return (0, respond_1.fail)(res, 401, "missing_user", "Missing user.");
    const parsed = ads_schema_1.CreateCampaignSchema.safeParse(req.body);
    if (!parsed.success) {
        return (0, respond_1.fail)(res, 400, "invalid_campaign", "Invalid campaign payload.", parsed.error.flatten());
    }
    const data = {
        ...parsed.data,
        advertiserId: uid,
        status: "draft",
        spentCents: 0,
        impressionCount: 0,
        clickCount: 0,
        createdAt: firestore_1.FieldValue.serverTimestamp(),
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
        createdBy: uid,
        updatedBy: uid,
    };
    const ref = await db.collection("adCampaigns").add(data);
    return (0, respond_1.ok)(res, { id: ref.id, ...data }, 201);
});
// ── Update campaign ────────────────────────────────────────────────────────────
exports.adsRouter.patch("/campaigns/:id", requireAuth_1.requireAuth, async (req, res) => {
    const uid = req.user?.uid;
    if (!uid)
        return (0, respond_1.fail)(res, 401, "missing_user", "Missing user.");
    const parsed = ads_schema_1.UpdateCampaignSchema.safeParse(req.body);
    if (!parsed.success) {
        return (0, respond_1.fail)(res, 400, "invalid_update", "Invalid update payload.", parsed.error.flatten());
    }
    const ref = db.collection("adCampaigns").doc(req.params.id);
    const doc = await ref.get();
    if (!doc.exists)
        return (0, respond_1.fail)(res, 404, "campaign_not_found", "Campaign not found.");
    if (doc.data()?.advertiserId !== uid && req.user?.admin !== true) {
        return (0, respond_1.fail)(res, 403, "forbidden", "Access denied.");
    }
    await ref.update({
        ...parsed.data,
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
        updatedBy: uid,
    });
    return (0, respond_1.ok)(res, { id: req.params.id, updated: true });
});
// ── Pause campaign ─────────────────────────────────────────────────────────────
exports.adsRouter.patch("/campaigns/:id/pause", requireAuth_1.requireAuth, async (req, res) => {
    const uid = req.user?.uid;
    if (!uid)
        return (0, respond_1.fail)(res, 401, "missing_user", "Missing user.");
    const ref = db.collection("adCampaigns").doc(req.params.id);
    const doc = await ref.get();
    if (!doc.exists)
        return (0, respond_1.fail)(res, 404, "campaign_not_found", "Campaign not found.");
    if (doc.data()?.advertiserId !== uid && req.user?.admin !== true) {
        return (0, respond_1.fail)(res, 403, "forbidden", "Access denied.");
    }
    if (doc.data()?.status !== "active") {
        return (0, respond_1.fail)(res, 400, "not_active", "Only active campaigns can be paused.");
    }
    await ref.update({
        status: "paused",
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
        updatedBy: uid,
    });
    return (0, respond_1.ok)(res, { id: req.params.id, status: "paused" });
});
// ── Resume campaign ────────────────────────────────────────────────────────────
exports.adsRouter.patch("/campaigns/:id/resume", requireAuth_1.requireAuth, async (req, res) => {
    const uid = req.user?.uid;
    if (!uid)
        return (0, respond_1.fail)(res, 401, "missing_user", "Missing user.");
    const ref = db.collection("adCampaigns").doc(req.params.id);
    const doc = await ref.get();
    if (!doc.exists)
        return (0, respond_1.fail)(res, 404, "campaign_not_found", "Campaign not found.");
    if (doc.data()?.advertiserId !== uid && req.user?.admin !== true) {
        return (0, respond_1.fail)(res, 403, "forbidden", "Access denied.");
    }
    if (doc.data()?.status !== "paused") {
        return (0, respond_1.fail)(res, 400, "not_paused", "Only paused campaigns can be resumed.");
    }
    await ref.update({
        status: "active",
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
        updatedBy: uid,
    });
    return (0, respond_1.ok)(res, { id: req.params.id, status: "active" });
});
// ── Ad serving ─────────────────────────────────────────────────────────────────
exports.adsRouter.get("/serve", requireAuth_1.requireAuth, async (req, res) => {
    const { sessionId, tags } = req.query;
    if (!sessionId)
        return (0, respond_1.fail)(res, 400, "missing_session", "sessionId is required.");
    const tagList = tags
        ? tags.split(",").map((t) => t.trim()).filter(Boolean)
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
        .map((d) => ({ id: d.id, ...d.data() }))
        .filter((c) => {
        const budget = c.budgetCents ?? 0;
        const spent = c.spentCents ?? 0;
        if (budget <= spent)
            return false;
        // Basic date window check
        if (c.startDate && new Date(c.startDate) > now)
            return false;
        if (c.endDate && new Date(c.endDate) < now)
            return false;
        return true;
    });
    if (candidates.length === 0) {
        return (0, respond_1.ok)(res, { data: null });
    }
    // Tag affinity scoring: prefer campaigns whose tags overlap with session tags
    const scored = candidates.map((c) => {
        const campTags = c.targetingTags ?? [];
        const overlap = campTags.filter((t) => tagList.includes(t)).length;
        return { campaign: c, score: overlap };
    });
    scored.sort((a, b) => b.score - a.score);
    const best = scored[0].campaign;
    const placement = {
        placementId: (0, uuid_1.v4)(),
        campaignId: best.id,
        advertiserId: best.advertiserId,
        creativeType: best.creativeType,
        creativeRef: best.creativeRef,
        ctaLabel: best.ctaLabel,
        ctaUrl: best.ctaUrl,
        durationSeconds: 15,
        impressionToken: Buffer.from(JSON.stringify({ placementId: (0, uuid_1.v4)(), ts: Date.now() })).toString("base64"),
    };
    return (0, respond_1.ok)(res, { data: placement });
});
// ── Record impression ──────────────────────────────────────────────────────────
exports.adsRouter.post("/impressions", requireAuth_1.requireAuth, async (req, res) => {
    const uid = req.user?.uid;
    if (!uid)
        return (0, respond_1.fail)(res, 401, "missing_user", "Missing user.");
    const parsed = ads_schema_1.RecordImpressionSchema.safeParse(req.body);
    if (!parsed.success) {
        return (0, respond_1.fail)(res, 400, "invalid_impression", "Invalid impression payload.", parsed.error.flatten());
    }
    const { placementId, impressionToken, sessionId } = parsed.data;
    // Idempotency: one impression per viewer per placement
    const impressionId = `${placementId}_${uid}`;
    const ref = db.collection("adImpressions").doc(impressionId);
    const existing = await ref.get();
    if (existing.exists) {
        return (0, respond_1.ok)(res, { recorded: false, reason: "already_recorded" });
    }
    // Decode campaignId from token (simplified — production uses HMAC verification)
    let campaignId = null;
    try {
        const decoded = JSON.parse(Buffer.from(impressionToken, "base64").toString());
        campaignId = decoded.campaignId ?? null;
    }
    catch {
        // Token parsing failed — still record impression
    }
    await db.runTransaction(async (txn) => {
        txn.set(ref, {
            placementId,
            sessionId,
            viewerId: uid,
            impressionToken,
            createdAt: firestore_1.FieldValue.serverTimestamp(),
        });
        if (campaignId) {
            const campRef = db.collection("adCampaigns").doc(campaignId);
            const campDoc = await txn.get(campRef);
            if (campDoc.exists) {
                const cpmCents = campDoc.data()?.cpmCents ?? 0;
                const costPerImpression = Math.round(cpmCents / 1000);
                txn.update(campRef, {
                    impressionCount: firestore_1.FieldValue.increment(1),
                    spentCents: firestore_1.FieldValue.increment(costPerImpression),
                    updatedAt: firestore_1.FieldValue.serverTimestamp(),
                });
            }
        }
    });
    return (0, respond_1.ok)(res, { recorded: true, placementId });
});
// ── Record click ───────────────────────────────────────────────────────────────
exports.adsRouter.post("/clicks", requireAuth_1.requireAuth, async (req, res) => {
    const uid = req.user?.uid;
    if (!uid)
        return (0, respond_1.fail)(res, 401, "missing_user", "Missing user.");
    const parsed = ads_schema_1.RecordClickSchema.safeParse(req.body);
    if (!parsed.success) {
        return (0, respond_1.fail)(res, 400, "invalid_click", "Invalid click payload.", parsed.error.flatten());
    }
    const { placementId, impressionToken, sessionId } = parsed.data;
    const clickId = `${placementId}_${uid}`;
    const ref = db.collection("adClicks").doc(clickId);
    const existing = await ref.get();
    if (existing.exists) {
        return (0, respond_1.ok)(res, { recorded: false, reason: "already_recorded" });
    }
    await ref.set({
        placementId,
        sessionId,
        viewerId: uid,
        impressionToken,
        createdAt: firestore_1.FieldValue.serverTimestamp(),
    });
    // Increment clickCount on the campaign (best-effort, no transaction needed)
    try {
        const decoded = JSON.parse(Buffer.from(impressionToken, "base64").toString());
        if (decoded.campaignId) {
            await db.collection("adCampaigns").doc(decoded.campaignId).update({
                clickCount: firestore_1.FieldValue.increment(1),
                updatedAt: firestore_1.FieldValue.serverTimestamp(),
            });
        }
    }
    catch {
        // Non-critical — click still recorded
    }
    return (0, respond_1.ok)(res, { recorded: true, placementId });
});
//# sourceMappingURL=ads.router.js.map