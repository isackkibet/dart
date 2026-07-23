import { z } from "zod";

export const AssignClaimsSchema = z.object({
  uid: z.string().min(1),
  role: z.enum([
    "viewer",
    "creator",
    "moderator",
    "operator",
    "approver",
    "finance",
    "admin",
  ]),
  creator: z.boolean().optional(),
  admin: z.boolean().optional(),
});

export type AssignClaimsInput = z.infer<typeof AssignClaimsSchema>;
