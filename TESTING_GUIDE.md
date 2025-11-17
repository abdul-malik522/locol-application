# LocalTrade Testing Guide

## Quick Start Testing

### Option 1: Install Flutter and Run Locally

1. **Install Flutter** (if not already installed):
   ```bash
   # On WSL2/Linux
   sudo snap install flutter --classic
   # OR download from https://flutter.dev/docs/get-started/install/linux
   
   # Verify installation
   flutter doctor
   ```

2. **Get Dependencies**:
   ```bash
   cd /home/bu2lo/LOCOL
   flutter pub get
   ```

3. **Run the App**:
   ```bash
   # For mobile device/emulator
   flutter run
   
   # For web preview
   flutter run -d chrome
   # OR
   flutter run -d web-server --web-port=8080
   ```

### Option 2: Web Preview (Recommended for Quick Testing)

1. **Enable Web Support**:
   ```bash
   flutter config --enable-web
   ```

2. **Build for Web**:
   ```bash
   flutter build web
   ```

3. **Serve Locally**:
   ```bash
   # Using Python (if available)
   cd build/web
   python3 -m http.server 8080
   
   # OR using Node.js http-server
   npx http-server build/web -p 8080
   ```

4. **Access Preview**:
   - Open browser: `http://localhost:8080`
   - Or share your local IP for network access

### Option 3: Use Flutter DevTools

```bash
flutter pub global activate devtools
flutter pub global run devtools
```

## Testing Checklist

### 1. Authentication Flow ✅
- [ ] Splash screen appears on launch
- [ ] Welcome/onboarding slides work
- [ ] Role selection (Seller/Restaurant)
- [ ] Registration form validation
- [ ] Login with existing credentials
- [ ] Auth persistence (restart app, should stay logged in)
- [ ] Logout functionality

**Test Credentials** (from mock data):
- Email: `john@example.com`, Password: `password123`
- Email: `maria@example.com`, Password: `password123`

### 2. Home Feed ✅
- [ ] Posts load and display correctly
- [ ] Infinite scroll works
- [ ] Pull-to-refresh works
- [ ] Filter by role works
- [ ] Like button works
- [ ] Post detail screen opens
- [ ] Comments can be added
- [ ] Image carousel works

### 3. Search ✅
- [ ] Search input works
- [ ] Filters apply correctly
- [ ] Category browsing works
- [ ] Recent searches save
- [ ] Results display properly

### 4. Create Post ✅
- [ ] Image picker works (gallery/camera)
- [ ] Multiple images can be selected
- [ ] Form validation works
- [ ] Location capture works
- [ ] Post submission works
- [ ] Post appears in feed after creation

### 5. Messaging ✅
- [ ] Chat list displays
- [ ] Unread badges show correctly
- [ ] Chat screen opens
- [ ] Messages send/receive
- [ ] Image messages work
- [ ] Mark as read works
- [ ] Swipe actions work

### 6. Orders ✅
- [ ] Orders list displays
- [ ] Status tabs work
- [ ] Order cards show correctly
- [ ] Statistics display
- [ ] Cancel order works
- [ ] Rate order works
- [ ] Reorder works

### 7. Profile ✅
- [ ] Own profile displays
- [ ] Edit profile works
- [ ] Profile image can be changed
- [ ] Other user profiles display
- [ ] Stats show correctly
- [ ] Tabs work (Posts, Reviews, About)
- [ ] Contact button navigates to chat

### 8. Notifications ✅
- [ ] Notifications list displays
- [ ] Mark as read works
- [ ] Delete notification works
- [ ] Mark all as read works
- [ ] Clear all works
- [ ] Unread count badge works

### 9. Settings ✅
- [ ] Theme toggle works (light/dark/system)
- [ ] Settings list displays
- [ ] Navigation to other screens works

## Known Limitations

1. **Mock Data**: All data is in-memory and resets on app restart
2. **Permissions**: Location and camera permissions need to be granted on device
3. **Network Images**: Uses placeholder images from `pravatar.cc`
4. **Placeholder Features**: Some features show "coming soon" messages (see REVIEW.md)

## Troubleshooting

### Flutter Not Found
```bash
# Add Flutter to PATH
export PATH="$PATH:/path/to/flutter/bin"
```

### Web Build Issues
```bash
# Enable web support
flutter config --enable-web

# Clean and rebuild
flutter clean
flutter pub get
flutter build web
```

### Permission Issues
- Android: Check `android/app/src/main/AndroidManifest.xml`
- iOS: Check `ios/Runner/Info.plist`
- Web: Permissions handled by browser

### Hot Reload Not Working
```bash
# Use hot restart instead
# Press 'R' in terminal or use IDE hot restart button
```

## Performance Testing

- Test on different screen sizes
- Test with slow network (use Chrome DevTools throttling)
- Test with many posts/orders/messages
- Test theme switching performance
- Test scroll performance

## Browser Compatibility (Web)

- Chrome/Edge: ✅ Full support
- Firefox: ✅ Full support
- Safari: ⚠️ Some features may vary

## Next Steps After Testing

1. Fix any bugs found
2. Replace mock datasources with real backend
3. Add error handling improvements
4. Optimize performance
5. Add analytics
6. Prepare for production build

