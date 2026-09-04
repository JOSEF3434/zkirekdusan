// backend/scripts/test-cloudinary-live.ts
import 'dotenv/config';
import { ConfigService } from '@nestjs/config';
import { CloudinaryStorageProvider } from '../src/modules/uploads/providers/cloudinary.provider.js';

async function testCloudinaryLiveStreaming() {
  console.log('🎥 Starting Cloudinary Live Streaming Verification Test...\n');

  const configService = new ConfigService();
  const provider = new CloudinaryStorageProvider(configService);

  if (!provider.configured) {
    console.error('❌ Cloudinary is not configured in .env!');
    process.exit(1);
  }

  console.log(`✓ Cloudinary initialized with cloud: ${provider.currentCloudName}`);

  // Test 1: Create Live Stream
  console.log('\nTest 1: Creating a test live stream on Cloudinary...');
  const testStreamName = `test_verification_${Date.now()}`;
  const stream = await provider.createLiveStream(testStreamName, {
    idleTimeoutSec: 60,
    maxRuntimeSec: 3600,
  });

  console.log('✓ Cloudinary Live Stream created:');
  console.log(`  - ID: ${stream.id}`);
  console.log(`  - Name: ${stream.name}`);
  console.log(`  - Initial Status: ${stream.status}`);
  console.log(`  - RTMP Ingest URL: ${stream.rtmpIngestUrl}`);
  console.log(`  - Stream Key: ${stream.streamKey ? stream.streamKey.substring(0, 10) + '...' : 'NONE'}`);
  console.log(`  - Playback HLS URL: ${stream.hlsUrl}`);
  console.log(`  - Archive Public ID: ${stream.archivePublicId}`);

  if (!stream.id || !stream.streamKey || !stream.hlsUrl) {
    throw new Error('Live stream resource missing essential fields!');
  }

  // Test 2: Activate Live Stream
  console.log('\nTest 2: Activating live stream...');
  await provider.activateLiveStream(stream.id);
  console.log('✓ Activation request completed successfully.');

  // Test 3: Query Stream Status
  console.log('\nTest 3: Querying live stream status...');
  const statusData = await provider.getLiveStream(stream.id);
  console.log(`✓ Queried status from Cloudinary: ${statusData?.status || 'unknown'}`);

  // Test 4: Idle Live Stream
  console.log('\nTest 4: Idling live stream...');
  await provider.idleLiveStream(stream.id);
  console.log('✓ Idle request completed successfully.');

  // Test 5: Cleanup test live stream
  console.log('\nTest 5: Cleaning up test stream...');
  try {
    const res = await fetch(
      `https://api.cloudinary.com/v2/video/${provider.currentCloudName}/live_streams/${stream.id}`,
      {
        method: 'DELETE',
        headers: {
          Authorization: `Basic ${Buffer.from(`${process.env.CLOUDINARY_API_KEY}:${process.env.CLOUDINARY_API_SECRET}`).toString('base64')}`,
        },
      },
    );
    if (res.ok) {
      console.log(`✓ Deleted test live stream [${stream.id}] from Cloudinary.`);
    } else {
      console.warn(`⚠ Could not delete test live stream (HTTP ${res.status})`);
    }
  } catch (err: any) {
    console.warn(`⚠ Error deleting test stream: ${err.message}`);
  }

  console.log('\n🎉 ALL CLOUDINARY LIVE STREAMING TESTS PASSED!\n');
}

testCloudinaryLiveStreaming().catch((err) => {
  console.error('❌ Cloudinary Live Streaming test failed:', err);
  process.exit(1);
});
