#!/bin/bash
# Check Flutter installation status

echo "🔍 Checking Flutter status..."
echo ""

if command -v flutter &> /dev/null; then
    echo "✅ Flutter is installed"
    flutter --version | head -1
    echo ""
    echo "Running flutter doctor..."
    flutter doctor
else
    echo "⏳ Flutter is still installing..."
    echo ""
    echo "Check installation progress with:"
    echo "  ps aux | grep flutter"
    echo ""
    echo "Or wait a few minutes and try:"
    echo "  flutter doctor"
fi
