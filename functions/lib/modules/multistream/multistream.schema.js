"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.CreateDestinationSchema = exports.UpdateLiveSessionStatusSchema = exports.CreateLiveSessionSchema = void 0;
const zod_1 = require("zod");
exports.CreateLiveSessionSchema = zod_1.z.object({
    title: zod_1.z.string().min(2).max(140),
    description: zod_1.z.string().max(1000).optional().default(""),
    category: zod_1.z.string().max(80).optional().default("creator"),
    streamMode: zod_1.z.enum(["full", "teaser", "hybrid"]).default("teaser"),
    scheduledAt: zod_1.z.string().datetime().optional(),
});
exports.UpdateLiveSessionStatusSchema = zod_1.z.object({
    status: zod_1.z.enum([
        "draft",
        "scheduled",
        "preparing",
        "live",
        "paused",
        "ended",
        "failed",
    ]),
});
exports.CreateDestinationSchema = zod_1.z.object({
    platform: zod_1.z.enum([
        "youtube",
        "facebook",
        "tiktok",
        "instagram",
        "x",
        "twitch",
    ]),
    destinationName: zod_1.z.string().min(1).max(120),
    streamMode: zod_1.z.enum(["full", "teaser", "hybrid"]).default("teaser"),
    ctaEnabled: zod_1.z.boolean().default(true),
    delaySeconds: zod_1.z.number().int().min(0).max(120).default(20),
});
//# sourceMappingURL=multistream.schema.js.map