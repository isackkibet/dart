import { z } from "zod";

export const GenerateClipsSchema = z.object({
  maxClips: z.number().int().min(1).max(20).default(10),
  minDurationSeconds: z.number().int().min(15).max(120).default(20),
  maxDurationSeconds: z.number().int().min(30).max(600).default(90),
});

export const UpdateClipStatusSchema = z.object({
  status: z.enum([
    "approved",
    "rejected",
    "exporting",
    "exported",
    "distributed",
  ]),
});
