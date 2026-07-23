import { Router } from "express";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { AuthenticatedRequest, requireAuth } from "../../core/http/requireAuth";
import { fail, ok } from "../../core/http/respond";
import {
  SupportedPlatforms,
  type SocialPlatform,
} from "./socialConnector.schema";

export const socialConnectorRouter = Router();
const db = getFirestore();

// ─── OAuth base URLs per platform (replace with real OAuth endpoints) ─────────
const OAUTH_CONFIG: Record<
  SocialPlatform,
  { authBaseUrl: string; scopes: string[] }
> = {
  youtube: {
    authBaseUrl: "https://accounts.google.com/o/oauth2/v2/auth",
    scopes: ["https://www.googleapis.com/auth/youtube.readonly"],
  },
  tiktok: {
    authBaseUrl: "https://www.tiktok.com/auth/authorize",
    scopes: ["user.info.basic", "video.list"],
  },
  instagram: {
    authBaseUrl: "https://api.instagram.com/oauth/authorize",
    scopes: ["user_profile", "user_media"],
  },
  facebook: {
    authBaseUrl: "https://www.facebook.com/v18.0/dialog/oauth",
    scopes: ["pages_manage_posts", "pages_read_engagement"],
  },
  x: {
    authBaseUrl: "https://twitter.com/i/oauth2/authorize",
    scopes: ["tweet.read", "users.read"],
  },
  linkedin: {
    authBaseUrl: "https://www.linkedin.com/oauth/v2/authorization",
    scopes: ["r_liteprofile", "r_emailaddress", "w_member_social"],
  },
  twitch: {
    authBaseUrl: "https://id.twitch.tv/oauth2/authorize",
    scopes: ["user:read:email", "channel:read:subscriptions"],
  },
  kick: {
    authBaseUrl: "https://kick.com/oauth2/authorize",
    scopes: ["channel:read"],
  },
};

// ─── Status ───────────────────────────────────────────────────────────────────
socialConnectorRouter.get("/status", requireAuth, async (_req, res) => {
  return ok(res, { module: "social_connector", status: "ready" });
});

// ─── List connectors ──────────────────────────────────────────────────────────
socialConnectorRouter.get(
  "/connectors",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const uid = req.user?.uid;
    if (!uid) return fail(res, 401, "missing_user", "Missing user.");

    const snap = await db
      .collection("socialConnectors")
      .where("creatorId", "==", uid)
      .orderBy("connectedAt", "desc")
      .get();

    const connectors = snap.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));

    return ok(res, { connectors });
  },
);

// ─── Get OAuth URL for a platform ────────────────────────────────────────────
socialConnectorRouter.post(
  "/connectors/:platform/oauth-url",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const uid = req.user?.uid;
    if (!uid) return fail(res, 401, "missing_user", "Missing user.");

    const platform = req.params.platform as SocialPlatform;
    if (!SupportedPlatforms.includes(platform)) {
      return fail(
        res,
        400,
        "unsupported_platform",
        `Platform "${platform}" is not supported.`,
      );
    }

    const config = OAUTH_CONFIG[platform];
    const clientId =
      process.env[`${platform.toUpperCase()}_CLIENT_ID`] ?? "PLACEHOLDER";
    const redirectUri =
      process.env.OAUTH_REDIRECT_URI ??
      "https://us-central1-yohpal-live.cloudfunctions.net/api/social-connectors/connectors/callback";

    const params = new URLSearchParams({
      client_id: clientId,
      redirect_uri: redirectUri,
      response_type: "code",
      scope: config.scopes.join(" "),
      state: `${uid}:${platform}`,
    });

    const authUrl = `${config.authBaseUrl}?${params.toString()}`;
    return ok(res, { authUrl, platform });
  },
);

