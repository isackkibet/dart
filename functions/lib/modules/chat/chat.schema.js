"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.MuteUserSchema = exports.PinMessageSchema = exports.SendMessageSchema = void 0;
const zod_1 = require("zod");
exports.SendMessageSchema = zod_1.z.object({
    text: zod_1.z
        .string()
        .min(1, "Message cannot be empty.")
        .max(300, "Message must be 300 characters or less."),
    type: zod_1.z.enum(["text", "gift", "system"]).default("text"),
});
exports.PinMessageSchema = zod_1.z.object({
    messageId: zod_1.z.string().min(1, "messageId is required."),
});
exports.MuteUserSchema = zod_1.z.object({
    userId: zod_1.z.string().min(1, "userId is required."),
    durationSeconds: zod_1.z.number().int().min(60).max(604800).default(86400),
});
//# sourceMappingURL=chat.schema.js.map