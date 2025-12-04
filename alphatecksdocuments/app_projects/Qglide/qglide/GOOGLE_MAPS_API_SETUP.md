# Google Maps API Key Setup for QGlide

## Current Status
The app uses **one API key** for both Android and Web. For production, you should create **separate keys** for better security and cost control.

## Files That Use API Keys

### 1. Android/iOS (Mobile)
- **File:** `android/app/src/main/AndroidManifest.xml`
- **Current Key:** `AIzaSyBrThzOJlW4SbyUHKLoCrv9yK5AAs_esao`
- **Dart Files:** 
  - `lib/services/places_service.dart` (line 12)
  - `lib/services/location_service.dart` (line 8)

### 2. Web
- **File:** `web/index.html` (line 38)
- **Current Key:** `AIzaSyBrThzOJlW4SbyUHKLoCrv9yK5AAs_esao` (same as mobile)
- **Dart Files:**
  - `lib/services/places_service.dart` (line 15)
  - `lib/services/location_service.dart` (line 9)

---

## How to Create Separate API Keys (Recommended)

### Step 1: Go to Google Cloud Console
Visit: https://console.cloud.google.com/apis/credentials

### Step 2: Create Android/iOS Key

1. Click **"+ CREATE CREDENTIALS" → "API key"**
2. Copy the key and save it as **"Android/iOS Key"**
3. Click **"RESTRICT KEY"**
4. Under **"Application restrictions"**:
   - Select **"Android apps"**
   - Click **"+ ADD AN ITEM"**
   - Package name: `com.yourcompany.qglide` (check `android/app/build.gradle.kts`)
   - SHA-1: Get from terminal with:
     ```bash
     keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
     ```
5. Under **"API restrictions"**:
   - Select **"Restrict key"**
   - Enable:
     - ✅ Maps SDK for Android
     - ✅ Places API
     - ✅ Geocoding API
     - ✅ Directions API
6. Click **"SAVE"**

### Step 3: Create Web Key

1. Click **"+ CREATE CREDENTIALS" → "API key"**
2. Copy the key and save it as **"Web Key"**
3. Click **"RESTRICT KEY"**
4. Under **"Application restrictions"**:
   - Select **"HTTP referrers (web sites)"**
   - Click **"+ ADD AN ITEM"**
   - Add: `http://localhost:*`
   - Add: `http://127.0.0.1:*`
   - Add: `https://yourdomain.com/*` (for production)
5. Under **"API restrictions"**:
   - Select **"Restrict key"**
   - Enable:
     - ✅ Maps JavaScript API
     - ✅ Places API
     - ✅ Geocoding API
     - ✅ Directions API
6. Click **"SAVE"**

### Step 4: Update Your Code

#### Android Key
Update `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ANDROID_KEY_HERE"/>
```

Update `lib/services/places_service.dart` (line 12):
```dart
static const String _mobileApiKey = 'YOUR_ANDROID_KEY_HERE';
```

Update `lib/services/location_service.dart` (line 8):
```dart
static const String _mobileApiKey = 'YOUR_ANDROID_KEY_HERE';
```

#### Web Key
Update `web/index.html` (line 38):
```html
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_WEB_KEY_HERE&libraries=geometry,places"></script>
```

Update `lib/services/places_service.dart` (line 15):
```dart
static const String _webApiKey = 'YOUR_WEB_KEY_HERE';
```

Update `lib/services/location_service.dart` (line 9):
```dart
static const String _webApiKey = 'YOUR_WEB_KEY_HERE';
```

---

## Quick Fix for Current CORS Issue on Web

If you're seeing `403 Forbidden` errors on web with `cors-anywhere.herokuapp.com`:

### Option A: Temporary (for testing only)
1. Visit: https://cors-anywhere.herokuapp.com/corsdemo
2. Click **"Request temporary access to the demo server"**
3. This gives you a few hours of access

### Option B: Permanent (recommended)
1. Configure your current API key to allow HTTP referrers:
   - Go to: https://console.cloud.google.com/apis/credentials
   - Click on your API key
   - Under **"Application restrictions"**, select **"HTTP referrers (web sites)"**
   - Add: `http://localhost:*` and `http://127.0.0.1:*`
   - Click **"SAVE"**
2. Wait 5 minutes for changes to propagate
3. Restart your Flutter web app

---

## Required Google Cloud APIs

Make sure these APIs are enabled in your Google Cloud project:
- ✅ Maps SDK for Android
- ✅ Maps SDK for iOS
- ✅ Maps JavaScript API
- ✅ Places API
- ✅ Places API (New)
- ✅ Geocoding API
- ✅ Directions API
- ✅ Geolocation API

Enable them at: https://console.cloud.google.com/apis/library

---

## Billing

⚠️ **Important:** Google Maps requires a billing account to be set up, even though there's a generous free tier ($200/month credit).

Without billing:
- API calls will fail with errors
- Keys won't work even if properly configured

Set up billing at: https://console.cloud.google.com/billing

---

## Testing Your Keys

### Test Android Key
Run the app on an Android device or emulator:
```bash
flutter run
```

### Test Web Key
Run the app on Chrome:
```bash
flutter run -d chrome --web-port=8080
```

### Debug Console
Check browser console (F12) for any API errors:
- ✅ "Places API Loaded" = Success
- ❌ "403 Forbidden" = Key restrictions issue
- ❌ "API not enabled" = Enable the API in Google Cloud Console

---

## Security Best Practices

1. **Never commit API keys to public repositories**
   - Use environment variables for production
   - Add to `.gitignore` if storing in config files

2. **Use separate keys for dev/staging/production**

3. **Set up billing alerts** to avoid unexpected charges

4. **Monitor API usage** in Google Cloud Console

5. **Rotate keys periodically** for security

---

## Troubleshooting

### "Places API not working on web"
- ✅ Check if `places` library is in `web/index.html`
- ✅ Check API key restrictions allow HTTP referrers
- ✅ Wait 5 minutes after changing restrictions
- ✅ Clear browser cache and hard refresh (Ctrl+Shift+R)

### "403 Forbidden on cors-anywhere"
- This is expected - the public CORS proxy is restricted
- Configure your API key for HTTP referrers (see Option B above)

### "API key not valid" on Android
- Check package name matches in Google Cloud Console
- Add SHA-1 fingerprint for the keystore you're using
- For debug builds, use debug keystore SHA-1

---

## Support

For issues with Google Maps API:
- Google Maps Platform Documentation: https://developers.google.com/maps/documentation
- Stack Overflow: https://stackoverflow.com/questions/tagged/google-maps-api

For QGlide app-specific issues:
- Check the console logs for detailed error messages
- Verify all files have been updated with correct keys


















