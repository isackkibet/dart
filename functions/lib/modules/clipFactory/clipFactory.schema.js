"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.UpdateClipStatusSchema = exports.GenerateClipsSchema = void 0;
const zod_1 = require("zod");
exports.GenerateClipsSchema = zod_1.z.object({
    maxClips: zod_1.z.number().int().min(1).max(20).default(10),
    minDurationSeconds: zod_1.z.number().int().min(15).max(120).default(20),
    maxDurationSeconds: zod_1.z.number().int().min(30).max(600).default(90),
});
exports.UpdateClipStatusSchema = zod_1.z.object({
    status: zod_1.z.enum([
        "approved",
        "rejected",
        "exporting",
        "exported",
        "distributed",
    ]),
});
//# sourceMappingURL=clipFactory.schema.js.map