"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.HealthCheckSchema = exports.DisconnectConnectorSchema = exports.GetOAuthUrlSchema = exports.SupportedPlatforms = void 0;
const zod_1 = require("zod");
exports.SupportedPlatforms = [
    "youtube",
    "tiktok",
    "instagram",
    "facebook",
    "x",
    "linkedin",
    "twitch",
    "kick",
];
exports.GetOAuthUrlSchema = zod_1.z.object({
    platform: zod_1.z.enum(exports.SupportedPlatforms),
});
exports.DisconnectConnectorSchema = zod_1.z.object({
    connectorId: zod_1.z.string().min(1, "connectorId is required."),
});
exports.HealthCheckSchema = zod_1.z.object({
    connectorId: zod_1.z.string().min(1, "connectorId is required."),
});
//# sourceMappingURL=socialConnector.schema.js.map