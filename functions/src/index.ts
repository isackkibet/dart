import * as admin from "firebase-admin";
import express from "express";
import cors from "cors";
import { onRequest } from "firebase-functions/v2/https";
import { ok } from "./core/http/respond";
import { authRouter } from "./modules/auth/auth.router";
import { creatorProfileRouter } from "./modules/creatorProfile/creatorProfile.router";
import { multistreamRouter } from "./modules/multistream/multistream.router";
import { streamOrchestrationRouter } from "./modules/streamOrchestration/streamOrchestration.router";
import { trafficFunnelRouter } from "./modules/trafficFunnel/trafficFunnel.router";
import { autonomyRouter } from "./modules/autonomy/autonomy.router";
import { creatorGrowthRouter } from "./modules/creatorGrowth/creatorGrowth.router";
import { revenueRouter } from "./modules/revenue/revenue.router";
import { commandCenterRouter } from "./modules/commandCenter/commandCenter.router";
import { clipFactoryRouter } from "./modules/clipFactory/clipFactory.router";
import { socialConnectorRouter } from "./modules/socialConnector/socialConnector.router";
import { mediaPipelineRouter } from "./modules/mediaPipeline/mediaPipeline.router";
import { pollsRouter } from "./modules/polls/polls.router";
import { adsRouter } from "./modules/ads/ads.router";
import { chatRouter } from "./modules/chat/chat.router";
import { searchRouter } from "./modules/search/search.router";

if (admin.apps.length === 0) {
  admin.initializeApp();
}


const app = express();

app.use(cors({ origin: true }));
app.use(express.json({ limit: "2mb" }));

app.get("/health", (_req, res) => {
  return ok(res, {
    service: "yohpal-live-functions",
    status: "healthy",
    timestamp: new Date().toISOString(),
  });
});

app.use("/auth", authRouter);
app.use("/creator-profile", creatorProfileRouter);
app.use("/multistream", multistreamRouter);
app.use("/stream-orchestration", streamOrchestrationRouter);
app.use("/traffic", trafficFunnelRouter);
app.use("/autonomy", autonomyRouter);
app.use("/growth", creatorGrowthRouter);
app.use("/revenue", revenueRouter);
app.use("/command-center", commandCenterRouter);
app.use("/clip-factory", clipFactoryRouter);
app.use("/social-connectors", socialConnectorRouter);
app.use("/media-pipeline", mediaPipelineRouter);
app.use("/polls", pollsRouter);
app.use("/ads", adsRouter);
app.use("/chat", chatRouter);
app.use("/search", searchRouter);



export const api = onRequest(
  {
    region: "africa-east1",
    cors: true,
    timeoutSeconds: 60,
    memory: "512MiB",
  },
  app,
);
