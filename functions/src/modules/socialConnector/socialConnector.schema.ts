import { z } from "zod";

export const SupportedPlatforms = [
  "youtube",
  "tiktok",
  "instagram",
  "facebook",
  "x",
  "linkedin",
  "twitch",
  "kick",
] as const;

export type SocialPlatform = (typeof SupportedPlatforms)[number];

export const GetOAuthUrlSchema = z.object({
  platform: z.enum(SupportedPlatforms),
});

export const DisconnectConnectorSchema = z.object({
  connectorId: z.string().min(1, "connectorId is required."),
});

export const HealthCheckSchema = z.object({
  connectorId: z.string().min(1, "connectorId is required."),
});
