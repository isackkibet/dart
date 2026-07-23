import { z } from "zod";

export const UpsertCreatorProfileSchema = z.object({
  displayName: z.string().min(2).max(120),
  handle: z
    .string()
    .min(2)
    .max(40)
    .regex(/^[a-zA-Z0-9_\.]+$/),
  category: z.string().max(80).optional().default(""),
  bio: z.string().max(500).optional().default(""),
});

export type UpsertCreatorProfileInput = z.infer<
  typeof UpsertCreatorProfileSchema
>;
