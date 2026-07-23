import { z } from "zod";

const CreativeTypes = ["banner", "overlay", "sponsored_poll"] as const;

export const CreateCampaignSchema = z.object({
  title: z.string().min(1, "Title is required.").max(120),
  budgetCents: z.number().int().min(1000, "Minimum budget is $10."),
  cpmCents: z.number().int().min(50, "Minimum CPM is $0.50.").max(100000),
  creativeType: z.enum(CreativeTypes),
  creativeRef: z.string().min(1, "Creative content is required.").max(500),
  ctaLabel: z.string().min(1).max(40).default("Learn More"),
  ctaUrl: z.string().url("ctaUrl must be a valid URL."),
  targetingTags: z.array(z.string().min(1).max(30)).max(10).default([]),
  startDate: z.string().datetime().optional(),
  endDate: z.string().datetime().optional(),
});

export const UpdateCampaignSchema = z.object({
  title: z.string().min(1).max(120).optional(),
  budgetCents: z.number().int().min(1000).optional(),
  cpmCents: z.number().int().min(50).optional(),
  creativeRef: z.string().min(1).max(500).optional(),
  ctaLabel: z.string().min(1).max(40).optional(),
  ctaUrl: z.string().url().optional(),
  targetingTags: z.array(z.string().min(1).max(30)).max(10).optional(),
  startDate: z.string().datetime().optional(),
  endDate: z.string().datetime().optional(),
});

export const RecordImpressionSchema = z.object({
  placementId: z.string().min(1),
  impressionToken: z.string().min(1),
  sessionId: z.string().min(1),
});

export const RecordClickSchema = z.object({
  placementId: z.string().min(1),
  impressionToken: z.string().min(1),
  sessionId: z.string().min(1),
});
