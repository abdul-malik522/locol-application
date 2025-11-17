#!/bin/bash
# Fast Preview Server - Serves already-built web app

if [ ! -d "build/web" ]; then
    echo "⚠️  Web build not found. Building first..."
    echo "This will take 2-3 minutes (one time only)"
    flutter build web --release
    if [ $? -ne 0 ]; then
        echo "❌ Build failed"
        exit 1
    fi
fi

echo "🚀 Starting preview server..."
echo "📱 Open http://localhost:8080 in your browser"
echo "   Press Ctrl+C to stop"
echo ""

cd build/web
python3 -m http.server 8080
