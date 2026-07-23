import { z } from "zod";

export const JobTypes = [
  "transcode",
  "thumbnail",
  "clip_export",
  "replay_package",
  "distribute",
] as const;

export type MediaJobType = (typeof JobTypes)[number];

export const PipelineConfigSchema = z.object({
  outputFormat: z.enum(["mp4", "webm", "hls"]).default("mp4"),
  resolution: z.enum(["1080p", "720p", "480p", "360p"]).default("720p"),
  videoBitrate: z.number().int().min(100).max(20000).default(2500),
  fps: z.number().int().min(15).max(60).default(30),
  audioBitrate: z.number().int().min(64).max(320).default(128),
  watermarkEnabled: z.boolean().default(false),
  watermarkRef: z.string().optional(),
});

export const DispatchJobSchema = z.object({
  jobType: z.enum(JobTypes),
  inputRef: z.string().min(1, "inputRef is required."),
  sessionId: z.string().optional(),
  clipSegmentId: z.string().optional(),
  config: PipelineConfigSchema.optional(),
  priority: z.number().int().min(1).max(10).default(5),
  maxRetries: z.number().int().min(0).max(5).default(3),
});

export const UpdateJobStatusSchema = z.object({
  status: z.enum(["queued", "processing", "completed", "failed", "cancelled"]),
  progressPercent: z.number().min(0).max(100).optional(),
  errorMessage: z.string().optional(),
  outputRef: z.string().optional(),
});
