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