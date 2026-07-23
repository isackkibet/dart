"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.CreatePaidMessageSchema = exports.SendGiftSchema = void 0;
const zod_1 = require("zod");
exports.SendGiftSchema = zod_1.z.object({
    sessionId: zod_1.z.string().min(1),
    creatorId: zod_1.z.string().min(1),
    giftType: zod_1.z.string().min(1).max(80),
    amount: zod_1.z.number().positive(),
    currency: zod_1.z.string().min(3).max(3).default("KES"),
    idempotencyKey: zod_1.z.string().min(10).max(200),
});
exports.CreatePaidMessageSchema = zod_1.z.object({
    sessionId: zod_1.z.string().min(1),
    creatorId: zod_1.z.string().min(1),
    message: zod_1.z.string().min(1).max(500),
    amount: zod_1.z.number().positive(),
    currency: zod_1.z.string().min(3).max(3).default("KES"),
    idempotencyKey: zod_1.z.string().min(10).max(200),
});
//# sourceMappingURL=revenue.schema.js.map