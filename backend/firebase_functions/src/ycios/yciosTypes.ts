export type YciosProjectStatus = 'active' | 'archived' | 'restored';
export type YciosRenderStatus = 'queued' | 'processing' | 'completed' | 'failed';
export type YciosAssetType = 'video' | 'audio' | 'image' | 'ai_asset' | 'prompt' | 'template';

export interface YciosProject {
  id: string;
  creatorId: string;
  title: string;
  description?: string;
  status: YciosProjectStatus;
  createdAt?: FirebaseFirestore.FieldValue;
  updatedAt?: FirebaseFirestore.FieldValue;
}

export interface YciosAsset {
  id: string;
  creatorId: string;
  projectId: string;
  type: YciosAssetType;
  name: string;
  storageUrl?: string;
  metadata?: Record<string, unknown>;
}

export interface YciosRenderJob {
  id: string;
  creatorId: string;
  projectId: string;
  status: YciosRenderStatus;
  progress: number;
  outputUrl?: string;
  error?: string;
}

export interface YciosAgentTask {
  id: string;
  creatorId: string;
  projectId: string;
  agentType: string;
  prompt: string;
  status: 'queued' | 'processing' | 'completed' | 'failed';
  result?: Record<string, unknown>;
}
