import { z } from "zod";

export const CreateLiveSessionSchema = z.object({
  title: z.string().min(2).max(140),
  description: z.string().max(1000).optional().default(""),
  category: z.string().max(80).optional().default("creator"),
  streamMode: z.enum(["full", "teaser", "hybrid"]).default("teaser"),
  scheduledAt: z.string().datetime().optional(),
});

export const UpdateLiveSessionStatusSchema = z.object({
  status: z.enum([
    "draft",
    "scheduled",
    "preparing",
    "live",
    "paused",
    "ended",
    "failed",
  ]),
});

export const CreateDestinationSchema = z.object({
  platform: z.enum([
    "youtube",
    "facebook",
    "tiktok",
    "instagram",
    "x",
    "twitch",
  ]),
  destinationName: z.string().min(1).max(120),
  streamMode: z.enum(["full", "teaser", "hybrid"]).default("teaser"),
  ctaEnabled: z.boolean().default(true),
  delaySeconds: z.number().int().min(0).max(120).default(20),
});
