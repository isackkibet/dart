export type ParticipantRole = 'DIRECTOR' | 'CAMERA' | 'VIEWER';
export type ProgramLayout = 'SINGLE' | 'SPLIT_SCREEN';
export type ProductionStatus = 'DRAFT' | 'LIVE' | 'ENDED';

export interface IceServerConfig { urls: string | string[]; username?: string; credential?: string }
export interface ParticipantSnapshot {
  participantId: string;
  role: ParticipantRole;
  label: string;
  venue?: string;
  connected: boolean;
  lastSeenAt: string;
}
export interface ProductionSnapshot {
  id: string;
  title: string;
  ownerId: string;
  status: ProductionStatus;
  plan: 'FREE';
  maxCameras: 2;
  layout: ProgramLayout;
  activeCameraIds: string[];
  participants: ParticipantSnapshot[];
  createdAt: string;
  updatedAt: string;
}
export interface PairingClaims {
  productionId: string;
  role: ParticipantRole;
  participantId: string;
  label: string;
  venue?: string;
  exp: number;
}
export interface SignalEnvelope {
  productionId: string;
  fromParticipantId: string;
  toParticipantId: string;
  type: 'offer' | 'answer' | 'ice-candidate';
  payload: unknown;
}
