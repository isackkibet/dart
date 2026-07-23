import { Injectable } from '@nestjs/common';
import { config } from '../../config';

@Injectable()
export class SignedUrlService {
  async sign(storagePath: string): Promise<string> {
    const expiresInSeconds = config.signedUrlExpirySeconds;
    // MVP stub: returns a local path reference.
    // Replace with GCS/S3 presigned URL generation before production.
    return `${storagePath}?signature=SIGNED_TOKEN&expiresIn=${expiresInSeconds}`;
  }
}
