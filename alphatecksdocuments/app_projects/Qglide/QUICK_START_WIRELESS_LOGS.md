# Quick Start: Wireless Log Monitoring

## One-Time Setup (5 minutes)

### 1. Connect Device via USB (First Time Only)

```bash
# Enable USB Debugging on your Android device
# Settings → Developer Options → USB Debugging

# Verify connection
adb devices
```

### 2. Enable Wireless ADB

**On your Android device:**
- Find IP address: Settings → WiFi → Tap your network → IP Address
- Example IP: `192.168.1.100`

**On your computer:**
```bash
adb tcpip 5555
adb connect 192.168.1.100:5555
```

**Verify:**
```bash
adb devices
# Should show: 192.168.1.100:5555    device
```

**Unplug USB** - You're now wireless! 🎉

## Daily Use

### Option 1: Use the Script (Easiest)

**macOS/Linux:**
```bash
./monitor_logs.sh zego
```

**Windows:**
```cmd
monitor_logs.bat zego
```

### Option 2: Manual Commands

**Monitor Zego/Call logs:**
```bash
adb logcat | grep -iE "(zego|callservice|📞|token)"
```

**Monitor errors only:**
```bash
adb logcat | grep -iE "(qglide|zego)" | grep -iE "(error|exception)"
```

**Save logs to file:**
```bash
adb logcat | grep -i qglide > logs.txt
```

## Common Filters

| Filter | Command |
|--------|---------|
| All QGlide logs | `adb logcat \| grep -i qglide` |
| Zego/Call logs | `adb logcat \| grep -iE "(zego\|callservice\|📞)"` |
| Errors only | `adb logcat \| grep -iE "(qglide\|zego)" \| grep -iE "(error\|exception)"` |
| Login flow | `adb logcat \| grep -iE "(login\|auth\|token)"` |
| API responses | `adb logcat \| grep -iE "(api\|response\|token)"` |

## Troubleshooting

**Device not found?**
```bash
adb connect <YOUR_IP>:5555
```

**Connection dropped?**
```bash
adb kill-server
adb start-server
adb connect <YOUR_IP>:5555
```

**Need to reconnect after reboot?**
- Re-run: `adb connect <YOUR_IP>:5555`

## Pro Tips

1. **Keep terminal open** - Leave logcat running while testing
2. **Use multiple terminals** - One for errors, one for all logs
3. **Save important logs** - When error occurs, save immediately
4. **Filter aggressively** - Reduce noise with specific filters

## What to Look For

When debugging the Zego token issue, watch for:
- `📞 Zego Token API Response Structure:` - Shows API response
- `Empty or missing Zego token` - The actual error
- `tokenData keys:` - Shows what fields are available
- `Full data:` - Complete API response

---

**Full guide:** See `WIRELESS_LOG_MONITORING.md` for detailed instructions.


