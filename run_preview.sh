#!/bin/bash
# LocalTrade Preview Script

echo "🚀 LocalTrade Preview Setup"
echo "============================"
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed."
    echo ""
    echo "To install Flutter, run:"
    echo "  sudo snap install flutter --classic"
    echo ""
    echo "Or visit: https://flutter.dev/docs/get-started/install/linux"
    exit 1
fi

echo "✅ Flutter found: $(flutter --version | head -1)"
echo ""

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: pubspec.yaml not found. Are you in the project root?"
    exit 1
fi

echo "📦 Getting dependencies..."
flutter pub get

echo ""
echo "🌐 Enabling web support..."
flutter config --enable-web

echo ""
echo "🚀 Starting web preview..."
echo ""
echo "The app will open in your browser."
echo "Preview URL will be shown in the terminal."
echo ""
echo "Press Ctrl+C to stop the server."
echo ""

# Run Flutter web
flutter run -d chrome --web-port=8080

