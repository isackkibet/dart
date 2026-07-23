import { z } from "zod";

export const CreateAutonomyPolicySchema = z.object({
  domain: z.enum(["growth", "monetisation", "scaling", "moderation"]),
  name: z.string().min(2).max(120),
  description: z.string().max(500).default(""),
  mode: z.enum(["inform", "assisted", "controlled", "disabled"]).default("assisted"),
  enabled: z.boolean().default(true),
  maxActionsPerHour: z.number().int().min(0).max(60).default(3),
  requiresApproval: z.boolean().default(true),
});

export const ProposeDecisionSchema = z.object({
  creatorId: z.string().min(1),
  sessionId: z.string().optional().nullable(),
  domain: z.enum(["growth", "monetisation", "scaling", "moderation"]),
  recommendation: z.string().min(2).max(500),
  reason: z.string().min(2).max(1000),
  confidence: z.number().min(0).max(1),
  actionType: z.string().min(1).max(100),
  payload: z.record(z.unknown()).default({}),
});
