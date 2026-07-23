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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.extractThumbnailFromVideo = extractThumbnailFromVideo;
const admin = __importStar(require("firebase-admin"));
const path = __importStar(require("path"));
const os = __importStar(require("os"));
const fs = __importStar(require("fs"));
const child_process_1 = require("child_process");
const ffmpeg_1 = __importDefault(require("@ffmpeg-installer/ffmpeg"));
const bucket = admin.storage().bucket();
async function extractThumbnailFromVideo(params) {
    const inputFile = path.join(os.tmpdir(), `input-${Date.now()}.mp4`);
    const outputFile = path.join(os.tmpdir(), `thumb-${Date.now()}.jpg`);
    await bucket.file(params.videoPath).download({ destination: inputFile });
    await new Promise((resolve, reject) => {
        const ffmpeg = (0, child_process_1.spawn)(ffmpeg_1.default.path, [
            '-y', '-ss', '0.5', '-i', inputFile,
            '-frames:v', '1', '-q:v', '2', outputFile,
        ]);
        ffmpeg.on('error', reject);
        ffmpeg.on('close', (code) => {
            if (code === 0)
                resolve();
            else
                reject(new Error(`FFmpeg thumbnail extraction failed: ${code}`));
        });
    });
    await bucket.upload(outputFile, {
        destination: params.outputPath,
        metadata: {
            contentType: 'image/jpeg',
            cacheControl: 'public,max-age=31536000,immutable',
        },
    });
    fs.unlinkSync(inputFile);
    fs.unlinkSync(outputFile);
    return `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(params.outputPath)}?alt=media`;
}
