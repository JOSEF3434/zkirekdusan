# Build Failure Fix Guide

## Error Summary
**Error:** `Could not start thread DartWorker: 22 (The device does not recognize the command.)`

**Type:** Dart VM Critical Error

**Impact:** Build fails completely, app won't compile

## Root Causes

This error typically happens due to:

1. **Corrupted Build Cache** - Stale or corrupt build artifacts
2. **System Resource Exhaustion** - Too many Dart/Flutter processes running
3. **Windows Thread Limit** - System unable to create new threads
4. **Antivirus Interference** - Security software blocking Dart processes
5. **Disk Space Issues** - Not enough space for build artifacts

## Solution Steps

### Step 1: Kill All Dart/Flutter Processes

```powershell
# Kill all related processes
taskkill /F /IM dart.exe /T
taskkill /F /IM flutter.bat /T  
taskkill /F /IM java.exe /T
taskkill /F /IM gradle.exe /T
```

### Step 2: Clean Everything

```powershell
cd mobile

# Flutter clean
fvm flutter clean

# Remove build folders manually
Remove-Item -Recurse -Force build -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force .dart_tool -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force android\.gradle -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force android\build -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force android\app\build -ErrorAction SilentlyContinue

# Clean Gradle cache
cd android
.\gradlew clean --no-daemon
cd ..
```

### Step 3: Clear Flutter/Dart Cache

```powershell
# Clear pub cache (be careful - this removes all packages!)
fvm flutter pub cache repair

# Or just clean
fvm flutter pub get
```

### Step 4: Restart Your Computer

**Important:** After cleaning, restart Windows to:
- Release all locked files
- Reset thread limits
- Clear system cache
- Stop background processes

### Step 5: Build with No Daemon

```powershell
cd mobile

# Get dependencies
fvm flutter pub get

# Build without Gradle daemon (uses less resources)
fvm flutter build apk --debug --no-daemon
```

### Step 6: If Still Failing - Build Verbose

```powershell
# Build with verbose output to see exact error
fvm flutter run -d <device-id> -v
```

## Alternative: Use These Flags

If the error persists, try building with these flags:

```powershell
# Skip dependency validation (ignore Gradle warnings)
fvm flutter run -d <device-id> --android-skip-build-dependency-validation

# Use release mode (sometimes more stable)
fvm flutter run -d <device-id> --release

# Disable sound null safety (if there are null errors)
fvm flutter run -d <device-id> --no-sound-null-safety
```

## Quick Fix Commands (Copy & Paste)

```powershell
# Full clean and rebuild sequence
cd c:\Users\mesti\Desktop\RandD\zkirekdusan\mobile

# 1. Kill processes
taskkill /F /IM dart.exe /T; taskkill /F /IM flutter.bat /T; taskkill /F /IM java.exe /T

# 2. Clean Flutter
fvm flutter clean

# 3. Remove folders
Remove-Item -Recurse -Force build, .dart_tool, android\.gradle, android\build, android\app\build -ErrorAction SilentlyContinue

# 4. Gradle clean (with timeout)
cd android; timeout /t 300 .\gradlew clean --no-daemon; cd ..

# 5. Get dependencies
fvm flutter pub get

# 6. Build
fvm flutter build apk --debug --no-daemon

# 7. Run on device
fvm flutter run -d SM-A075F
```

## Checking Your Device

```powershell
# List connected devices
fvm flutter devices

# If device not showing, restart ADB
adb kill-server
adb start-server
adb devices
```

## System Resource Checks

### Check Disk Space
```powershell
Get-PSDrive C | Select-Object Used,Free
```
**Need:** At least 10GB free for Flutter build

### Check Running Processes
```powershell
Get-Process | Where-Object {$_.ProcessName -match "dart|flutter|java|gradle"}
```
**Should see:** Minimal or no processes before building

### Check Thread Count
```powershell
(Get-Process).Threads.Count | Measure-Object -Sum
```
**Normal:** Less than 10,000 total system threads

## Antivirus Exclusions

Add these to your antivirus exclusions:
- `C:\Users\mesti\fvm\`
- `C:\Users\mesti\Desktop\RandD\zkirekdusan\mobile\`
- `C:\Users\mesti\AppData\Local\Pub\Cache\`
- `%LOCALAPPDATA%\Temp\`

## Gradle Daemon Issues

If Gradle daemon keeps failing:

```powershell
# Check daemon status
cd android
.\gradlew --status

# Stop all daemons
.\gradlew --stop

# Build without daemon
.\gradlew assembleDebug --no-daemon
```

## Last Resort: Fresh Rebuild

If nothing works:

1. **Backup your code** (commit to git)
2. **Delete mobile folder**
3. **Re-run build_runner** to regenerate files:
   ```powershell
   cd mobile
   fvm dart run build_runner build --delete-conflicting-outputs
   ```
4. **Try build again**

## Common Windows-Specific Issues

### 1. Path Too Long
```powershell
# Enable long paths in Windows
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Value 1 -PropertyType DWORD -Force
```

### 2. Execution Policy
```powershell
# Allow scripts to run
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

### 3. Dart SDK Cache Corruption
```powershell
# Clear Dart SDK cache
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\Pub\Cache" -ErrorAction SilentlyContinue
fvm flutter pub cache repair
```

## Success Indicators

You'll know it's fixed when you see:
```
✓ Built build\app\outputs\flutter-apk\app-debug.apk (xxx MB)
```

## Prevention

To avoid this error in the future:

1. **Always** run `flutter clean` between major changes
2. **Restart** Android Studio/VS Code regularly
3. **Close** unused terminals
4. **Stop** Gradle daemons when not building: `gradlew --stop`
5. **Commit** your code frequently
6. **Keep** at least 15GB free disk space

## Still Not Working?

If after all steps it still fails:

1. Check Windows Event Viewer for system errors
2. Check if your disk is failing (run `chkdsk`)
3. Check RAM usage (might need more memory)
4. Try building on a different machine
5. Consider using Flutter's web target instead: `flutter run -d chrome`

## Contact Info

If you need to report this bug to Flutter team:
- Include output of: `flutter doctor -v`
- Include the full error log
- Mention: Windows, Dart 3.13.2, Flutter 3.47.2, FVM

---

**TL;DR:** Kill all processes, clean everything, restart computer, rebuild. If that doesn't work, check system resources and antivirus settings.
