#!/bin/bash
set -e

FLUTTER_DIR="$HOME/flutter"

if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  echo "Flutter not found. Installing Flutter..."
  git clone https://github.com/flutter/flutter.git \
    --depth 1 \
    -b stable \
    "$FLUTTER_DIR"
else
  echo "Flutter already exists. Reusing cached Flutter SDK."
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

flutter --version

flutter config --enable-web

flutter pub get

flutter build web \
  --release \
  -t lib/main.dart

# Ensure Render SPA rewrite rule is present in publish directory
if [ -f web/_redirects ]; then
  cp web/_redirects build/web/_redirects
else
  echo "/*    /index.html   200" > build/web/_redirects
fi
echo "✓ Web build complete with SPA rewrite rules."