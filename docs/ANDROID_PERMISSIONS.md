# Android Permissions Documentation

This document details all permissions used by IA Helper and their justifications for Google Play Store compliance.

## Permission Strategy

IA Helper follows Android best practices for permissions:
- **Runtime permissions**: All dangerous permissions requested only when needed
- **Minimal permissions**: Only essential permissions for core functionality
- **Clear justifications**: Each permission has a specific, user-facing purpose
- **Graceful degradation**: App functions with limited permissions (reduced features)
- **Version-specific**: Uses appropriate permissions for each Android version

## Required Permissions

### 1. INTERNET (Normal Permission)
- **Permission**: `android.permission.INTERNET`
- **Protection Level**: Normal (granted automatically)
- **Purpose**: Download files from Internet Archive (archive.org)
- **Justification**: Core functionality - app downloads files from archive.org API
- **User Control**: None needed (normal permission)
- **Alternatives**: None - app cannot function without internet access
- **Play Store**: Always approved for download manager apps

### 2. ACCESS_NETWORK_STATE (Normal Permission)
- **Permission**: `android.permission.ACCESS_NETWORK_STATE`
- **Protection Level**: Normal (granted automatically)
- **Purpose**: Detect connection type and network availability
- **Justification**: 
  - Pause downloads on poor/expensive connections (cellular data)
  - Resume downloads when Wi-Fi available
  - Display network status to user
  - Prevent download failures due to network changes
- **User Control**: None needed (normal permission)
- **Alternatives**: Could download blindly, but wastes data and causes failures
- **Play Store**: Standard for download manager apps

## Storage Permissions (Version-Specific Strategy)

IA Helper uses different storage permissions based on Android version to follow platform evolution:

### Android 5-9 (API 21-28): Legacy Storage

#### WRITE_EXTERNAL_STORAGE (Dangerous Permission)
- **Permission**: `android.permission.WRITE_EXTERNAL_STORAGE`
- **Max SDK Version**: 28 (Android 9 and below)
- **Purpose**: Save downloaded files to external storage
- **Justification**: 
  - Users expect downloads in Downloads folder
  - Files accessible by other apps (file managers, media players)
  - Persistent storage survives app uninstall
- **User Control**: Runtime permission dialog on first download
- **Alternatives**: App-private storage (not user-accessible)
- **Play Store**: Standard for download manager apps on older Android

### Android 10-12 (API 29-32): Scoped Storage

#### READ_EXTERNAL_STORAGE (Dangerous Permission)
- **Permission**: `android.permission.READ_EXTERNAL_STORAGE`
- **Max SDK Version**: 32 (Android 12 and below)
- **Purpose**: Read existing files for verification and resume capability
- **Justification**:
  - Verify file integrity before resume
  - Check available storage space
  - Resume interrupted downloads
  - Read downloaded file metadata
- **User Control**: Runtime permission dialog
- **Alternatives**: Can't resume downloads or verify files
- **Play Store**: Standard for download manager apps

**Note**: On Android 10+, apps use Scoped Storage which limits access to only appropriate directories (Downloads, Documents, etc.) without requiring broad storage permissions for writes.

### Android 13+ (API 33+): Granular Media Permissions

#### READ_MEDIA_IMAGES (Dangerous Permission)
- **Permission**: `android.permission.READ_MEDIA_IMAGES`
- **Purpose**: Access downloaded image files from Internet Archive
- **Justification**:
  - Many Internet Archive items are historical images
  - Users browse downloaded images in app library
  - Display thumbnails and previews
- **User Control**: Runtime permission dialog (images only)
- **Alternatives**: Downloads work but can't show image previews
- **Play Store**: Granular permission - better privacy than broad storage

#### READ_MEDIA_VIDEO (Dangerous Permission)
- **Permission**: `android.permission.READ_MEDIA_VIDEO`
- **Purpose**: Access downloaded video files from Internet Archive
- **Justification**:
  - Internet Archive hosts classic films and historical videos
  - Users can view downloaded videos in app library
  - Display video thumbnails and metadata
