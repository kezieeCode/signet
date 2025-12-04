#!/bin/bash

# QGlide Crash Log Viewer Script
# This script helps you view crash logs from your release APK

echo "=========================================="
echo "QGlide Crash Log Viewer"
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

# Menu
echo "Select an option:"
echo "1. Capture logs continuously during testing (RECOMMENDED)"
echo "2. View real-time logs (Ctrl+C to stop)"
echo "3. View crash log file from app"
echo "4. Save recent logs to file"
echo "5. View only errors and warnings"
echo "6. Clear logcat buffer and start fresh"
echo ""

read -p "Enter option (1-6): " option

case $option in
    1)
        echo "=========================================="
        echo "Starting continuous log capture..."
        echo "This will capture logs until you press Ctrl+C"
        echo "=========================================="
        echo ""
        echo "Step 1: Clearing old logs..."
        adb logcat -c
        echo "✅ Log buffer cleared"
        echo ""
        filename="test_logs_$(date +%Y%m%d_%H%M%S).txt"
        echo "Step 2: Starting log capture..."
        echo "Logs will be saved to: $filename"
        echo ""
        echo "⚠️  IMPORTANT: Keep this terminal open and run your app now!"
        echo "When you're done testing, press Ctrl+C to stop capturing."
        echo ""
        echo "Capturing logs... (Press Ctrl+C when done)"
        echo "=========================================="
        adb logcat -v time '*:E' '*:W' 'flutter:*' > "$filename"
        echo ""
        echo "✅ Log capture stopped. Logs saved to: $filename"
        ;;
    2)
        echo "Viewing real-time logs (Press Ctrl+C to stop)..."
        echo ""
        adb logcat | grep -i "qglide\|flutter\|error"
        ;;
    3)
        echo "Attempting to read crash log file..."
        echo ""
        
        # Try external storage first (Android 10+)
        log_path="/storage/emulated/0/Android/data/com.alphatecks.qglide/files/QGlideLogs/qglide_crash_logs.txt"
        if adb shell test -f "$log_path" 2>/dev/null; then
            echo "Found log file at: $log_path"
            echo "=========================================="
            adb shell cat "$log_path"
        else
            # Try app data directory (requires debuggable or root)
            log_path2="/data/data/com.alphatecks.qglide/files/QGlideLogs/qglide_crash_logs.txt"
            echo "Trying alternative path..."
            if adb shell run-as com.alphatecks.qglide cat "$log_path2" 2>/dev/null; then
                echo "Found log file at: $log_path2"
            else
                echo "❌ Could not find crash log file"
                echo "The app may not have created logs yet, or the file is not accessible"
                echo ""
                echo "Try running the app first, then check again"
            fi
        fi
        ;;
    4)
        read -p "Enter filename (default: crash_logs_$(date +%Y%m%d_%H%M%S).txt): " filename
        filename=${filename:-crash_logs_$(date +%Y%m%d_%H%M%S).txt}
        echo "Saving logs to $filename..."
        adb logcat -d > "$filename"
        echo "✅ Logs saved to $filename"
        ;;
    5)
        echo "Viewing errors and warnings only..."
        echo ""
        adb logcat -d '*:E' '*:W' | grep -i "qglide\|flutter"
        ;;
    6)
        echo "Clearing logcat buffer..."
        adb logcat -c
        echo "✅ Buffer cleared"
        echo "Now run your app and use option 1 to view real-time logs"
        ;;
    *)
        echo "Invalid option"
        exit 1
        ;;
esac

