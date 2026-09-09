# Ethiopian Calendar Feature - Installation Verification Script (PowerShell)
# Run this script to verify the installation is complete and correct

Write-Host "🔍 Ethiopian Calendar Feature - Verification Script" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

$errors = 0
$warnings = 0

function Print-Success {
    param($message)
    Write-Host "✅ $message" -ForegroundColor Green
}

function Print-Error {
    param($message)
    Write-Host "❌ $message" -ForegroundColor Red
    $script:errors++
}

function Print-Warning {
    param($message)
    Write-Host "⚠️  $message" -ForegroundColor Yellow
    $script:warnings++
}

Write-Host "📋 Checking Prerequisites..." -ForegroundColor White
Write-Host "----------------------------"

# Check Flutter
try {
    $flutterVersion = flutter --version 2>&1 | Select-Object -First 1
    Print-Success "Flutter installed: $flutterVersion"
} catch {
    Print-Error "Flutter not installed"
}

# Check Dart
try {
    $dartVersion = dart --version 2>&1 | Select-Object -First 1
    Print-Success "Dart installed: $dartVersion"
} catch {
    Print-Error "Dart not installed"
}

# Check Node.js
try {
    $nodeVersion = node --version
    Print-Success "Node.js installed: $nodeVersion"
} catch {
    Print-Error "Node.js not installed"
}

# Check npm
try {
    $npmVersion = npm --version
    Print-Success "npm installed: $npmVersion"
} catch {
    Print-Error "npm not installed"
}

Write-Host ""
Write-Host "📁 Checking Backend Files..." -ForegroundColor White
Write-Host "----------------------------"

# Check backend files
if (Test-Path "backend\package.json") {
    Print-Success "backend\package.json exists"
} else {
    Print-Error "backend\package.json not found"
}

if (Test-Path "backend\prisma\schema.prisma") {
    Print-Success "Prisma schema exists"
    
    # Check if calendar models exist in schema
    $schemaContent = Get-Content "backend\prisma\schema.prisma" -Raw
    if ($schemaContent -match "model CalendarNote") {
        Print-Success "CalendarNote model found in schema"
    } else {
        Print-Error "CalendarNote model not found in schema"
    }
    
    if ($schemaContent -match "model CalendarNoteMedia") {
        Print-Success "CalendarNoteMedia model found in schema"
    } else {
        Print-Error "CalendarNoteMedia model not found in schema"
    }
} else {
    Print-Error "Prisma schema not found"
}

if (Test-Path "backend\src\modules\calendar") {
    Print-Success "Calendar module directory exists"
    
    # Check key files
    if (Test-Path "backend\src\modules\calendar\calendar.controller.ts") {
        Print-Success "calendar.controller.ts exists"
    } else {
        Print-Error "calendar.controller.ts missing"
    }
    
    if (Test-Path "backend\src\modules\calendar\calendar.service.ts") {
        Print-Success "calendar.service.ts exists"
    } else {
        Print-Error "calendar.service.ts missing"
    }
    
    if (Test-Path "backend\src\modules\calendar\calendar.module.ts") {
        Print-Success "calendar.module.ts exists"
    } else {
        Print-Error "calendar.module.ts missing"
    }
} else {
    Print-Error "Calendar module directory not found"
}

if (Test-Path "backend\prisma\migrations\20260908000000_add_calendar_notes") {
    Print-Success "Calendar migration exists"
} else {
    Print-Error "Calendar migration not found"
}

Write-Host ""
Write-Host "📱 Checking Frontend Files..." -ForegroundColor White
Write-Host "-----------------------------"

# Check Flutter files
if (Test-Path "mobile\pubspec.yaml") {
    Print-Success "pubspec.yaml exists"
    
    # Check for abushakir package
    $pubspecContent = Get-Content "mobile\pubspec.yaml" -Raw
    if ($pubspecContent -match "abushakir") {
        Print-Success "abushakir package in pubspec.yaml"
    } else {
        Print-Error "abushakir package not in pubspec.yaml"
    }
} else {
    Print-Error "pubspec.yaml not found"
}

