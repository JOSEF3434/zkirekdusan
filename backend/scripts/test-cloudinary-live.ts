// backend/scripts/test-cloudinary-live.ts
import 'dotenv/config';
import { ConfigService } from '@nestjs/config';
import {
  CloudinaryStorageProvider,
  calculateCloudinaryMaxRuntimeSec,
  CLOUDINARY_MAX_RUNTIME_ARCHIVE_ENABLED,
  CLOUDINARY_MAX_RUNTIME_ARCHIVE_DISABLED,
} from '../src/modules/uploads/providers/cloudinary.provider.js';

async function testCloudinaryLiveStreaming() {
  console.log('🎥 Starting Cloudinary Live Streaming Verification Test...\n');

  // ── Test Suite 1: Pure Unit Checks on Runtime Limits ──────────────────────
  console.log('Test Suite 1: Verifying max_runtime_sec calculation rules...');

  // Rule 1: archive=true never exceeds 10800
  const defaultArchive = calculateCloudinaryMaxRuntimeSec(true);
  console.log(`  - archive=true (default): ${defaultArchive}s (must equal ${CLOUDINARY_MAX_RUNTIME_ARCHIVE_ENABLED})`);
  if (defaultArchive > 10800) {
    throw new Error(`FAIL: archive=true returned ${defaultArchive} > 10800`);
  }

  const requestedOverArchive = calculateCloudinaryMaxRuntimeSec(true, 43200);
  console.log(`  - archive=true (requested 43200s): ${requestedOverArchive}s (must clamp to 10800)`);
  if (requestedOverArchive > 10800) {
    throw new Error(`FAIL: archive=true with 43200s was not clamped: ${requestedOverArchive}`);
  }

  const requestedUnderArchive = calculateCloudinaryMaxRuntimeSec(true, 7200);
  console.log(`  - archive=true (requested 7200s): ${requestedUnderArchive}s`);
  if (requestedUnderArchive !== 7200) {
    throw new Error(`FAIL: archive=true with 7200s returned ${requestedUnderArchive}`);
  }

  // Rule 2: archive=false never exceeds 36000
  const defaultNoArchive = calculateCloudinaryMaxRuntimeSec(false);
  console.log(`  - archive=false (default): ${defaultNoArchive}s (must equal ${CLOUDINARY_MAX_RUNTIME_ARCHIVE_DISABLED})`);
  if (defaultNoArchive > 36000) {
    throw new Error(`FAIL: archive=false returned ${defaultNoArchive} > 36000`);
  }

  const requestedOverNoArchive = calculateCloudinaryMaxRuntimeSec(false, 50000);
  console.log(`  - archive=false (requested 50000s): ${requestedOverNoArchive}s (must clamp to 36000)`);
  if (requestedOverNoArchive > 36000) {
    throw new Error(`FAIL: archive=false with 50000s was not clamped: ${requestedOverNoArchive}`);
  }

  console.log('✓ All runtime limit calculation tests passed!\n');

  // ── Test Suite 2: Cloudinary API Integration Test with Record Stream ─────
  const configService = new ConfigService();
  const provider = new CloudinaryStorageProvider(configService);

  if (!provider.configured) {
    console.error('❌ Cloudinary is not configured in .env!');
    process.exit(1);
  }

  console.log(`✓ Cloudinary initialized with cloud: ${provider.currentCloudName}`);

  // Test 2A: Create Live Stream with Record Stream (archiveEnabled = true)
  console.log('\nTest 2A: Creating Live Stream with "Record Stream" enabled (archiveEnabled=true)...');
  const testStreamName = `test_studio_record_${Date.now()}`;
  const stream = await provider.createLiveStream(testStreamName, {
    idleTimeoutSec: 60,
    archiveEnabled: true,
  });

  console.log('✓ Cloudinary Live Stream created:');
  console.log(`  - ID: ${stream.id}`);
  console.log(`  - Name: ${stream.name}`);
  console.log(`  - Initial Status: ${stream.status}`);
  console.log(`  - RTMP Ingest URL: ${stream.rtmpIngestUrl}`);
  console.log(`  - Stream Key: ${stream.streamKey ? stream.streamKey.substring(0, 4) + '...' + stream.streamKey.substring(stream.streamKey.length - 4) + ` (len=${stream.streamKey.length})` : 'NONE'}`);
  console.log(`  - Playback HLS URL: ${stream.hlsUrl}`);
  console.log(`  - Archive Public ID: ${stream.archivePublicId}`);

  if (!stream.id || !stream.streamKey || !stream.hlsUrl) {
    throw new Error('Live stream resource missing essential fields!');
  }

  // Test 2B: Activate Live Stream
  console.log('\nTest 2B: Activating live stream...');
  await provider.activateLiveStream(stream.id);
  console.log('✓ Activation completed successfully.');

  // Test 2C: Query Status
  console.log('\nTest 2C: Querying stream status...');
  const statusData = await provider.getLiveStream(stream.id);
  console.log(`✓ Queried status from Cloudinary: ${statusData?.status || 'unknown'}`);

  // Test 2D: Idle Stream
  console.log('\nTest 2D: Idling live stream...');
  await provider.idleLiveStream(stream.id);
  console.log('✓ Idle request completed successfully.');

  console.log('\n🎉 ALL CLOUDINARY LIVE STREAMING TESTS PASSED!\n');
}

testCloudinaryLiveStreaming().catch((err) => {
  console.error('❌ Cloudinary Live Streaming test failed:', err);
  process.exit(1);
});
