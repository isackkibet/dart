"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.UpsertCreatorProfileSchema = void 0;
const zod_1 = require("zod");
exports.UpsertCreatorProfileSchema = zod_1.z.object({
    displayName: zod_1.z.string().min(2).max(120),
    handle: zod_1.z
        .string()
        .min(2)
        .max(40)
        .regex(/^[a-zA-Z0-9_\.]+$/),
    category: zod_1.z.string().max(80).optional().default(""),
    bio: zod_1.z.string().max(500).optional().default(""),
});
//# sourceMappingURL=creatorProfile.schema.js.map