# In-App Update Feature - Play Store Integration

## Overview
Automatic Play Store update check implemented using `in_app_update` package.

## How It Works

### 1. **Automatic Check on App Start**
- When user opens the app, it automatically checks Play Store for updates
- Runs in background, doesn't block app loading

### 2. **Two Types of Updates**

#### **Immediate Update** (Critical/Mandatory)
- Full-screen update prompt
- User MUST update to continue using app
- Use this for critical bug fixes or security updates

#### **Flexible Update** (Optional)
- Bottom sheet from Play Store appears
- User can dismiss and continue playing
- Update downloads in background
- Shows snackbar when ready to install
- Use this for feature updates, improvements

### 3. **Configuration in Play Store Console**

When you upload a new version to Play Store:

1. Go to **Google Play Console**
2. Navigate to **Release > Production**
3. Create new release with higher version number
4. In **Release details**, you can set:
   - **Priority**: 0-5 (higher = more urgent)
   - **Update priority 5** = Immediate update (forced)
   - **Update priority 1-4** = Flexible update (optional)

### 4. **Version Management**

Update version in `pubspec.yaml`:
```yaml
version: 1.0.0+1
         ↑     ↑
         |     Build number (increment for each upload)
         Version name (shown to users)
```

**Example progression:**
- Current: `1.0.0+1`
- Bug fix: `1.0.1+2`
- New feature: `1.1.0+3`
- Major update: `2.0.0+4`

## Files Modified

1. **`pubspec.yaml`**
   - Added `in_app_update: ^4.2.3`

2. **`lib/services/update_service.dart`** (NEW)
   - Handles update checking logic
   - Shows Play Store bottomsheet
   - Manages flexible update downloads

3. **`lib/screens/game_screen.dart`**
   - Added update check in `initState()`
   - Runs after screen loads

## Testing

### During Development
- In-app updates **only work on real devices with Play Store installed**
- **Won't work on emulators or debug builds**
- Must test with **internal testing track** or **closed testing**

### Steps to Test:
1. Upload current version (e.g., 1.0.0+1) to Internal Testing
2. Install on device from Play Store
3. Upload new version (e.g., 1.0.1+2) to Internal Testing
4. Open app on device
5. Play Store update bottomsheet should appear

## Important Notes

- ✅ **Android only** - iOS uses App Store's built-in update system
- ✅ Silently fails if Play Store not available (no error shown to user)
- ✅ Works only with **signed release builds** from Play Store
- ✅ User must have Google Play Services enabled
- ✅ Update check happens once per app launch

## Play Store Bottomsheet Appearance

The bottomsheet will show:
- App icon
- "Update available" message
- Version details
- "Update" button (green)
- "Not now" button (for flexible updates)
- Download progress (for flexible updates)

This is the **native Play Store UI** - you don't need to design it!

## Future Enhancements (Optional)

- Add manual "Check for Updates" button in settings
- Show update changelog/release notes
- Track update install rate in analytics
- Customize update frequency (daily, weekly)