if (Test-Path "mobile\lib\features\calendar") {
    Print-Success "Calendar feature directory exists"
    
    # Check key files
    @(
        "mobile\lib\features\calendar\presentation\calendar_screen.dart",
        "mobile\lib\features\calendar\domain\calendar_note_model.dart",
        "mobile\lib\features\calendar\data\calendar_repository.dart",
        "mobile\lib\features\calendar\data\calendar_offline_repository.dart"
    ) | ForEach-Object {
        if (Test-Path $_) {
            $filename = Split-Path $_ -Leaf
            Print-Success "$filename exists"
        } else {
            $filename = Split-Path $_ -Leaf
            Print-Error "$filename missing"
        }
    }
} else {
    Print-Error "Calendar feature directory not found"
}

if (Test-Path "mobile\lib\core\database") {
    Print-Success "Database directory exists"
    
    # Check database files
    @(
        "mobile\lib\core\database\app_database.dart",
        "mobile\lib\core\database\tables\local_calendar_notes_table.dart",
        "mobile\lib\core\database\daos\calendar_notes_dao.dart"
    ) | ForEach-Object {
        if (Test-Path $_) {
            $filename = Split-Path $_ -Leaf
            Print-Success "$filename exists"
        } else {
            $filename = Split-Path $_ -Leaf
            Print-Error "$filename missing"
        }
    }
} else {
    Print-Error "Database directory not found"
}

if (Test-Path "mobile\lib\core\utils\ethiopian_calendar_util.dart") {
    Print-Success "ethiopian_calendar_util.dart exists"
} else {
    Print-Error "ethiopian_calendar_util.dart missing"
}

Write-Host ""
Write-Host "📄 Checking Documentation..." -ForegroundColor White
Write-Host "----------------------------"

@(
    @("ETHIOPIAN_CALENDAR_FEATURE.md", "Feature documentation"),
    @("CALENDAR_QUICK_START.md", "Quick start guide"),
    @("MIGRATION_CHECKLIST.md", "Migration checklist"),
    @("CALENDAR_IMPLEMENTATION_SUMMARY.md", "Implementation summary")
) | ForEach-Object {
    if (Test-Path $_[0]) {
        Print-Success "$($_[1]) exists"
    } else {
        Print-Warning "$($_[1]) missing"
    }
}

Write-Host ""
Write-Host "🔧 Checking Generated Files..." -ForegroundColor White
Write-Host "-------------------------------"

# Check for generated files
if (Test-Path "mobile\lib\core\database\app_database.g.dart") {
    Print-Success "app_database.g.dart generated"
} else {
    Print-Warning "app_database.g.dart not generated (run build_runner)"
}

if (Test-Path "mobile\lib\features\calendar\domain\calendar_note_model.freezed.dart") {
    Print-Success "calendar_note_model.freezed.dart generated"
} else {
    Print-Warning "calendar_note_model.freezed.dart not generated (run build_runner)"
}

if (Test-Path "mobile\lib\features\calendar\domain\calendar_note_model.g.dart") {
    Print-Success "calendar_note_model.g.dart generated"
} else {
    Print-Warning "calendar_note_model.g.dart not generated (run build_runner)"
}

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "📊 Verification Summary" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

if ($errors -eq 0) {
    Print-Success "All critical checks passed! ✅"
} else {
    Print-Error "$errors error(s) found"
}

if ($warnings -gt 0) {
    Print-Warning "$warnings warning(s) found"
}

Write-Host ""

if ($errors -eq 0 -and $warnings -eq 0) {
    Write-Host "🎉 Installation looks good!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor White
    Write-Host "1. cd mobile; dart run build_runner build --delete-conflicting-outputs" -ForegroundColor Yellow
    Write-Host "2. cd backend; npx prisma migrate deploy" -ForegroundColor Yellow
    Write-Host "3. cd backend; npm run start:dev" -ForegroundColor Yellow
    Write-Host "4. cd mobile; flutter run" -ForegroundColor Yellow
} else {
    Write-Host "⚠️  Please fix the issues above before proceeding." -ForegroundColor Yellow
    
    if ($warnings -gt 0 -and $errors -eq 0) {
        Write-Host ""
        Write-Host "💡 Warnings detected. To fix:" -ForegroundColor Cyan
        Write-Host "   cd mobile; dart run build_runner build --delete-conflicting-outputs" -ForegroundColor Yellow
    }
}

Write-Host ""
exit $errors
