"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ClosePollSchema = exports.CastVoteSchema = exports.CreatePollSchema = void 0;
const zod_1 = require("zod");
const PollOptionInputSchema = zod_1.z.string().min(1).max(80);
exports.CreatePollSchema = zod_1.z.object({
    question: zod_1.z.string().min(1, "Question is required.").max(200),
    options: zod_1.z
        .array(PollOptionInputSchema)
        .min(2, "At least 2 options required.")
        .max(4, "Maximum 4 options allowed."),
    durationSeconds: zod_1.z.number().int().min(15).max(120).default(30),
    allowMultipleVotes: zod_1.z.boolean().default(false),
});
exports.CastVoteSchema = zod_1.z.object({
    sessionId: zod_1.z.string().min(1, "sessionId is required."),
    optionIds: zod_1.z
        .array(zod_1.z.string().min(1))
        .min(1, "At least one option must be selected.")
        .max(4),
});
exports.ClosePollSchema = zod_1.z.object({
    pollId: zod_1.z.string().min(1),
});
//# sourceMappingURL=polls.schema.js.map