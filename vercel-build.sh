#!/bin/bash
set -e

# Get the project root directory (where vercel.json is located)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

echo "🚀 Starting Vercel build for Flutter web app..."
echo "📁 Project root: $PROJECT_ROOT"

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
  cd "$PROJECT_ROOT"
else
  echo "Flutter SDK already exists, using cached version"
fi

# Add Flutter to PATH
export PATH="$FLUTTER_SDK_PATH/bin:$PATH"

# Ensure we're in the project root
cd "$PROJECT_ROOT"

# Precache web dependencies to speed up build
echo "📦 Precaching Flutter web dependencies..."
flutter precache --web

# Verify Flutter installation
echo "✅ Flutter version:"
flutter --version

# Enable web support (idempotent)
echo "🌐 Enabling web support..."
flutter config --enable-web --no-analytics

# Verify we're in the right directory and main.dart exists
echo "🔍 Verifying project structure..."
if [ ! -f "lib/main.dart" ]; then
  echo "❌ Error: lib/main.dart not found in current directory: $(pwd)"
  echo "📂 Directory contents:"
  ls -la
  exit 1
fi
echo "✅ Found lib/main.dart"

# Get dependencies
echo "📚 Getting Flutter dependencies..."
flutter pub get

# Build for web with optimizations
echo "🏗️  Building Flutter web app (release mode)..."
flutter build web --release

echo "✅ Build complete! Output in build/web"

