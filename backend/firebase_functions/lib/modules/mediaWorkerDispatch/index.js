"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.retryMediaWorkerJob = exports.mediaWorkerDispatch = void 0;
const functions = __importStar(require("firebase-functions/v2/https"));
const admin = __importStar(require("firebase-admin"));
exports.mediaWorkerDispatch = functions.onCall(async (request) => {
    if (!request.auth) {
        throw new functions.HttpsError("unauthenticated", "Authentication required.");
    }
    const { sessionId, creatorId, jobType, inputUrl } = request.data || {};
    if (!sessionId || !creatorId || !jobType || !inputUrl) {
        throw new functions.HttpsError("invalid-argument", "Missing required job fields.");
    }
    if (request.auth.uid !== creatorId) {
        throw new functions.HttpsError("permission-denied", "Creator mismatch.");
    }
    const ref = admin.firestore().collection("mediaWorkerJobs").doc();
    await ref.set({
        sessionId,
        creatorId,
        jobType,
        inputUrl,
        status: "queued",
        retryCount: 0,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return {
        jobId: ref.id,
        status: "queued",
    };
});
exports.retryMediaWorkerJob = functions.onCall(async (request) => {
    if (!request.auth) {
        throw new functions.HttpsError("unauthenticated", "Authentication required.");
    }
    const { jobId } = request.data || {};
    if (!jobId) {
        throw new functions.HttpsError("invalid-argument", "jobId is required.");
    }
    const ref = admin.firestore().collection("mediaWorkerJobs").doc(jobId);
    const snap = await ref.get();
    if (!snap.exists) {
        throw new functions.HttpsError("not-found", "Job not found.");
    }
    const job = snap.data();
    if (job.creatorId !== request.auth.uid) {
        throw new functions.HttpsError("permission-denied", "Not job owner.");
    }
    await ref.update({
        status: "queued",
        retryCount: admin.firestore.FieldValue.increment(1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return {
        jobId,
        status: "queued",
    };
});
