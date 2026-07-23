import {
  Controller,
  Post,
  UploadedFile,
  UseInterceptors,
  Body,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { config } from '../../config';
import { UploadService } from './upload.service';

@Controller('upload')
export class UploadController {
  constructor(private readonly uploadService: UploadService) {}

  @Post()
  @UseInterceptors(
    FileInterceptor('file', {
      storage: diskStorage({ destination: config.uploadTmpDir }),
    }),
  )
  async upload(
    @UploadedFile() file: Express.Multer.File,
    @Body('creatorId') creatorId: string,
  ) {
    return this.uploadService.handleUpload(file, creatorId);
  }
}
