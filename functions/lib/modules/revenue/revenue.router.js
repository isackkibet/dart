"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.revenueRouter = void 0;
const express_1 = require("express");
const firestore_1 = require("firebase-admin/firestore");
const requireAuth_1 = require("../../core/http/requireAuth");
const respond_1 = require("../../core/http/respond");
const revenue_schema_1 = require("./revenue.schema");
exports.revenueRouter = (0, express_1.Router)();
const db = (0, firestore_1.getFirestore)();
exports.revenueRouter.get("/status", requireAuth_1.requireAuth, async (_req, res) => {
    return (0, respond_1.ok)(res, {
        module: "revenue",
        status: "ready",
        ledgerMode: "immutable",
    });
});
exports.revenueRouter.post("/gifts", requireAuth_1.requireAuth, async (req, res) => {
    const senderId = req.user?.uid;
    if (!senderId)
        return (0, respond_1.fail)(res, 401, "missing_user", "Missing user.");
    const parsed = revenue_schema_1.SendGiftSchema.safeParse(req.body);
    if (!parsed.success) {
        return (0, respond_1.fail)(res, 400, "invalid_gift_payload", "Invalid gift payload.", parsed.error.flatten());
    }
    const input = parsed.data;
    const result = await db.runTransaction(async (tx) => {
        const idempotencyRef = db
            .collection("paymentIdempotencyKeys")
            .doc(input.idempotencyKey);
        const existing = await tx.get(idempotencyRef);
        if (existing.exists) {
            return {
                duplicate: true,
                referenceId: existing.data()?.referenceId,
            };
        }
        const giftRef = db.collection("giftEvents").doc();
        const creatorLedgerRef = db.collection("ledgerEntries").doc();
        const platformLedgerRef = db.collection("ledgerEntries").doc();
        const platformFee = Number((input.amount * 0.1).toFixed(2));
        const creatorAmount = Number((input.amount - platformFee).toFixed(2));
        tx.set(giftRef, {
            sessionId: input.sessionId,
            creatorId: input.creatorId,
            senderId,
            giftType: input.giftType,
            amount: input.amount,
            currency: input.currency,
            platformFee,
            creatorAmount,
            createdAt: firestore_1.FieldValue.serverTimestamp(),
            createdBy: senderId,
        });
        tx.set(creatorLedgerRef, {
            ownerType: "creator",
            ownerId: input.creatorId,
            entryType: "gift_credit",
            direction: "credit",
            referenceType: "gift",
            referenceId: giftRef.id,
            amount: creatorAmount,
            currency: input.currency,
            createdAt: firestore_1.FieldValue.serverTimestamp(),
            createdBy: senderId,
        });
        tx.set(platformLedgerRef, {
            ownerType: "platform",
            ownerId: "yohpal",
            entryType: "platform_fee",
            direction: "credit",
            referenceType: "gift",
            referenceId: giftRef.id,
            amount: platformFee,
            currency: input.currency,
            createdAt: firestore_1.FieldValue.serverTimestamp(),
            createdBy: senderId,
        });
        tx.set(idempotencyRef, {
            key: input.idempotencyKey,
            operation: "gift",
            referenceId: giftRef.id,
            createdAt: firestore_1.FieldValue.serverTimestamp(),
            createdBy: senderId,
        });
        return {
            duplicate: false,
            referenceId: giftRef.id,
        };
    });
    return (0, respond_1.ok)(res, {
        accepted: true,
        duplicate: result.duplicate,
        giftId: result.referenceId,
    }, result.duplicate ? 200 : 201);
});
exports.revenueRouter.post("/paid-messages", requireAuth_1.requireAuth, async (req, res) => {
    const senderId = req.user?.uid;
    if (!senderId)
        return (0, respond_1.fail)(res, 401, "missing_user", "Missing user.");
    const parsed = revenue_schema_1.CreatePaidMessageSchema.safeParse(req.body);
    if (!parsed.success) {
        return (0, respond_1.fail)(res, 400, "invalid_paid_message_payload", "Invalid paid message payload.", parsed.error.flatten());
    }
    const input = parsed.data;
    const result = await db.runTransaction(async (tx) => {
        const idempotencyRef = db
            .collection("paymentIdempotencyKeys")
            .doc(input.idempotencyKey);
        const existing = await tx.get(idempotencyRef);
        if (existing.exists) {
            return {
                duplicate: true,
                referenceId: existing.data()?.referenceId,
            };
        }
        const paidMessageRef = db.collection("paidMessages").doc();
        const creatorLedgerRef = db.collection("ledgerEntries").doc();
        const platformLedgerRef = db.collection("ledgerEntries").doc();
        const platformFee = Number((input.amount * 0.1).toFixed(2));
        const creatorAmount = Number((input.amount - platformFee).toFixed(2));
        tx.set(paidMessageRef, {
            sessionId: input.sessionId,
            creatorId: input.creatorId,
            senderId,
            message: input.message,
            amount: input.amount,
            currency: input.currency,
            platformFee,
            creatorAmount,
            priorityRank: Math.round(input.amount),
            createdAt: firestore_1.FieldValue.serverTimestamp(),
            createdBy: senderId,
        });
        tx.set(creatorLedgerRef, {
            ownerType: "creator",
            ownerId: input.creatorId,
            entryType: "paid_message_credit",
            direction: "credit",
            referenceType: "paid_message",
            referenceId: paidMessageRef.id,
            amount: creatorAmount,
            currency: input.currency,
            createdAt: firestore_1.FieldValue.serverTimestamp(),
            createdBy: senderId,
        });
        tx.set(platformLedgerRef, {
            ownerType: "platform",
            ownerId: "yohpal",
            entryType: "platform_fee",
            direction: "credit",
            referenceType: "paid_message",
            referenceId: paidMessageRef.id,
            amount: platformFee,
            currency: input.currency,
            createdAt: firestore_1.FieldValue.serverTimestamp(),
            createdBy: senderId,
        });
        tx.set(idempotencyRef, {
            key: input.idempotencyKey,
            operation: "paid_message",
            referenceId: paidMessageRef.id,
            createdAt: firestore_1.FieldValue.serverTimestamp(),
            createdBy: senderId,
        });
        return {
            duplicate: false,
            referenceId: paidMessageRef.id,
        };
    });
    return (0, respond_1.ok)(res, {
        accepted: true,
        duplicate: result.duplicate,
        paidMessageId: result.referenceId,
    }, result.duplicate ? 200 : 201);
});
exports.revenueRouter.get("/wallets/:creatorId", requireAuth_1.requireAuth, async (req, res) => {
    const requester = req.user?.uid;
    const creatorId = req.params.creatorId;
    if (!requester)
        return (0, respond_1.fail)(res, 401, "missing_user", "Missing user.");
    if (requester !== creatorId && req.user?.admin !== true) {
        return (0, respond_1.fail)(res, 403, "forbidden", "You cannot view this wallet.");
    }
    const snapshot = await db
        .collection("ledgerEntries")
        .where("ownerType", "==", "creator")
        .where("ownerId", "==", creatorId)
        .limit(3000)
        .get();
    let totalCredits = 0;
    let totalDebits = 0;
    let giftRevenue = 0;
    let paidMessageRevenue = 0;
    let currency = "KES";
    for (const doc of snapshot.docs) {
        const item = doc.data();
        const amount = typeof item.amount === "number" ? item.amount : 0;
        currency = String(item.currency ?? currency);
        if (item.direction === "credit")
            totalCredits += amount;
        if (item.direction === "debit")
            totalDebits += amount;
        if (item.entryType === "gift_credit")
            giftRevenue += amount;
        if (item.entryType === "paid_message_credit") {
            paidMessageRevenue += amount;
        }
    }
    return (0, respond_1.ok)(res, {
        creatorId,
        currency,
        totalCredits,
        totalDebits,
        availableBalance: Number((totalCredits - totalDebits).toFixed(2)),
        pendingBalance: 0,
        giftRevenue,
        paidMessageRevenue,
    });
});
exports.revenueRouter.get("/ledger/:creatorId", requireAuth_1.requireAuth, async (req, res) => {
    const requester = req.user?.uid;
    const creatorId = req.params.creatorId;
    if (!requester)
        return (0, respond_1.fail)(res, 401, "missing_user", "Missing user.");
    if (requester !== creatorId && req.user?.admin !== true) {
        return (0, respond_1.fail)(res, 403, "forbidden", "You cannot view this ledger.");
    }
    const snapshot = await db
        .collection("ledgerEntries")
        .where("ownerType", "==", "creator")
        .where("ownerId", "==", creatorId)
        .orderBy("createdAt", "desc")
        .limit(100)
        .get();
    return (0, respond_1.ok)(res, {
        entries: snapshot.docs.map((doc) => ({
            id: doc.id,
            ...doc.data(),
        })),
    });
});
//# sourceMappingURL=revenue.router.js.map