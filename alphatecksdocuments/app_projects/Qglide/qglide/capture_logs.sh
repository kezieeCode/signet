#!/bin/bash

# QGlide Continuous Log Capture Script
# Run this BEFORE testing your app to capture all logs during testing

echo "=========================================="
echo "QGlide Continuous Log Capture"
echo "=========================================="
echo ""

# Check if adb is available
if ! command -v adb &> /dev/null; then
    echo "❌ Error: adb is not installed or not in PATH"
    echo "Please install Android SDK Platform Tools"
    exit 1
fi

# Check if device is connected
if ! adb devices | grep -q "device$"; then
    echo "❌ Error: No Android device connected"
    echo "Please connect your device and enable USB debugging"
    exit 1
fi

echo "✅ Device connected"
echo ""

# Generate filename with timestamp
filename="test_logs_$(date +%Y%m%d_%H%M%S).txt"

echo "Step 1: Clearing old logs..."
adb logcat -c
echo "✅ Log buffer cleared"
echo ""

echo "Step 2: Starting continuous log capture..."
echo "Log file: $filename"
echo ""
echo "⚠️  IMPORTANT INSTRUCTIONS:"
echo "   1. Keep this terminal window open"
echo "   2. Now run your app and perform your tests"
echo "   3. When you're done testing, press Ctrl+C to stop capturing"
echo ""
echo "=========================================="
echo "Capturing logs... (Press Ctrl+C when done)"
echo "=========================================="
echo ""

# Capture logs with timestamps, errors, warnings, and Flutter logs
adb logcat -v time '*:E' '*:W' 'flutter:*' > "$filename" 2>&1

# When user presses Ctrl+C, show summary
echo ""
echo "=========================================="
echo "Log capture stopped"
echo "=========================================="
echo ""
echo "✅ Logs saved to: $filename"
echo ""
echo "File size: $(du -h "$filename" | cut -f1)"
echo "Total lines: $(wc -l < "$filename")"
echo ""
echo "To view the logs:"
echo "  cat $filename"
echo "  or"
echo "  less $filename"
echo ""

