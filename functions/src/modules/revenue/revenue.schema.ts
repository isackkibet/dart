import { z } from "zod";

export const SendGiftSchema = z.object({
  sessionId: z.string().min(1),
  creatorId: z.string().min(1),
  giftType: z.string().min(1).max(80),
  amount: z.number().positive(),
  currency: z.string().min(3).max(3).default("KES"),
  idempotencyKey: z.string().min(10).max(200),
});

export const CreatePaidMessageSchema = z.object({
  sessionId: z.string().min(1),
  creatorId: z.string().min(1),
  message: z.string().min(1).max(500),
  amount: z.number().positive(),
  currency: z.string().min(3).max(3).default("KES"),
  idempotencyKey: z.string().min(10).max(200),
});
