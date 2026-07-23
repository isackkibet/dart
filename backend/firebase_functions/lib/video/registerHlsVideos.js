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
exports.registerHlsVideos = void 0;
const https_1 = require("firebase-functions/v2/https");
const admin = __importStar(require("firebase-admin"));
const firebaseAdmin_1 = require("../shared/firebaseAdmin");
const BUCKET = 'yohlab.firebasestorage.app';
const HLS_PREFIX = 'videos-hls/';
const MASTER_NAMES = ['master.m3u8', 'index.m3u8', 'playlist.m3u8'];
function publicUrl(filePath) {
    return `https://firebasestorage.googleapis.com/v0/b/${BUCKET}/o/${encodeURIComponent(filePath)}?alt=media`;
}
exports.registerHlsVideos = (0, https_1.onCall)({ region: 'europe-west2', timeoutSeconds: 300, memory: '512MiB' }, async () => {
    const bucket = admin.storage().bucket(BUCKET);
    const [files] = await bucket.getFiles({ prefix: HLS_PREFIX });
    const masters = files.filter(f => MASTER_NAMES.some(name => f.name.endsWith(`/${name}`) || f.name === name));
    const results = [];
    for (const file of masters) {
        const parts = file.name.split('/').filter(Boolean);
        // parts[0] = 'videos-hls'
        // two possible layouts:
        //   videos-hls/{videoId}/master.m3u8          → parts.length == 3
        //   videos-hls/{userId}/{videoId}/master.m3u8 → parts.length == 4
        const videoId = parts.length >= 4 ? parts[2] : parts[1];
        const hlsUrl = publicUrl(file.name);
        const ref = firebaseAdmin_1.db.collection('videos').doc(videoId);
        const snap = await ref.get();
        if (!snap.exists) {
            await ref.set({
                id: videoId,
                ownerId: '',
                userId: '',
                title: videoId,
                description: '',
                hlsUrl,
                hlsManifestUrl: hlsUrl,
                videoUrl: hlsUrl,
                thumbnailUrl: '',
                rawPath: file.name,
                status: 'live',
                visibility: 'public',
                views: 0,
                likes: 0,
                engagementScore: 0,
                broken: false,
                tags: [],
                createdAt: firebaseAdmin_1.FieldValue.serverTimestamp(),
                updatedAt: firebaseAdmin_1.FieldValue.serverTimestamp(),
            });
            results.push({ path: file.name, videoId, action: 'created' });
        }
        else {
            const data = snap.data();
            if (!data.hlsUrl) {
                await ref.update({
                    hlsUrl,
                    hlsManifestUrl: hlsUrl,
                    videoUrl: hlsUrl,
                    status: 'live',
                    updatedAt: firebaseAdmin_1.FieldValue.serverTimestamp(),
                });
                results.push({ path: file.name, videoId, action: 'updated' });
            }
            else {
                results.push({ path: file.name, videoId, action: 'skipped' });
            }
        }
    }
    return { scanned: masters.length, results };
});
