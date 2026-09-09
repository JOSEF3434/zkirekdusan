#!/bin/bash

# Ethiopian Calendar Feature - Installation Verification Script
# Run this script to verify the installation is complete and correct

echo "🔍 Ethiopian Calendar Feature - Verification Script"
echo "=================================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

errors=0
warnings=0

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to print success
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Function to print error
print_error() {
    echo -e "${RED}❌ $1${NC}"
    ((errors++))
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    ((warnings++))
}

echo "📋 Checking Prerequisites..."
echo "----------------------------"

# Check Flutter
if command_exists flutter; then
    flutter_version=$(flutter --version | head -n 1)
    print_success "Flutter installed: $flutter_version"
else
    print_error "Flutter not installed"
fi

# Check Dart
if command_exists dart; then
    dart_version=$(dart --version 2>&1 | head -n 1)
    print_success "Dart installed: $dart_version"
else
    print_error "Dart not installed"
fi

# Check Node.js
if command_exists node; then
    node_version=$(node --version)
    print_success "Node.js installed: $node_version"
else
    print_error "Node.js not installed"
fi

# Check npm
if command_exists npm; then
    npm_version=$(npm --version)
    print_success "npm installed: $npm_version"
else
    print_error "npm not installed"
fi

echo ""
echo "📁 Checking Backend Files..."
echo "----------------------------"

# Check backend files
if [ -f "backend/package.json" ]; then
    print_success "backend/package.json exists"
else
    print_error "backend/package.json not found"
fi

if [ -f "backend/prisma/schema.prisma" ]; then
    print_success "Prisma schema exists"
    
    # Check if calendar models exist in schema
    if grep -q "model CalendarNote" backend/prisma/schema.prisma; then
        print_success "CalendarNote model found in schema"
    else
        print_error "CalendarNote model not found in schema"
    fi
    
    if grep -q "model CalendarNoteMedia" backend/prisma/schema.prisma; then
        print_success "CalendarNoteMedia model found in schema"
    else
        print_error "CalendarNoteMedia model not found in schema"
    fi
else
    print_error "Prisma schema not found"
fi

if [ -d "backend/src/modules/calendar" ]; then
    print_success "Calendar module directory exists"
    
    # Check key files
    [ -f "backend/src/modules/calendar/calendar.controller.ts" ] && print_success "calendar.controller.ts exists" || print_error "calendar.controller.ts missing"
    [ -f "backend/src/modules/calendar/calendar.service.ts" ] && print_success "calendar.service.ts exists" || print_error "calendar.service.ts missing"
    [ -f "backend/src/modules/calendar/calendar.module.ts" ] && print_success "calendar.module.ts exists" || print_error "calendar.module.ts missing"
else
    print_error "Calendar module directory not found"
fi

if [ -d "backend/prisma/migrations/20260908000000_add_calendar_notes" ]; then
    print_success "Calendar migration exists"
else
    print_error "Calendar migration not found"
fi

echo ""
echo "📱 Checking Frontend Files..."
echo "-----------------------------"

# Check Flutter files
if [ -f "mobile/pubspec.yaml" ]; then
    print_success "pubspec.yaml exists"
    
    # Check for abushakir package
    if grep -q "abushakir" mobile/pubspec.yaml; then
        print_success "abushakir package in pubspec.yaml"
    else
        print_error "abushakir package not in pubspec.yaml"
    fi
else
    print_error "pubspec.yaml not found"
fi

if [ -d "mobile/lib/features/calendar" ]; then
    print_success "Calendar feature directory exists"
    
    # Check key files
    [ -f "mobile/lib/features/calendar/presentation/calendar_screen.dart" ] && print_success "calendar_screen.dart exists" || print_error "calendar_screen.dart missing"
    [ -f "mobile/lib/features/calendar/domain/calendar_note_model.dart" ] && print_success "calendar_note_model.dart exists" || print_error "calendar_note_model.dart missing"
    [ -f "mobile/lib/features/calendar/data/calendar_repository.dart" ] && print_success "calendar_repository.dart exists" || print_error "calendar_repository.dart missing"
    [ -f "mobile/lib/features/calendar/data/calendar_offline_repository.dart" ] && print_success "calendar_offline_repository.dart exists" || print_error "calendar_offline_repository.dart missing"
