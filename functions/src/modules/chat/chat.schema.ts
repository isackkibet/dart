import { z } from "zod";

export const SendMessageSchema = z.object({
  text: z
    .string()
    .min(1, "Message cannot be empty.")
    .max(300, "Message must be 300 characters or less."),
  type: z.enum(["text", "gift", "system"]).default("text"),
});

export const PinMessageSchema = z.object({
  messageId: z.string().min(1, "messageId is required."),
});

export const MuteUserSchema = z.object({
  userId: z.string().min(1, "userId is required."),
  durationSeconds: z.number().int().min(60).max(604800).default(86400),
});
