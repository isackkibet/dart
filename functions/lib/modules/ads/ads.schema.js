"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.RecordClickSchema = exports.RecordImpressionSchema = exports.UpdateCampaignSchema = exports.CreateCampaignSchema = void 0;
const zod_1 = require("zod");
const CreativeTypes = ["banner", "overlay", "sponsored_poll"];
exports.CreateCampaignSchema = zod_1.z.object({
    title: zod_1.z.string().min(1, "Title is required.").max(120),
    budgetCents: zod_1.z.number().int().min(1000, "Minimum budget is $10."),
    cpmCents: zod_1.z.number().int().min(50, "Minimum CPM is $0.50.").max(100000),
    creativeType: zod_1.z.enum(CreativeTypes),
    creativeRef: zod_1.z.string().min(1, "Creative content is required.").max(500),
    ctaLabel: zod_1.z.string().min(1).max(40).default("Learn More"),
    ctaUrl: zod_1.z.string().url("ctaUrl must be a valid URL."),
    targetingTags: zod_1.z.array(zod_1.z.string().min(1).max(30)).max(10).default([]),
    startDate: zod_1.z.string().datetime().optional(),
    endDate: zod_1.z.string().datetime().optional(),
});
exports.UpdateCampaignSchema = zod_1.z.object({
    title: zod_1.z.string().min(1).max(120).optional(),
    budgetCents: zod_1.z.number().int().min(1000).optional(),
    cpmCents: zod_1.z.number().int().min(50).optional(),
    creativeRef: zod_1.z.string().min(1).max(500).optional(),
    ctaLabel: zod_1.z.string().min(1).max(40).optional(),
    ctaUrl: zod_1.z.string().url().optional(),
    targetingTags: zod_1.z.array(zod_1.z.string().min(1).max(30)).max(10).optional(),
    startDate: zod_1.z.string().datetime().optional(),
    endDate: zod_1.z.string().datetime().optional(),
});
exports.RecordImpressionSchema = zod_1.z.object({
    placementId: zod_1.z.string().min(1),
    impressionToken: zod_1.z.string().min(1),
    sessionId: zod_1.z.string().min(1),
});
exports.RecordClickSchema = zod_1.z.object({
    placementId: zod_1.z.string().min(1),
    impressionToken: zod_1.z.string().min(1),
    sessionId: zod_1.z.string().min(1),
});
//# sourceMappingURL=ads.schema.js.map