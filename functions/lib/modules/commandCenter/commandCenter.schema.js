"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.CreateAutoResponseRuleSchema = exports.SetSafeModeSchema = exports.UpdateIncidentSchema = exports.CreateIncidentSchema = void 0;
const zod_1 = require("zod");
exports.CreateIncidentSchema = zod_1.z.object({
    title: zod_1.z.string().min(2).max(160),
    description: zod_1.z.string().min(1).max(1000),
    severity: zod_1.z.enum(["p0", "p1", "p2", "p3"]).default("p3"),
    affectedService: zod_1.z.string().min(1).max(120),
});
exports.UpdateIncidentSchema = zod_1.z.object({
    status: zod_1.z.enum(["open", "investigating", "resolved", "ignored"]),
});
exports.SetSafeModeSchema = zod_1.z.object({
    enabled: zod_1.z.boolean(),
    reason: zod_1.z.string().max(500).default(""),
});
exports.CreateAutoResponseRuleSchema = zod_1.z.object({
    name: zod_1.z.string().min(2).max(160),
    eventType: zod_1.z.string().min(1).max(100),
    conditionMetric: zod_1.z.string().min(1).max(100),
    conditionOperator: zod_1.z.enum([">", ">=", "<", "<=", "=="]).default(">"),
    conditionValue: zod_1.z.number(),
    actionType: zod_1.z.enum([
        "create_incident",
        "enable_safe_mode",
        "disable_feature",
        "notify_admin",
        "mark_degraded",
    ]),
    enabled: zod_1.z.boolean().default(true),
    requiresApproval: zod_1.z.boolean().default(true),
});
//# sourceMappingURL=commandCenter.schema.js.map