- **User Control**: Runtime permission dialog (videos only)
- **Alternatives**: Downloads work but can't show video previews
- **Play Store**: Granular permission - better privacy than broad storage

#### READ_MEDIA_AUDIO (Dangerous Permission)
- **Permission**: `android.permission.READ_MEDIA_AUDIO`
- **Purpose**: Access downloaded audio files from Internet Archive
- **Justification**:
  - Internet Archive hosts music, audiobooks, podcasts, historical recordings
  - Users can play downloaded audio in app library
  - Display audio metadata (artist, album, duration)
- **User Control**: Runtime permission dialog (audio only)
- **Alternatives**: Downloads work but can't show audio library
- **Play Store**: Granular permission - better privacy than broad storage

### Android 14+ (API 34+): Partial Media Access

#### READ_MEDIA_VISUAL_USER_SELECTED (Dangerous Permission)
- **Permission**: `android.permission.READ_MEDIA_VISUAL_USER_SELECTED`
- **Purpose**: Allow user to grant access to only specific photos/videos
- **Justification**:
  - User can select which media to share with app
  - Better privacy - no full media library access required
  - Follows Android 14+ "Privacy by Design" principles
- **User Control**: Photo picker UI (user selects specific files)
- **Alternatives**: Full READ_MEDIA_IMAGES/VIDEO access
- **Play Store**: Preferred over full media access on Android 14+

## Optional Permissions

### POST_NOTIFICATIONS (Android 13+, API 33+)
- **Permission**: `android.permission.POST_NOTIFICATIONS`
- **Protection Level**: Dangerous (requires runtime permission)
- **Purpose**: Show download progress notifications
- **Justification**:
  - Users want to see download progress in notification shade
  - Notify when downloads complete
  - Alert on download errors
  - Allow pause/resume from notifications
- **User Control**: Runtime permission dialog
- **Alternatives**: No notifications (downloads continue silently)
- **Graceful Degradation**: Downloads work without notifications
- **Play Store**: Standard for download manager apps

### MANAGE_EXTERNAL_STORAGE (Android 11+, API 30+)
- **Permission**: `android.permission.MANAGE_EXTERNAL_STORAGE`
- **Protection Level**: Special (requires manual grant in Settings)
- **Purpose**: **OPTIONAL** - Full storage access for power users
- **Justification**:
  - Advanced users can save to any directory
  - Batch organize existing downloads
  - Access app files in custom locations
- **User Control**: Manual grant in Settings (never auto-requested)
- **Alternatives**: Scoped Storage (Downloads directory only)
- **Graceful Degradation**: App works fully without this permission
- **Play Store**: **Requires special approval** - only for file managers/download managers
- **Important**: This is never requested automatically - user must enable in Settings

**Play Store Compliance Note**: While this permission is declared, it's never requested at runtime. Apps with this permission must meet Play Store special requirements:
1. Core functionality must require broad files access
2. Alternatives (Scoped Storage) must be insufficient
3. Clear explanation in app description
4. Will require Play Store review approval

## Permission Request Flow

### First Launch
1. App loads without requesting permissions
2. User browses Internet Archive catalog
3. User can search and view item details

### First Download
1. User clicks download button
2. App checks if storage permission granted:
   - **Android 10+**: Uses Scoped Storage (no permission dialog)
   - **Android 5-9**: Shows storage permission dialog
3. If denied: Shows explanation dialog with "Settings" button
4. Download begins after permission granted

### Notifications (Android 13+)
1. App checks if notification permission granted
2. If not: Shows permission rationale dialog
3. If granted: Shows download progress notifications
4. If denied: Downloads continue without notifications

