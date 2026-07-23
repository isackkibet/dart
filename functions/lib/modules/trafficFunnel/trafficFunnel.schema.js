"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.CaptureConversionSchema = exports.CreateTrafficCampaignSchema = exports.CaptureTrafficEventSchema = void 0;
const zod_1 = require("zod");
exports.CaptureTrafficEventSchema = zod_1.z.object({
    sessionId: zod_1.z.string().min(1),
    creatorId: zod_1.z.string().min(1),
    sourcePlatform: zod_1.z.string().min(1).max(60),
    eventType: zod_1.z.enum([
        "view",
        "join",
        "follow",
        "tip",
        "share",
        "purchase",
        "vip_join",
    ]),
    anonymousId: zod_1.z.string().min(1),
    userId: zod_1.z.string().optional().nullable(),
    campaignCode: zod_1.z.string().optional().nullable(),
    campaignId: zod_1.z.string().optional().nullable(),
    clipId: zod_1.z.string().optional().nullable(),
});
exports.CreateTrafficCampaignSchema = zod_1.z.object({
    sessionId: zod_1.z.string().min(1),
    name: zod_1.z.string().min(2).max(120),
    sourcePlatform: zod_1.z.string().min(1).max(60),
});
exports.CaptureConversionSchema = zod_1.z.object({
    sessionId: zod_1.z.string().min(1),
    creatorId: zod_1.z.string().min(1),
    sourcePlatform: zod_1.z.string().min(1).max(60),
    conversionType: zod_1.z.enum([
        "signup",
        "follow",
        "tip",
        "subscribe",
        "purchase",
        "vip_join",
        "share",
    ]),
    valueAmount: zod_1.z.number().min(0).default(0),
    currency: zod_1.z.string().min(3).max(3).default("KES"),
    userId: zod_1.z.string().optional().nullable(),
    anonymousId: zod_1.z.string().min(1),
    campaignCode: zod_1.z.string().optional().nullable(),
});
//# sourceMappingURL=trafficFunnel.schema.js.map