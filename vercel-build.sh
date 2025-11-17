#!/bin/bash
set -e

echo "🚀 Starting Vercel build for Flutter web app..."

# Install Flutter SDK
echo "📦 Installing Flutter SDK..."
FLUTTER_SDK_PATH="$HOME/flutter"

if [ ! -d "$FLUTTER_SDK_PATH" ]; then
  echo "Downloading Flutter SDK (this may take a few minutes)..."
  cd $HOME
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 $FLUTTER_SDK_PATH
  cd $FLUTTER_SDK_PATH
  git fetch --depth 1 origin stable
  git checkout stable
else
  echo "Flutter SDK already exists, using cached version"
fi

# Add Flutter to PATH
export PATH="$FLUTTER_SDK_PATH/bin:$PATH"

# Precache web dependencies to speed up build
echo "📦 Precaching Flutter web dependencies..."
flutter precache --web

# Verify Flutter installation
echo "✅ Flutter version:"
flutter --version

# Enable web support (idempotent)
echo "🌐 Enabling web support..."
flutter config --enable-web --no-analytics

# Get dependencies
echo "📚 Getting Flutter dependencies..."
flutter pub get

# Build for web with optimizations
echo "🏗️  Building Flutter web app (release mode)..."
flutter build web --release --web-renderer canvaskit

echo "✅ Build complete! Output in build/web"

