"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.api = void 0;
const admin = __importStar(require("firebase-admin"));
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const https_1 = require("firebase-functions/v2/https");
const respond_1 = require("./core/http/respond");
const auth_router_1 = require("./modules/auth/auth.router");
const creatorProfile_router_1 = require("./modules/creatorProfile/creatorProfile.router");
const multistream_router_1 = require("./modules/multistream/multistream.router");
const streamOrchestration_router_1 = require("./modules/streamOrchestration/streamOrchestration.router");
const trafficFunnel_router_1 = require("./modules/trafficFunnel/trafficFunnel.router");
const autonomy_router_1 = require("./modules/autonomy/autonomy.router");
const creatorGrowth_router_1 = require("./modules/creatorGrowth/creatorGrowth.router");
const revenue_router_1 = require("./modules/revenue/revenue.router");
const commandCenter_router_1 = require("./modules/commandCenter/commandCenter.router");
const clipFactory_router_1 = require("./modules/clipFactory/clipFactory.router");
const socialConnector_router_1 = require("./modules/socialConnector/socialConnector.router");
const mediaPipeline_router_1 = require("./modules/mediaPipeline/mediaPipeline.router");
const polls_router_1 = require("./modules/polls/polls.router");
const ads_router_1 = require("./modules/ads/ads.router");
const chat_router_1 = require("./modules/chat/chat.router");
const search_router_1 = require("./modules/search/search.router");
if (admin.apps.length === 0) {
    admin.initializeApp();
}
const app = (0, express_1.default)();
app.use((0, cors_1.default)({ origin: true }));
app.use(express_1.default.json({ limit: "2mb" }));
app.get("/health", (_req, res) => {
    return (0, respond_1.ok)(res, {
        service: "yohpal-live-functions",
        status: "healthy",
        timestamp: new Date().toISOString(),
    });
});
app.use("/auth", auth_router_1.authRouter);
app.use("/creator-profile", creatorProfile_router_1.creatorProfileRouter);
app.use("/multistream", multistream_router_1.multistreamRouter);
app.use("/stream-orchestration", streamOrchestration_router_1.streamOrchestrationRouter);
app.use("/traffic", trafficFunnel_router_1.trafficFunnelRouter);
app.use("/autonomy", autonomy_router_1.autonomyRouter);
app.use("/growth", creatorGrowth_router_1.creatorGrowthRouter);
app.use("/revenue", revenue_router_1.revenueRouter);
app.use("/command-center", commandCenter_router_1.commandCenterRouter);
app.use("/clip-factory", clipFactory_router_1.clipFactoryRouter);
app.use("/social-connectors", socialConnector_router_1.socialConnectorRouter);
app.use("/media-pipeline", mediaPipeline_router_1.mediaPipelineRouter);
app.use("/polls", polls_router_1.pollsRouter);
app.use("/ads", ads_router_1.adsRouter);
app.use("/chat", chat_router_1.chatRouter);
app.use("/search", search_router_1.searchRouter);
exports.api = (0, https_1.onRequest)({
    region: "africa-east1",
    cors: true,
    timeoutSeconds: 60,
    memory: "512MiB",
}, app);
//# sourceMappingURL=index.js.map