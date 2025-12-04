# Quick Fix for "API Key Invalid" Error

## The Issue
Your API key is being rejected on web because of restrictions.

## Temporary Solution (5 Minutes)

### Step 1: Go to Google Cloud Console
https://console.cloud.google.com/apis/credentials

### Step 2: Find Your API Key
Click on: `AIzaSyBrThzOJlW4SbyUHKLoCrv9yK5AAs_esao`

### Step 3: Remove ALL Restrictions (Temporarily)

**Application restrictions:**
- Select: **"None"**
- This allows the key to work everywhere (web, Android, iOS)

**API restrictions:**
- Select: **"Don't restrict key"**
- This enables all Google APIs

### Step 4: SAVE
Click the blue **"SAVE"** button at the bottom

### Step 5: Wait 2-5 Minutes
Google needs time to propagate the changes.

### Step 6: Restart Your App
```bash
# Stop the current app (Ctrl+C)
# Then run:
flutter run -d chrome --web-port=8080
```

### Step 7: Hard Refresh Browser
Press: **Ctrl+Shift+R** (Windows) or **Cmd+Shift+R** (Mac)

---

## ⚠️ IMPORTANT Security Note

**"None" is INSECURE** - Anyone can use your API key if they find it!

This is ONLY for testing. After confirming it works:

1. ✅ Create a separate web-only API key
2. ✅ Restrict the new web key to HTTP referrers
3. ✅ Re-restrict the original key back to Android apps
4. ✅ Follow the guide in `GOOGLE_MAPS_API_SETUP.md`

---

## Check These While You're There

### 1. Billing
- Make sure billing is enabled: https://console.cloud.google.com/billing
- Google requires a credit card even for free tier

### 2. APIs Enabled
Check these are enabled: https://console.cloud.google.com/apis/library

- ✅ Places API
- ✅ Places API (New)
- ✅ Maps JavaScript API
- ✅ Geocoding API
- ✅ Directions API
- ✅ Maps SDK for Android
- ✅ Geolocation API

### 3. Quota
Check you haven't exceeded quota: https://console.cloud.google.com/apis/dashboard

---

## What Happens After You Remove Restrictions

| Before | After (Unrestricted) |
|--------|---------------------|
| ❌ Web blocked | ✅ Web works |
| ✅ Android works | ✅ Android works |
| ❌ Invalid key error | ✅ Valid key |
| ✅ Secure | ⚠️ Less secure |

---

## Test It's Working

After restarting the app, open Chrome DevTools (F12) and check Console:

**Success:**
```
✅ Places API Loaded
✅ No "invalid key" errors
✅ Autocomplete suggestions appear
```

**Still failing:**
- Wait another 5 minutes (propagation can be slow)
- Check billing is enabled
- Check APIs are enabled
- Clear browser cache completely

---

## After Confirming It Works

Follow the proper setup in `GOOGLE_MAPS_API_SETUP.md`:
1. Create a new restricted web key
2. Update the code with the new key
3. Re-restrict the original key back to Android

---

## Common Mistakes

❌ **Not clicking SAVE** - Changes don't apply until you save!
❌ **Not waiting** - Give it 5 minutes after saving
❌ **Not restarting** - Old key is cached, restart the app
❌ **Not refreshing** - Browser caches the old key, hard refresh
❌ **Billing disabled** - Google requires billing to be set up

---

## Still Not Working?

Check the exact error in Chrome DevTools Console (F12):

**"API key not valid"**
→ Wait longer (5-10 minutes) or check billing

**"This API project is not authorized"**
→ Enable the specific API that's being called

**"REQUEST_DENIED"**
→ Billing is not enabled

**Still seeing CORS errors**
→ The key is working! This is a different issue (already fixed in code)

---

## Quick Checklist

Before you try again, verify:

- [ ] Clicked SAVE in Google Cloud Console
- [ ] Waited 5 minutes
- [ ] Billing is enabled
- [ ] All APIs are enabled
- [ ] Restarted Flutter app
- [ ] Hard refreshed browser (Ctrl+Shift+R)
- [ ] Checked console for different error messages

---

Good luck! This should get you working immediately. 🚀


















