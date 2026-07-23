import { z } from "zod";

export const SearchQuerySchema = z.object({
  q: z
    .string()
    .min(2, "Search query must be at least 2 characters.")
    .max(100, "Search query is too long."),
  type: z.enum(["videos", "creators", "all"]).default("all"),
  limit: z
    .string()
    .optional()
    .transform((val) => {
      const num = Number(val);
      return isNaN(num) ? 10 : Math.min(Math.max(num, 1), 20);
    })
    .default("10"),
});
