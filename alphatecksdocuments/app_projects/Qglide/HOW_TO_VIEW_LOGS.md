# How to View App Logs (Release Mode)

Since you're running in release mode (not debug), here are **3 ways** to view the console logs:

## Method 1: View Logs in the App (Easiest) ✅

1. **Open the app** and navigate to **Settings**
2. Scroll down to the **Account** section
3. Tap on **"View App Logs"**
4. You'll see all logs including:
   - Zego token API responses
   - Call service initialization details
   - Error messages with full context
   - All API response structures

**Features:**
- ✅ View logs directly in the app
- ✅ Copy logs to clipboard
- ✅ Refresh to see latest logs
- ✅ Clear logs if needed

---

## Method 2: Using Flutter Commands (Terminal)

### For Android:
```bash
# Connect your device via USB and run:
flutter logs

# Or use ADB directly:
adb logcat | grep -i "qglide\|zego\|call"
```

### For iOS:
```bash
# Connect your device via USB and run:
flutter logs

# Or use Xcode Console:
# Open Xcode → Window → Devices and Simulators → Select your device → View Device Logs
```

### For macOS/Windows/Linux:
```bash
# Just run:
flutter logs
```

---

## Method 3: Access Log File Directly

The app saves logs to a file that you can access:

### Android:
```bash
# Get the log file path (shown in the app's log viewer)
adb pull /storage/emulated/0/Android/data/com.alphatecks.qglide/files/QGlideLogs/qglide_crash_logs.txt

# Or access via file manager:
# Internal Storage → Android → data → com.alphatecks.qglide → files → QGlideLogs → qglide_crash_logs.txt
```

### iOS:
```bash
# Use Xcode to download container:
# Xcode → Window → Devices → Select device → Select app → Download Container
# Then navigate to: AppData/Documents/qglide_crash_logs.txt
```

### macOS:
```bash
# Log file location:
~/Library/Containers/com.alphatecks.qglide/Data/Documents/qglide_crash_logs.txt
```

---

## What Gets Logged?

The app now logs **all important events** to the file, including:

- ✅ **Zego Token API Responses** - Full response structure
- ✅ **Token Parsing** - What fields were extracted
- ✅ **Validation Errors** - Detailed error messages with available keys
- ✅ **Call Service Events** - Initialization, registration, errors
- ✅ **API Calls** - Request/response details
- ✅ **Errors** - Stack traces and error context

---

## Quick Debugging Tips

1. **When login fails:**
   - Open Settings → View App Logs
   - Look for "Zego Token API Response Structure"
   - Check what keys are available in the response
   - The error message will show exactly what's missing

2. **When calls fail:**
   - Check logs for "CallService" entries
   - Look for initialization errors
   - Check token validation errors

3. **To share logs with developers:**
   - Open Settings → View App Logs
   - Tap "Copy logs" button
   - Paste and share

---

## Example Log Entry

```
[2025-12-02 14:30:15.123] INFO: 📞 Zego Token API Response Structure:
[2025-12-02 14:30:15.124] INFO:    result keys: (success, data)
[2025-12-02 14:30:15.125] INFO:    data type: _InternalLinkedHashMap<String, dynamic>
[2025-12-02 14:30:15.126] INFO:    data keys: (token, user_id, app_id)
[2025-12-02 14:30:15.127] INFO:    Full data: {token: abc123..., user_id: user123, app_id: 123456}
[2025-12-02 14:30:15.128] INFO: 📞 Extracted Zego Token Data:
[2025-12-02 14:30:15.129] INFO:    token: abc123...
[2025-12-02 14:30:15.130] INFO:    userID: user123
[2025-12-02 14:30:15.131] INFO:    appID: 123456
```

---

**Note:** All logs are automatically saved to a file, so you can view them even after closing the app. The log file is rotated when it gets too large (keeps last 1000 lines).


