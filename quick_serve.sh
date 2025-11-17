#!/bin/bash
# Quick Serve: If already built, serve instantly

if [ ! -d "build/web" ]; then
    echo "❌ Web build not found. Building first..."
    flutter build web --release
fi

echo "🚀 Serving on http://localhost:8080"
echo "   Press Ctrl+C to stop"
cd build/web
python3 -m http.server 8080
