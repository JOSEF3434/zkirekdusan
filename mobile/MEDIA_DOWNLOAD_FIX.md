# Media Download Fix - MissingPluginException

## Error
**Error:** `MissingPluginException(No implementation found for method getApplicationDocumentsDirectory on channel plugins.flutter.io/path_provider)`

**When:** Downloading calendar note media attachments

## Root Cause

The `media_watermark_service.dart` file is missing the proper import for `path_provider` and has incorrect implementation for native file saving.

## Fix Required

You need to edit `mobile/lib/core/utils/media_watermark_service.dart`:

### 1. Fix Imports (Lines 1-18)

**Replace:**
```dart
// lib/core/utils/media_watermark_service.dart
// ... comments ...

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Conditional imports for platform-specific code
import 'media_watermark_service_stub.dart'
    if (dart.library.io) 'media_watermark_service_io.dart'
    if (dart.library.html) 'media_watermark_service_web.dart'
    as platform;
```

**With:**
```dart
// lib/core/utils/media_watermark_service.dart
// Watermark service that brands media downloads with App Logo + 'ዝክረ ቅዱሳን'
// in a modern, platform-style (TikTok/Instagram) overlay.
// Cross-platform: Web triggers a browser Blob download;
// Android/iOS/Desktop saves to the local filesystem.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' if (dart.library.html) 'dart:html' as io;
import 'package:path_provider/path_provider.dart';
```

### 2. Fix _nativeSave Method (Around line 160)

**Find the `_nativeSave` method and replace it with:**

```dart
  /// Native save implementation using path_provider and dart:io
  Future<void> _nativeSave({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('_nativeSave should not be called on web');
    }
    
    try {
      // Get documents directory using path_provider
      final dir = await getApplicationDocumentsDirectory();
      final downloadsDir = io.Directory('${dir.path}/ZkireKdusan_Downloads');
      
      // Create directory if it doesn't exist
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      
      // Save file
      final filePath = '${downloadsDir.path}/$fileName';
      final file = io.File(filePath);
      await file.writeAsBytes(bytes);
      
      debugPrint('[MediaWatermarkService] Saved to: $filePath');
    } catch (e) {
      debugPrint('[MediaWatermarkService] Native save error: $e');
      rethrow;
    }
  }
```

**Delete these methods (they don't work):**
- `_getIoLib()`
- `_getPathProviderLib()`

## Manual Fix Steps

1. Open `mobile/lib/core/utils/media_watermark_service.dart` in your editor

2. **At the top** (lines 1-18), replace imports with the correct ones above

3. **Find** the `_nativeSave` method (around line 160)

4. **Replace** the entire `_nativeSave` method with the one above

5. **Delete** the `_getIoLib()` method if it exists

6. **Delete** the `_getPathProviderLib()` method if it exists

7. **Save** the file

8. **Run** hot restart: Press `R` in terminal or click restart button

## Why This Fixes It

### Before (Broken):
```dart
// NO import for path_provider ❌
// Tries to use dynamic imports ❌
final pathProvider = await import('package:path_provider/path_provider.dart');  
```

### After (Fixed):
```dart
// Proper import ✅
import 'package:path_provider/path_provider.dart';

// Direct function call ✅
final dir = await getApplicationDocumentsDirectory();
```

## After Fixing

1. **Hot Restart** the app (not just hot reload)
2. **Try downloading** a calendar note media again
3. **Check** the folder `/storage/emulated/0/Android/data/com.yourapp/files/ZkireKdusan_Downloads/`

## Expected Result

✅ **Success message:** "X media file(s) saved to internal storage with ዝክረ ቅዱሳን mark"

✅ **Files saved to:** `/data/user/0/com.yourapp/files/ZkireKdusan_Downloads/`

✅ **Images have** watermark with logo + "ዝክረ ቅዱሳን"

## Testing

```dart
// Test download from calendar
1. Open calendar
2. Click on a date with notes
3. View note with media
4. Click download button
5. Should see success message
6. Check file explorer for downloaded files
```

## Platform Behavior

### Mobile (Android/iOS) ✅
- Uses `path_provider` to get app documents directory
- Saves to `ZkireKdusan_Downloads` subfolder
- Files accessible in app's private storage

### Web 🌐
- Doesn't use `path_provider` (not available on web)
- Triggers browser download
- Files go to browser's Downloads folder

## Notes

- `path_provider` package is already in your `pubspec.yaml`
- The plugin just wasn't being called correctly
- Conditional imports (`if (dart.library.html)`) handle web vs mobile
- Hot restart is needed because this affects plugin channels

---

**TL;DR:** The file was trying to dynamically import `path_provider` which doesn't work. Fixed by adding proper import at top and using `getApplicationDocumentsDirectory()` directly.
