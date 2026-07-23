export const config = {
  port: parseInt(process.env.PORT ?? '3000', 10),
  storageBucket: process.env.STORAGE_BUCKET ?? '',
  storageRoot: process.env.STORAGE_ROOT ?? '/var/yohpal/storage',
  uploadTmpDir: process.env.UPLOAD_TMP_DIR ?? '/tmp/yohpal/uploads',
  outputDir: process.env.OUTPUT_DIR ?? '/tmp/yohpal/transcoded',
  signedUrlExpirySeconds: 60 * 15,
};
