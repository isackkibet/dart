import { z } from "zod";

const PollOptionInputSchema = z.string().min(1).max(80);

export const CreatePollSchema = z.object({
  question: z.string().min(1, "Question is required.").max(200),
  options: z
    .array(PollOptionInputSchema)
    .min(2, "At least 2 options required.")
    .max(4, "Maximum 4 options allowed."),
  durationSeconds: z.number().int().min(15).max(120).default(30),
  allowMultipleVotes: z.boolean().default(false),
});

export const CastVoteSchema = z.object({
  sessionId: z.string().min(1, "sessionId is required."),
  optionIds: z
    .array(z.string().min(1))
    .min(1, "At least one option must be selected.")
    .max(4),
});

export const ClosePollSchema = z.object({
  pollId: z.string().min(1),
});