else
    print_error "Calendar feature directory not found"
fi

if [ -d "mobile/lib/core/database" ]; then
    print_success "Database directory exists"
    
    # Check database files
    [ -f "mobile/lib/core/database/app_database.dart" ] && print_success "app_database.dart exists" || print_error "app_database.dart missing"
    [ -f "mobile/lib/core/database/tables/local_calendar_notes_table.dart" ] && print_success "local_calendar_notes_table.dart exists" || print_error "local_calendar_notes_table.dart missing"
    [ -f "mobile/lib/core/database/daos/calendar_notes_dao.dart" ] && print_success "calendar_notes_dao.dart exists" || print_error "calendar_notes_dao.dart missing"
else
    print_error "Database directory not found"
fi

if [ -f "mobile/lib/core/utils/ethiopian_calendar_util.dart" ]; then
    print_success "ethiopian_calendar_util.dart exists"
else
    print_error "ethiopian_calendar_util.dart missing"
fi

echo ""
echo "📄 Checking Documentation..."
echo "----------------------------"

[ -f "ETHIOPIAN_CALENDAR_FEATURE.md" ] && print_success "Feature documentation exists" || print_warning "Feature documentation missing"
[ -f "CALENDAR_QUICK_START.md" ] && print_success "Quick start guide exists" || print_warning "Quick start guide missing"
[ -f "MIGRATION_CHECKLIST.md" ] && print_success "Migration checklist exists" || print_warning "Migration checklist missing"
[ -f "CALENDAR_IMPLEMENTATION_SUMMARY.md" ] && print_success "Implementation summary exists" || print_warning "Implementation summary missing"

echo ""
echo "🔧 Checking Generated Files..."
echo "-------------------------------"

# Check for generated files
if [ -f "mobile/lib/core/database/app_database.g.dart" ]; then
    print_success "app_database.g.dart generated"
else
    print_warning "app_database.g.dart not generated (run build_runner)"
fi

if [ -f "mobile/lib/features/calendar/domain/calendar_note_model.freezed.dart" ]; then
    print_success "calendar_note_model.freezed.dart generated"
else
    print_warning "calendar_note_model.freezed.dart not generated (run build_runner)"
fi

if [ -f "mobile/lib/features/calendar/domain/calendar_note_model.g.dart" ]; then
    print_success "calendar_note_model.g.dart generated"
else
    print_warning "calendar_note_model.g.dart not generated (run build_runner)"
fi

echo ""
echo "=================================================="
echo "📊 Verification Summary"
echo "=================================================="
echo ""

if [ $errors -eq 0 ]; then
    print_success "All critical checks passed! ✅"
else
    print_error "$errors error(s) found"
fi

if [ $warnings -gt 0 ]; then
    print_warning "$warnings warning(s) found"
fi

echo ""

if [ $errors -eq 0 ] && [ $warnings -eq 0 ]; then
    echo "🎉 Installation looks good!"
    echo ""
    echo "Next steps:"
    echo "1. cd mobile && dart run build_runner build --delete-conflicting-outputs"
    echo "2. cd backend && npx prisma migrate deploy"
    echo "3. cd backend && npm run start:dev"
    echo "4. cd mobile && flutter run"
else
    echo "⚠️  Please fix the issues above before proceeding."
    
    if [ $warnings -gt 0 ] && [ $errors -eq 0 ]; then
        echo ""
        echo "💡 Warnings detected. To fix:"
        echo "   cd mobile && dart run build_runner build --delete-conflicting-outputs"
    fi
fi

echo ""
exit $errors
