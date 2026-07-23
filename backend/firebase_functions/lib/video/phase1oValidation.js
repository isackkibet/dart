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
exports.validateUltraLowLatencyFeed1O = void 0;
const https_1 = require("firebase-functions/v2/https");
const admin = __importStar(require("firebase-admin"));
const db = admin.firestore();
exports.validateUltraLowLatencyFeed1O = (0, https_1.onCall)({ region: 'europe-west2', timeoutSeconds: 540, memory: '512MiB' }, async (request) => {
    if (!request.auth?.token.admin) {
        throw new https_1.HttpsError('permission-denied', 'Admin only');
    }
    const eligibleSnap = await db
        .collection('videos')
        .where('visibility', '==', 'public')
        .where('playbackReady', '==', true)
        .where('processingStatus', '==', 'ready')
        .where('broken', '==', false)
        .get();
    let missingThumbnail = 0;
    let missingHls = 0;
    for (const doc of eligibleSnap.docs) {
        const data = doc.data();
        if (!data.thumbnailUrl)
            missingThumbnail++;
        if (!data.hlsLowUrl || !data.hlsStandardUrl || !data.hlsHdUrl) {
            missingHls++;
        }
    }
    const diagnosticsSnap = await db
        .collection('videoPlaybackDiagnostics')
        .orderBy('createdAt', 'desc')
        .limit(100)
        .get();
    const diagnostics = diagnosticsSnap.docs.map((doc) => doc.data());
    const validLatencySamples = diagnostics
        .map((item) => Number(item.timeToFirstFrameMs ?? 0))
        .filter((value) => value > 0 && value < 9999);
    const averageTimeToFirstFrameMs = validLatencySamples.length === 0
        ? null
        : Math.round(validLatencySamples.reduce((sum, value) => sum + value, 0) /
            validLatencySamples.length);
    return {
        ok: missingThumbnail === 0 && missingHls === 0,
        feedEligibleVideos: eligibleSnap.size,
        missingThumbnail,
        missingHls,
        diagnosticsChecked: diagnosticsSnap.size,
        averageTimeToFirstFrameMs,
        readyForPilot: missingThumbnail === 0 &&
            missingHls === 0 &&
            averageTimeToFirstFrameMs !== null &&
            averageTimeToFirstFrameMs <= 500,
    };
});
