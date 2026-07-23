"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.UpdateJobStatusSchema = exports.DispatchJobSchema = exports.PipelineConfigSchema = exports.JobTypes = void 0;
const zod_1 = require("zod");
exports.JobTypes = [
    "transcode",
    "thumbnail",
    "clip_export",
    "replay_package",
    "distribute",
];
exports.PipelineConfigSchema = zod_1.z.object({
    outputFormat: zod_1.z.enum(["mp4", "webm", "hls"]).default("mp4"),
    resolution: zod_1.z.enum(["1080p", "720p", "480p", "360p"]).default("720p"),
    videoBitrate: zod_1.z.number().int().min(100).max(20000).default(2500),
    fps: zod_1.z.number().int().min(15).max(60).default(30),
    audioBitrate: zod_1.z.number().int().min(64).max(320).default(128),
    watermarkEnabled: zod_1.z.boolean().default(false),
    watermarkRef: zod_1.z.string().optional(),
});
exports.DispatchJobSchema = zod_1.z.object({
    jobType: zod_1.z.enum(exports.JobTypes),
    inputRef: zod_1.z.string().min(1, "inputRef is required."),
    sessionId: zod_1.z.string().optional(),
    clipSegmentId: zod_1.z.string().optional(),
    config: exports.PipelineConfigSchema.optional(),
    priority: zod_1.z.number().int().min(1).max(10).default(5),
    maxRetries: zod_1.z.number().int().min(0).max(5).default(3),
});
exports.UpdateJobStatusSchema = zod_1.z.object({
    status: zod_1.z.enum(["queued", "processing", "completed", "failed", "cancelled"]),
    progressPercent: zod_1.z.number().min(0).max(100).optional(),
    errorMessage: zod_1.z.string().optional(),
    outputRef: zod_1.z.string().optional(),
});
//# sourceMappingURL=mediaPipeline.schema.js.map