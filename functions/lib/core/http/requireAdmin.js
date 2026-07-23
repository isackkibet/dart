"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.requireAdmin = requireAdmin;
const respond_1 = require("./respond");
function requireAdmin(req, res, next) {
    if (req.user?.admin !== true && req.user?.role !== "admin") {
        (0, respond_1.fail)(res, 403, "admin_required", "Admin access is required.");
        return;
    }
    next();
}
//# sourceMappingURL=requireAdmin.js.map