// ─── OAuth Callback ───────────────────────────────────────────────────────────
socialConnectorRouter.get(
  "/connectors/callback",
  async (req, res) => {
    const { code, state, error } = req.query as Record<string, string>;

    if (error) {
      return res
        .status(400)
        .send(`OAuth error: ${error}. You can close this window.`);
    }

    if (!code || !state) {
      return res.status(400).send("Missing code or state. Please try again.");
    }

    const [uid, platform] = state.split(":");
    if (!uid || !platform) {
      return res.status(400).send("Invalid state parameter.");
    }

    // Store the connector record — token exchange happens server-side
    const existingSnap = await db
      .collection("socialConnectors")
      .where("creatorId", "==", uid)
      .where("platform", "==", platform)
      .limit(1)
      .get();

    const connectorData = {
      creatorId: uid,
      platform,
      status: "connected",
      scopes: OAUTH_CONFIG[platform as SocialPlatform]?.scopes ?? [],
      authCode: code, // Store code; actual token exchange done server-side
      externalUserId: "",
      externalUsername: "",
      externalAvatarUrl: "",
      connectedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    };

    if (existingSnap.empty) {
      await db.collection("socialConnectors").add(connectorData);
    } else {
      await existingSnap.docs[0].ref.update({
        status: "connected",
        authCode: code,
        connectedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    }

    return res
      .status(200)
      .send(
        `✅ ${platform} connected successfully! You can close this window and return to YohPal Live.`,
      );
  },
);

// ─── Disconnect a connector ───────────────────────────────────────────────────
socialConnectorRouter.delete(
  "/connectors/:connectorId",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const uid = req.user?.uid;
    if (!uid) return fail(res, 401, "missing_user", "Missing user.");

    const ref = db.collection("socialConnectors").doc(req.params.connectorId);
    const doc = await ref.get();

    if (!doc.exists) {
      return fail(res, 404, "connector_not_found", "Connector not found.");
    }
    if (doc.data()?.creatorId !== uid && req.user?.admin !== true) {
      return fail(res, 403, "forbidden", "You cannot disconnect this connector.");
    }

    await ref.update({
      status: "revoked",
      revokedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    // Log health event
    await db.collection("connectorHealthLogs").add({
      connectorId: req.params.connectorId,
      platform: doc.data()?.platform ?? "unknown",
      status: "revoked",
      checkedAt: FieldValue.serverTimestamp(),
      triggeredBy: uid,
    });

    return ok(res, {
      id: req.params.connectorId,
      status: "revoked",
      message: "Platform disconnected successfully.",
    });
  },
);

// ─── Health check ─────────────────────────────────────────────────────────────
socialConnectorRouter.post(
  "/connectors/:connectorId/health",
  requireAuth,
  async (req: AuthenticatedRequest, res) => {
    const uid = req.user?.uid;
    if (!uid) return fail(res, 401, "missing_user", "Missing user.");

    const ref = db.collection("socialConnectors").doc(req.params.connectorId);
    const doc = await ref.get();

    if (!doc.exists) {
      return fail(res, 404, "connector_not_found", "Connector not found.");
    }
    if (doc.data()?.creatorId !== uid && req.user?.admin !== true) {
      return fail(res, 403, "forbidden", "Cannot health-check this connector.");
    }

    const platform = doc.data()?.platform ?? "unknown";
    const status = doc.data()?.status ?? "disconnected";
    const startMs = Date.now();

    // Simulate platform API ping — replace with real token validation per platform
    const isConnected = status === "connected";
    const latencyMs = Date.now() - startMs + Math.floor(Math.random() * 80);
    const healthStatus = isConnected ? "healthy" : "expired";

    const healthResult = {
      connectorId: req.params.connectorId,
      platform,
      status: healthStatus,
      latencyMs,
      checkedAt: new Date().toISOString(),
      errorMessage: isConnected ? null : "Token expired or revoked.",
    };

    // Update last health check timestamp
    await ref.update({
      lastHealthCheckAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    // Log the health result
    await db.collection("connectorHealthLogs").add({
      ...healthResult,
      checkedAt: FieldValue.serverTimestamp(),
      triggeredBy: uid,
    });

    return ok(res, healthResult);
  },
);
