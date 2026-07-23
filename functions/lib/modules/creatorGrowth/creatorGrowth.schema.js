"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.GenerateRecommendationsSchema = void 0;
const zod_1 = require("zod");
exports.GenerateRecommendationsSchema = zod_1.z.object({
    sessionId: zod_1.z.string().optional().nullable(),
});
//# sourceMappingURL=creatorGrowth.schema.js.map