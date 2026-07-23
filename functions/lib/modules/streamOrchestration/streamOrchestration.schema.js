"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.MockIngestHeartbeatSchema = exports.UpsertRoutePolicySchema = void 0;
const zod_1 = require("zod");
exports.UpsertRoutePolicySchema = zod_1.z.object({
    sessionId: zod_1.z.string().min(1),
    destinationId: zod_1.z.string().min(1),
    mode: zod_1.z.enum(["full", "teaser", "hybrid"]),
    enabled: zod_1.z.boolean().default(true),
    delaySeconds: zod_1.z.number().int().min(0).max(120).default(20),
    previewWindowSeconds: zod_1.z.number().int().min(5).max(600).default(60),
    ctaOverlayEnabled: zod_1.z.boolean().default(true),
    ctaText: zod_1.z.string().min(1).max(180).default("Join the full live on YohPal"),
    ctaUrl: zod_1.z.string().url().optional().default("https://yohpal.live"),
    watermarkEnabled: zod_1.z.boolean().default(true),
    blurAfterPreview: zod_1.z.boolean().default(false),
});
exports.MockIngestHeartbeatSchema = zod_1.z.object({
    sessionId: zod_1.z.string().min(1),
    bitrateKbps: zod_1.z.number().int().min(0).default(4200),
    latencyMs: zod_1.z.number().int().min(0).default(850),
    activeDestinations: zod_1.z.number().int().min(0).default(1),
    failedDestinations: zod_1.z.number().int().min(0).default(0),
});
//# sourceMappingURL=streamOrchestration.schema.js.map