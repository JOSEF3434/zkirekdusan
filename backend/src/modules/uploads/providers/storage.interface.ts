// src/modules/uploads/providers/storage.interface.ts

export interface StorageUploadResult {
  storageKey: string;
  url: string;
  provider: 'LOCAL' | 'CLOUDINARY' | 'S3' | 'MINIO';
  width?: number;
  height?: number;
}

export interface IStorageProvider {
  /**
   * Save a buffer/file to storage
   */
  upload(
    file: {
      buffer: Buffer;
      originalname: string;
      mimetype: string;
      size: number;
    },
    subfolder: string,
  ): Promise<StorageUploadResult>;

  /**
   * Delete a stored object by key
   */
  delete(storageKey: string): Promise<void>;

  /**
   * Public URL of stored object
   */
  getUrl(storageKey: string): string;
}
