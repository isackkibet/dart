import { z } from "zod";

export const CaptureTrafficEventSchema = z.object({
  sessionId: z.string().min(1),
  creatorId: z.string().min(1),
  sourcePlatform: z.string().min(1).max(60),
  eventType: z.enum([
    "view",
    "join",
    "follow",
    "tip",
    "share",
    "purchase",
    "vip_join",
  ]),
  anonymousId: z.string().min(1),
  userId: z.string().optional().nullable(),
  campaignCode: z.string().optional().nullable(),
  campaignId: z.string().optional().nullable(),
  clipId: z.string().optional().nullable(),
});

export const CreateTrafficCampaignSchema = z.object({
  sessionId: z.string().min(1),
  name: z.string().min(2).max(120),
  sourcePlatform: z.string().min(1).max(60),
});

export const CaptureConversionSchema = z.object({
  sessionId: z.string().min(1),
  creatorId: z.string().min(1),
  sourcePlatform: z.string().min(1).max(60),
  conversionType: z.enum([
    "signup",
    "follow",
    "tip",
    "subscribe",
    "purchase",
    "vip_join",
    "share",
  ]),
  valueAmount: z.number().min(0).default(0),
  currency: z.string().min(3).max(3).default("KES"),
  userId: z.string().optional().nullable(),
  anonymousId: z.string().min(1),
  campaignCode: z.string().optional().nullable(),
});
