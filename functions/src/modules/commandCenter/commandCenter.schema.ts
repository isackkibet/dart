import { z } from "zod";

export const CreateIncidentSchema = z.object({
  title: z.string().min(2).max(160),
  description: z.string().min(1).max(1000),
  severity: z.enum(["p0", "p1", "p2", "p3"]).default("p3"),
  affectedService: z.string().min(1).max(120),
});

export const UpdateIncidentSchema = z.object({
  status: z.enum(["open", "investigating", "resolved", "ignored"]),
});

export const SetSafeModeSchema = z.object({
  enabled: z.boolean(),
  reason: z.string().max(500).default(""),
});

export const CreateAutoResponseRuleSchema = z.object({
  name: z.string().min(2).max(160),
  eventType: z.string().min(1).max(100),
  conditionMetric: z.string().min(1).max(100),
  conditionOperator: z.enum([">", ">=", "<", "<=", "=="]).default(">"),
  conditionValue: z.number(),
  actionType: z.enum([
    "create_incident",
    "enable_safe_mode",
    "disable_feature",
    "notify_admin",
    "mark_degraded",
  ]),
  enabled: z.boolean().default(true),
  requiresApproval: z.boolean().default(true),
});
