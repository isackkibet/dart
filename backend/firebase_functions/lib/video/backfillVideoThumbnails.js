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
exports.backfillVideoThumbnails = void 0;
const https_1 = require("firebase-functions/v2/https");
const admin = __importStar(require("firebase-admin"));
const extractVideoThumbnail_1 = require("./extractVideoThumbnail");
const db = admin.firestore();
exports.backfillVideoThumbnails = (0, https_1.onCall)({ region: 'europe-west2', timeoutSeconds: 540, memory: '1GiB' }, async (request) => {
    if (!request.auth?.token.admin) {
        throw new https_1.HttpsError('permission-denied', 'Admin only');
    }
    const snap = await db
        .collection('videos')
        .where('processingStatus', '==', 'ready')
        .where('playbackReady', '==', true)
        .get();
    let updated = 0;
    let skipped = 0;
    let failed = 0;
    for (const doc of snap.docs) {
        const data = doc.data();
        if (data.thumbnailUrl) {
            skipped++;
            continue;
        }
        try {
            const videoPath = data.rawPath || data.storagePath || data.originalStoragePath;
            if (!videoPath) {
                skipped++;
                continue;
            }
            const thumbnailUrl = await (0, extractVideoThumbnail_1.extractThumbnailFromVideo)({
                videoPath,
                outputPath: `video-thumbnails/${doc.id}/thumbnail.jpg`,
            });
            await doc.ref.set({ thumbnailUrl }, { merge: true });
            updated++;
        }
        catch (_) {
            failed++;
        }
    }
    return { ok: true, updated, skipped, failed };
});
