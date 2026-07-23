"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ProposeDecisionSchema = exports.CreateAutonomyPolicySchema = void 0;
const zod_1 = require("zod");
exports.CreateAutonomyPolicySchema = zod_1.z.object({
    domain: zod_1.z.enum(["growth", "monetisation", "scaling", "moderation"]),
    name: zod_1.z.string().min(2).max(120),
    description: zod_1.z.string().max(500).default(""),
    mode: zod_1.z.enum(["inform", "assisted", "controlled", "disabled"]).default("assisted"),
    enabled: zod_1.z.boolean().default(true),
    maxActionsPerHour: zod_1.z.number().int().min(0).max(60).default(3),
    requiresApproval: zod_1.z.boolean().default(true),
});
exports.ProposeDecisionSchema = zod_1.z.object({
    creatorId: zod_1.z.string().min(1),
    sessionId: zod_1.z.string().optional().nullable(),
    domain: zod_1.z.enum(["growth", "monetisation", "scaling", "moderation"]),
    recommendation: zod_1.z.string().min(2).max(500),
    reason: zod_1.z.string().min(2).max(1000),
    confidence: zod_1.z.number().min(0).max(1),
    actionType: zod_1.z.string().min(1).max(100),
    payload: zod_1.z.record(zod_1.z.unknown()).default({}),
});
//# sourceMappingURL=autonomy.schema.js.map