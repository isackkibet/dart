"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.authRouter = void 0;
const express_1 = require("express");
const auth_1 = require("firebase-admin/auth");
const requireAuth_1 = require("../../core/http/requireAuth");
const requireAdmin_1 = require("../../core/http/requireAdmin");
const respond_1 = require("../../core/http/respond");
const auth_schema_1 = require("./auth.schema");
exports.authRouter = (0, express_1.Router)();
exports.authRouter.get("/me", requireAuth_1.requireAuth, async (req, res) => {
    return (0, respond_1.ok)(res, {
        user: req.user,
    });
});
exports.authRouter.post("/assign-claims", requireAuth_1.requireAuth, requireAdmin_1.requireAdmin, async (req, res) => {
    const parsed = auth_schema_1.AssignClaimsSchema.safeParse(req.body);
    if (!parsed.success) {
        return (0, respond_1.fail)(res, 400, "invalid_claims_payload", "Invalid custom claims payload.", parsed.error.flatten());
    }
    const input = parsed.data;
    const claims = {
        role: input.role,
        creator: input.creator ?? input.role === "creator",
        admin: input.admin ?? input.role === "admin",
        moderator: input.role === "moderator",
        operator: input.role === "operator",
        approver: input.role === "approver",
        finance: input.role === "finance",
    };
    await (0, auth_1.getAuth)().setCustomUserClaims(input.uid, claims);
    return (0, respond_1.ok)(res, {
        uid: input.uid,
        claims,
        message: "Custom claims assigned. User must refresh token or re-login.",
    });
});
//# sourceMappingURL=auth.router.js.map