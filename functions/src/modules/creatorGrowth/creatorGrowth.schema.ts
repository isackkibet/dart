import { z } from "zod";

export const GenerateRecommendationsSchema = z.object({
  sessionId: z.string().optional().nullable(),
});
