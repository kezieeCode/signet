# Wireless Log Monitoring Guide

This guide shows you how to monitor QGlide app logs in real-time wirelessly using ADB.

## Prerequisites

- Android device and computer on the same WiFi network
- ADB installed on your computer
- USB cable (for initial setup only)

## Step 1: Initial USB Connection (One-Time Setup)

1. **Enable Developer Options** on your Android device:
   - Go to Settings → About Phone
   - Tap "Build Number" 7 times
   - Go back to Settings → Developer Options

2. **Enable USB Debugging**:
   - In Developer Options, enable "USB Debugging"
   - Connect your device via USB

3. **Verify USB Connection**:
   ```bash
   adb devices
   ```
   You should see your device listed.

## Step 2: Set Up Wireless ADB

### Option A: Using ADB Command (Android 11+)

1. **Find your device's IP address**:
   - Settings → About Phone → Status → IP Address
   - Or: Settings → WiFi → Tap your network → IP Address
   - Example: `192.168.1.100`

2. **Connect wirelessly**:
   ```bash
   adb tcpip 5555
   adb connect <DEVICE_IP>:5555
   ```
   Example:
   ```bash
   adb tcpip 5555
   adb connect 192.168.1.100:5555
   ```

3. **Verify wireless connection**:
   ```bash
   adb devices
   ```
   You should see: `192.168.1.100:5555    device`

4. **Disconnect USB** - You can now unplug the cable!

### Option B: Using Wireless Debugging (Android 11+)

1. **Enable Wireless Debugging**:
   - Settings → Developer Options → Wireless Debugging
   - Enable it

2. **Pair with pairing code**:
   - Tap "Pair device with pairing code"
   - Note the IP address and port (e.g., `192.168.1.100:12345`)
   - Note the 6-digit pairing code

3. **Connect from computer**:
   ```bash
   adb pair <IP>:<PORT>
   ```
   Enter the pairing code when prompted.
   
   Example:
   ```bash
   adb pair 192.168.1.100:12345
   # Enter pairing code: 123456
   ```

4. **Connect to device**:
   ```bash
   adb connect <IP>:<PORT>
   ```
   (Use the IP and port shown in Wireless Debugging settings)

## Step 3: Monitor Logs in Real-Time

### Basic Logcat (All Logs)

```bash
adb logcat
```

### Filter for QGlide App Only

```bash
adb logcat | grep -i qglide
```

### Filter for Zego/Call Service Logs

```bash
adb logcat | grep -iE "(zego|callservice|📞|token)"
```

### Filter for Errors Only

```bash
adb logcat *:E
```

### Filter for QGlide Errors Only

```bash
adb logcat | grep -iE "(qglide|zego|callservice)" | grep -iE "(error|exception|failed)"
```

### Monitor CrashLogger Output (Our Custom Logs)

```bash
adb logcat | grep -iE "(INFO:|ERROR:|WARNING:|📞|Zego Token|CallService)"
```

### Clear Logs and Start Fresh

```bash
adb logcat -c && adb logcat | grep -iE "(qglide|zego|callservice|📞)"
```

## Step 4: Save Logs to File

### Save All Logs

```bash
adb logcat > qglide_logs.txt
```

### Save Filtered Logs

```bash
adb logcat | grep -iE "(qglide|zego|callservice|📞|token)" > qglide_filtered_logs.txt
```

### Save with Timestamps

```bash
adb logcat -v time > qglide_logs_timestamped.txt
```

## Step 5: Useful Logcat Filters

### Monitor Login Flow

```bash
adb logcat | grep -iE "(login|auth|token|zego|callservice)"
```

### Monitor Call Initiation

```bash
adb logcat | grep -iE "(startcall|makecall|zego|room|token)"
```

### Monitor API Responses

```bash
adb logcat | grep -iE "(api|response|token|data|keys)"
```

### Monitor All Custom Logs (CrashLogger)

```bash
adb logcat | grep -E "\[.*\] (INFO|ERROR|WARNING|CALL|NOTIFICATION):"
```

## Step 6: Advanced Monitoring

### Monitor Multiple Tags

```bash
adb logcat -s flutter:V CrashLogger:V ZegoExpressEngine:V
```

### Color-Coded Output (if you have `ccze` installed)

```bash
adb logcat | ccze -A
```

### Follow Logs with Tail (macOS/Linux)

```bash
adb logcat | grep -i qglide | tail -f
```

## Step 7: Reconnect After Device Reboot

If your device reboots, you'll need to reconnect:

```bash
# Find device IP again (if it changed)
adb connect <DEVICE_IP>:5555
```

Or if using Wireless Debugging:
- Re-enable Wireless Debugging on device
- Use the new IP/port shown

## Troubleshooting

### Device Not Found

```bash
# Check if device is connected
adb devices

# If not listed, reconnect
adb connect <DEVICE_IP>:5555

# If still not working, restart ADB server
adb kill-server
adb start-server
adb connect <DEVICE_IP>:5555
```

### Connection Drops

```bash
# Reconnect
adb connect <DEVICE_IP>:5555

# Or restart ADB
adb kill-server && adb start-server
adb connect <DEVICE_IP>:5555
```

### Can't See Logs

Make sure:
1. App is running
2. Logs are being written (check in-app log viewer)
3. Filter isn't too restrictive

## Quick Reference Commands

```bash
# Connect wirelessly
adb tcpip 5555
adb connect <IP>:5555

# Monitor all QGlide logs
adb logcat | grep -i qglide

# Monitor Zego/Call logs
adb logcat | grep -iE "(zego|callservice|📞|token)"

# Monitor errors only
adb logcat | grep -iE "(qglide|zego)" | grep -iE "(error|exception)"

# Save logs to file
adb logcat | grep -i qglide > logs.txt

# Clear logs and start fresh
adb logcat -c && adb logcat | grep -i qglide
```

## Tips

1. **Keep terminal open**: Leave logcat running in a terminal window while testing
2. **Use multiple terminals**: Open separate terminals for different filters
3. **Save important logs**: When you see an error, save the logs immediately
4. **Check timestamps**: Use `-v time` flag to see when events occurred
5. **Filter aggressively**: Use specific filters to reduce noise

## Example Workflow

1. **Start monitoring**:
   ```bash
   adb logcat | grep -iE "(qglide|zego|callservice|📞|token)" > qglide_logs.txt
   ```

2. **Perform actions in app** (login, make call, etc.)

3. **Watch logs in real-time** or check the saved file

4. **When error occurs**, stop logcat (Ctrl+C) and check the file

5. **Share logs**: Send the log file or copy relevant sections


