import { z } from "zod";

export const UpsertRoutePolicySchema = z.object({
  sessionId: z.string().min(1),
  destinationId: z.string().min(1),
  mode: z.enum(["full", "teaser", "hybrid"]),
  enabled: z.boolean().default(true),
  delaySeconds: z.number().int().min(0).max(120).default(20),
  previewWindowSeconds: z.number().int().min(5).max(600).default(60),
  ctaOverlayEnabled: z.boolean().default(true),
  ctaText: z.string().min(1).max(180).default("Join the full live on YohPal"),
  ctaUrl: z.string().url().optional().default("https://yohpal.live"),
  watermarkEnabled: z.boolean().default(true),
  blurAfterPreview: z.boolean().default(false),
});

export const MockIngestHeartbeatSchema = z.object({
  sessionId: z.string().min(1),
  bitrateKbps: z.number().int().min(0).default(4200),
  latencyMs: z.number().int().min(0).default(850),
  activeDestinations: z.number().int().min(0).default(1),
  failedDestinations: z.number().int().min(0).default(0),
});
