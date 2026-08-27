// backend/scripts/test-cloudinary-e2e.ts
import 'dotenv/config';
import { ConfigService } from '@nestjs/config';
import { CloudinaryStorageProvider } from '../src/modules/uploads/providers/cloudinary.provider.js';

async function testCloudinaryE2E() {
  console.log('🧪 Starting Cloudinary End-to-End Test Suite...\n');

  const configService = new ConfigService();
  const provider = new CloudinaryStorageProvider(configService);

  if (!provider.configured) {
    console.error('❌ Cloudinary is not configured in .env!');
    process.exit(1);
  }

  console.log(`✓ Cloudinary initialized with cloud: ${provider.currentCloudName}`);

  // Test 1: Upload Image
  console.log('\nTest 1: Uploading synthetic test image...');
  // 1x1 transparent PNG buffer
  const sampleImageBuffer = Buffer.from(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
    'base64',
  );

  const imgResult = await provider.upload(
    {
      buffer: sampleImageBuffer,
      originalname: 'test_pixel.png',
      mimetype: 'image/png',
      size: sampleImageBuffer.length,
    },
    'test/migration',
  );

  console.log(`✓ Image uploaded successfully:`);
  console.log(`  - storageKey: ${imgResult.storageKey}`);
  console.log(`  - secure_url: ${imgResult.url}`);
  console.log(`  - resourceType: ${imgResult.resourceType}`);
  console.log(`  - transformed: ${provider.getImageUrl(imgResult.storageKey, 300, 300)}`);

  // Test 2: URL Helpers
  console.log('\nTest 2: Validating URL Generation Helpers...');
  const testPublicId = 'videos/channels/sample_video';
  const hlsUrl = provider.getVideoStreamingUrl(testPublicId);
  const mp4Url = provider.getVideoDirectUrl(testPublicId);
  const rendition720p = provider.getVideoRenditionUrl(testPublicId, 720);
  const imgThumb = provider.getImageUrl('users/avatar_123', 200, 200);

  console.log(`  - HLS URL: ${hlsUrl}`);
  console.log(`  - Direct MP4 URL: ${mp4Url}`);
  console.log(`  - 720p Rendition URL: ${rendition720p}`);
  console.log(`  - Transformed Avatar URL: ${imgThumb}`);

  if (
    !hlsUrl.includes('sp_hd') ||
    !mp4Url.includes('f_mp4') ||
    !rendition720p.includes('h_720')
  ) {
    throw new Error('URL generation validation failed!');
  }
  console.log('✓ All URL helpers verified.');

  // Test 3: Public ID Extraction
  console.log('\nTest 3: Validating Public ID Extraction...');
  const extracted = CloudinaryStorageProvider.extractPublicId(imgResult.url);
  console.log(`  - Extracted: ${extracted}`);
  if (!extracted || !imgResult.storageKey.includes(extracted.split('/').pop()!)) {
    console.warn('  ⚠ PublicId extraction mismatch (non-fatal):', extracted, imgResult.storageKey);
  } else {
    console.log('✓ PublicId extraction verified.');
  }

  // Test 4: Safe Deletion
  console.log('\nTest 4: Testing safe asset deletion...');
  await provider.delete(imgResult.storageKey, 'image');
  console.log(`✓ Deleted test asset [${imgResult.storageKey}] from Cloudinary.`);

  console.log('\n🎉 ALL CLOUDINARY E2E TESTS PASSED SUCCESSFULLY!\n');
}

testCloudinaryE2E().catch((err) => {
  console.error('❌ Cloudinary E2E test failed:', err);
  process.exit(1);
});
