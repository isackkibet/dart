"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AssignClaimsSchema = void 0;
const zod_1 = require("zod");
exports.AssignClaimsSchema = zod_1.z.object({
    uid: zod_1.z.string().min(1),
    role: zod_1.z.enum([
        "viewer",
        "creator",
        "moderator",
        "operator",
        "approver",
        "finance",
        "admin",
    ]),
    creator: zod_1.z.boolean().optional(),
    admin: zod_1.z.boolean().optional(),
});
//# sourceMappingURL=auth.schema.js.map