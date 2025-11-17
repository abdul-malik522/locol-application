#!/bin/bash
# Fast Preview: Build once, serve instantly

echo "🏗️  Building LocalTrade for web (this may take 2-3 minutes)..."
echo ""

flutter build web --release

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build complete!"
    echo ""
    echo "🚀 Starting server on http://localhost:8080"
    echo "   Press Ctrl+C to stop"
    echo ""
    cd build/web
    python3 -m http.server 8080
else
    echo "❌ Build failed. Please check the errors above."
    exit 1
fi
