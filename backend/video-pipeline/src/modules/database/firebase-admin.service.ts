import { Injectable, OnModuleInit } from '@nestjs/common';
import { initializeApp, getApps, getApp, App } from 'firebase-admin/app';
import { getFirestore, Firestore } from 'firebase-admin/firestore';

@Injectable()
export class FirebaseAdminService implements OnModuleInit {
  private app!: App;

  onModuleInit(): void {
    this.app = getApps().length
      ? getApp()
      : initializeApp({ projectId: 'yohlab', storageBucket: 'yohlab.firebasestorage.app' });
  }

  get db(): Firestore {
    return getFirestore(this.app);
  }
}
