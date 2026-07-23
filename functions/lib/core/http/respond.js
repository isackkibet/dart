"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ok = ok;
exports.fail = fail;
function ok(res, data, statusCode = 200) {
    return res.status(statusCode).json({
        success: true,
        data,
    });
}
function fail(res, statusCode, code, message, error) {
    console.error(`[${code}] ${message}`, error);
    return res.status(statusCode).json({
        success: false,
        error: {
            code,
            message,
            ...(error && process.env.NODE_ENV === "development" && { details: error }),
        },
    });
}
//# sourceMappingURL=respond.js.map