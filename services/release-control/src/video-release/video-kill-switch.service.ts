import { Injectable } from '@nestjs/common';

@Injectable()
export class YohPalVideoKillSwitchService {
  private killSwitchEnabled = false;
  private reason = '';
  private enabledAt: Date | null = null;

  enable(reason: string): { enabled: boolean; reason: string; enabledAt: Date } {
    this.killSwitchEnabled = true;
    this.reason = reason;
    this.enabledAt = new Date();
    return { enabled: true, reason, enabledAt: this.enabledAt };
  }

  disable(): { enabled: boolean; disabledAt: Date } {
    this.killSwitchEnabled = false;
    this.reason = '';
    this.enabledAt = null;
    return { enabled: false, disabledAt: new Date() };
  }

  isEnabled(): boolean {
    return this.killSwitchEnabled;
  }

  status(): { enabled: boolean; reason: string; enabledAt: Date | null } {
    return { enabled: this.killSwitchEnabled, reason: this.reason, enabledAt: this.enabledAt };
  }
}