### Media Access (Android 13+)
1. User opens Library screen
2. App checks if media permissions granted
3. If not: Shows explanation of benefits (thumbnails, metadata)
4. User can grant images, videos, audio individually
5. If denied: Library shows file names only (no previews)

## User Control & Privacy

### Permission Management
Users can control all permissions in Android Settings:
- **Settings → Apps → IA Helper → Permissions**
- Grant or revoke any dangerous permission
- View permission usage history (Android 12+)

### App Behavior When Permissions Denied

#### Storage Permission Denied (Android 5-9)
- **Impact**: Cannot download files
- **Mitigation**: Clear explanation dialog with "Go to Settings" button
- **Alternative**: Use app-private storage (not user-accessible)

#### Read Storage Denied (Android 10-12)
- **Impact**: Cannot resume interrupted downloads
- **Mitigation**: Downloads restart from beginning
- **Alternative**: None for resume functionality

#### Media Permissions Denied (Android 13+)
- **Impact**: Cannot show thumbnails/previews in Library
- **Mitigation**: Shows file names and metadata only
- **Alternative**: User can open files in external apps

#### Notifications Denied (Android 13+)
- **Impact**: No download progress notifications
- **Mitigation**: In-app progress bar still works
- **Alternative**: User checks app manually for status

### Privacy Protections
- **No data collection**: Permissions used only for stated purposes
- **No tracking**: No analytics or telemetry using permission data
- **Local only**: All file access stays on device
- **No uploads**: App never uploads user files (except future opt-in feature)
- **No sharing**: Downloaded files not shared with third parties

## Play Store Compliance Checklist

### Required for Approval
- [x] All permissions have clear, user-facing justifications
- [x] Permissions used only for core functionality
- [x] No unnecessary or excessive permissions
- [x] Runtime permission requests follow best practices
- [x] Graceful degradation when permissions denied
- [x] Privacy policy explains permission usage
- [x] App description mentions storage requirements

### MANAGE_EXTERNAL_STORAGE Special Approval
If Google requests justification:
- **Primary use case**: Download manager for Internet Archive files
- **Why scoped storage insufficient**: Users download thousands of mixed file types
- **User benefit**: Save downloads to any custom directory
- **Alternatives provided**: App works fully with scoped storage (Downloads only)
- **Declaration**: Never requested at runtime, must be manually enabled in Settings

### Version-Specific Testing
- [x] Test on Android 5-9 (legacy storage)
- [x] Test on Android 10-12 (scoped storage)
- [x] Test on Android 13+ (granular media)
- [x] Test on Android 14+ (partial media)
- [x] Verify graceful degradation on all versions

## Comparison to Competitors

### Internet Archive Official App
- Permissions: INTERNET only
- Limitation: No offline downloads, online streaming only
- IA Helper Advantage: Full download capability

### Generic Download Managers (IDM, ADM)
- Permissions: Same as IA Helper + browser integration
- Limitation: Not optimized for Internet Archive
- IA Helper Advantage: Purpose-built for archive.org

### File Manager Apps
- Permissions: MANAGE_EXTERNAL_STORAGE (required)
- Limitation: Full storage access always required
- IA Helper Advantage: Works with scoped storage, MANAGE optional

## Future Considerations

### Upload Support (Version 2.0)
When upload feature added:
- Will need same permissions (already have them)
- No new permissions required
- User control: Uploads opt-in only
- Rename: "Downloads" → "Transfers"

### Cloud Sync (Future)
If added, may need:
- Google Drive API (no new permissions)
- Dropbox API (no new permissions)
- Account access (sign-in only, no contacts/email)

## Developer Contact

**Questions about permissions?**
- Email: gameaday.project@gmail.com
- GitHub Issues: github.com/gameaday/ia-helper/issues

---

**Last Updated**: October 8, 2025  
**App Version**: 1.0.0  
**Target SDK**: 34 (Android 14)  
**Min SDK**: 21 (Android 5.0)  
**Status**: Ready for Play Store submission
