"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.requireAuth = requireAuth;
const auth_1 = require("firebase-admin/auth");
const respond_1 = require("./respond");
async function requireAuth(req, res, next) {
    try {
        const header = req.headers.authorization;
        if (!header?.startsWith("Bearer ")) {
            (0, respond_1.fail)(res, 401, "missing_auth", "Missing bearer token.");
            return;
        }
        const token = header.replace("Bearer ", "").trim();
        const decoded = await (0, auth_1.getAuth)().verifyIdToken(token, true);
        req.user = {
            uid: decoded.uid,
            email: decoded.email,
            role: typeof decoded.role === "string" ? decoded.role : undefined,
            admin: decoded.admin === true,
        };
        next();
    }
    catch (error) {
        (0, respond_1.fail)(res, 401, "invalid_auth", "Invalid or expired token.", error);
    }
}
//# sourceMappingURL=requireAuth.js.map