import { Injectable } from '@nestjs/common';
import fs from 'fs/promises';
import path from 'path';
import { config } from '../../config';

@Injectable()
export class StorageService {
  // Filesystem-backed for MVP. Swap for GCS/S3 by replacing this class only.
  private readonly root = config.storageRoot;

  async store(localPath: string, storagePath: string): Promise<string> {
    const dest = path.join(this.root, storagePath);
    await fs.mkdir(path.dirname(dest), { recursive: true });
    await fs.copyFile(localPath, dest);
    return storagePath;
  }

  async download(storagePath: string): Promise<string> {
    return path.join(this.root, storagePath);
  }

  async storeDirectory(localDir: string, storageDir: string): Promise<string> {
    const dest = path.join(this.root, storageDir);
    await fs.cp(localDir, dest, { recursive: true });
    return storageDir;
  }
}
