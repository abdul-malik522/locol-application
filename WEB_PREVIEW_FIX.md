# Web Preview - Quick Fix Guide

## Current Status

✅ Singleton constructor errors fixed
⚠️  One remaining error: `UserRole.label` extension not recognized in web build

## Quick Solution: Use Linux Desktop (Recommended)

Since Chrome isn't available, **Linux desktop works perfectly**:

```bash
flutter run -d linux
```

This gives you a native preview with all features working!

## Alternative: Fix Web Build

The remaining error is about the `UserRole.label` extension. The extension is defined in `app_constants.dart` but web compiler needs explicit imports.

### Quick Fix Option 1: Use String Instead

In `profile_screen.dart` and `user_profile_screen.dart`, replace:
```dart
label: Text(currentUser.role.label),
```

With:
```dart
label: Text(currentUser.role == UserRole.seller ? 'Seller' : 'Restaurant'),
```

### Quick Fix Option 2: Build & Serve (Any Browser)

Once fixed, build and serve:
```bash
flutter build web --release
cd build/web
python3 -m http.server 8080
```

Then open **http://localhost:8080** in **any browser** (Firefox, Edge, etc.)

## Recommended: Use Linux Desktop

**Fastest and easiest** - just run:
```bash
flutter run -d linux
```

No browser needed, works immediately! 🚀

