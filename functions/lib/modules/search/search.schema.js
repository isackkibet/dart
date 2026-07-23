"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.SearchQuerySchema = void 0;
const zod_1 = require("zod");
exports.SearchQuerySchema = zod_1.z.object({
    q: zod_1.z
        .string()
        .min(2, "Search query must be at least 2 characters.")
        .max(100, "Search query is too long."),
    type: zod_1.z.enum(["videos", "creators", "all"]).default("all"),
    limit: zod_1.z
        .string()
        .optional()
        .transform((val) => {
        const num = Number(val);
        return isNaN(num) ? 10 : Math.min(Math.max(num, 1), 20);
    })
        .default("10"),
});
//# sourceMappingURL=search.schema.js.map