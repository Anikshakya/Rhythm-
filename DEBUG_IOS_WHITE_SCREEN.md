# iOS Blank White Screen Debugging Guide

## ✅ Changes Made to Your App

I've added comprehensive error handling and logging to identify the root cause of the blank screen:

### 1. **main.dart** - Added ErrorApp Widget
- Displays errors on screen if initialization fails
- Logs each initialization step (AudioService, Controllers)
- Shows full stack traces for debugging

### 2. **LibraryController** - Async Initialization
- Library scanning no longer blocks app startup
- Errors are caught and logged
- App launches even if library scanning fails

### 3. **AudioController** - Error Handling
- Wrapped audio handler binding in try-catch
- Logs audio initialization steps
- Won't crash if audio handler fails

### 4. **OnlineController** - Background Loading
- Online content loads in background
- Network errors won't block startup

### 5. **audio_handler.dart** - Improved Error Logging
- Better error stack trace reporting
- Errors now propagate to ErrorApp

---

## 🔍 How to Find the Problem

### **Option 1: Use VS Code Debug Console**

1. In VS Code, open **Run and Debug** panel
2. Select **Flutter: Attach to Device**
3. Run: `flutter run -v` in terminal
4. Look for console output showing:
   - ❌ FATAL ERROR messages
   - Stack traces
   - Which initialization step failed

### **Option 2: Check Device Console**

On your iPhone/iPad:
1. Open **Settings** → **Developer** (if available)
2. Look for any crash reports
3. Check **Console** app if available

### **Option 3: Use Xcode**

1. Open Xcode: `open ios/Runner.xcworkspace`
2. Select your device
3. Run the app
4. Check Xcode's Console output (Cmd+Shift+C)

---

## 🎯 Common Causes & Solutions

### **1. Audio Service Initialization Fails**

**Symptom:** Error screen shows "AudioService init error"

**Solutions:**
- Ensure iOS 11+ (minimum required)
- Check iOS/Podfile is properly configured
- Try: `flutter clean && flutter pub get && flutter run`

### **2. Permission Issues**

**Symptom:** "Permission denied" in logs

**Solution:** This shouldn't block startup anymore, but if it does:
- The app should show a permission prompt
- Grant "Media & Apple Music" access
- Restart the app

### **3. Database Initialization Fails**

**Symptom:** "Failed to open database" error

**Solution:**
- Delete app from device
- Clean build: `flutter clean`
- Reinstall: `flutter run`

### **4. Library Scanning Blocks Startup**

**Symptom:** App takes 10+ seconds to load with no UI

**Solution:** Already fixed! Library scanning now happens in background.

---

## 📋 Complete Debugging Checklist

- [ ] Run `flutter clean`
- [ ] Run `flutter pub get`
- [ ] Delete app from device
- [ ] Reconnect device (USB)
- [ ] Run `flutter run -v` and check console output
- [ ] If error screen appears, screenshot and note the error message
- [ ] Check Xcode console for native errors
- [ ] Try different iOS versions (simulator vs real device)

---

## 🔧 If You Still Get Blank Screen

### Step 1: Add Minimal App Version

Create a test version of main.dart to isolate the issue:

```dart
void main() {
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Test')),
        body: const Center(child: Text('App Loaded!')),
      ),
    );
  }
}
```

If this works, the issue is in initialization logic.

### Step 2: Progressive Controller Addition

Try adding controllers one by one:

```dart
// Start with just:
Get.put(ThemeController(), permanent: true);
// Test, then add:
Get.put(AudioController(), permanent: true);
// Test, then add:
Get.put(LibraryController(), permanent: true);
// Continue...
```

This will tell you which controller causes the crash.

### Step 3: Audio Service Testing

Test audio service initialization separately:

```dart
try {
  await initAudioService();
  debugPrint('✅ Audio service OK');
} catch (e) {
  debugPrint('❌ Audio service failed: $e');
}
```

---

## 📱 Testing on Real Device vs Simulator

**Real Device Issues Often:**
- Need physical permissions (will prompt user)
- Require proper code signing
- May have different iOS version

**Simulator Issues Often:**
- Missing permissions automatically denied
- Can't access actual music library
- Faster to test & rebuild

**Recommendation:** 
- First test on **simulator** to get debugging info
- Once working, test on **real device**

---

## 💡 Next Steps

1. **Run the app with `-v` flag** to capture debug output
2. **Share any error messages** from the screen or console
3. **Note which step fails:** AudioService, ThemeController, LibraryController, etc.
4. I can provide targeted fixes based on the actual error

---

## 📝 Debug Output Example

When working correctly, you should see:

```
🟡 [1/7] Starting initialization...
🟡 [2/7] Initializing AudioService...
✅ [2/7] AudioService initialized
🟡 [3/7] Injecting ThemeController...
✅ [3/7] ThemeController injected
...
✅ Launching RhythmApp...
```

If you see this but then a blank screen, the issue is in the UI rendering layer.

---

**Need help?** Run the app and share:
1. Console output from `flutter run -v`
2. Any error messages shown on the screen
3. Which initialization step it stops at
