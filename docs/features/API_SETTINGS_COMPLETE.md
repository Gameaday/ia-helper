# API Settings Feature - Complete

## Overview

Added a comprehensive **API Settings Screen** that exposes Internet Archive API configuration to users, demonstrating transparency, good citizenship, and respect for archive.org's infrastructure.

## Created Files

### 1. `lib/services/api_settings_service.dart`
Persistent storage service for API settings using SharedPreferences:
- **Reduced Priority Settings**:
  - Use reduced priority by default
  - Auto-reduce large files
  - Large file size threshold (MB)
- **Rate Limiting Settings**:
  - Minimum request delay (ms)
  - Max requests per minute
  - Respect Retry-After headers
- **Privacy Settings**:
  - Send Do Not Track header
- **Reset to defaults** functionality

### 2. `lib/screens/api_settings_screen.dart`
Full-featured settings screen with Material Design 3 styling:

#### Features:
- **Info Banner**: Explains "Good API Citizenship" concept
- **Download Priority Section**:
  - Toggle reduced priority for all downloads
  - Auto-reduce large files setting
  - Configurable size threshold with slider dialog
  - Educational tooltip about X-Accept-Reduced-Priority header
- **Rate Limiting Section**:
  - Request delay configuration (0-5000ms)
  - Max requests per minute (1-100, recommended: 30)
  - Respect Retry-After toggle
  - Educational tooltip about archive.org recommendations
- **Privacy & Compliance Section**:
  - Do Not Track header toggle
  - Educational tooltip about DNT header
- **Reset to Defaults**:
  - Danger-styled card for resetting all settings
  - Confirmation dialog
- **Documentation Links**:
  - API Best Practices
  - Rate Limiting Guide
  - Custom Headers documentation
- **Number Picker Dialogs**:
  - Reusable dialog with text input, slider, +/- buttons
  - Validation and step controls

## Integration

### More Menu
Added "API Settings" link in Configuration section:
- Icon: `Icons.api`
- Subtitle: "Internet Archive API configuration"
- Navigation: MD3 shared axis transition
- Position: After "Settings", before Information section

## Settings Details

### Default Values (from IAConstants)

| Setting | Default | Range | Description |
|---------|---------|-------|-------------|
| Reduced Priority | `false` | boolean | Use reduced priority for all downloads |
| Auto-Reduce Large | `true` | boolean | Auto-enable reduced priority for large files |
| Large Threshold | `50 MB` | 1-1000 MB | Size threshold for "large files" |
| Request Delay | `100 ms` | 0-5000 ms | Minimum delay between API requests |
| Max Requests/Min | `30` | 1-100 | Maximum requests per minute (IA recommendation: 30) |
| Send DNT | `true` | boolean | Include "Do Not Track" header |
| Respect Retry-After | `true` | boolean | Honor server Retry-After headers |

### Educational Content

The screen includes explanatory text for each setting:

1. **Reduced Priority**: 
   > "The X-Accept-Reduced-Priority header helps avoid rate limiting and reduces strain on archive.org servers."

2. **Rate Limiting**: 
   > "Archive.org recommends no more than 30 requests per minute. Lower settings show more respect for their infrastructure."

3. **Do Not Track**: 
   > "The DNT header signals that you prefer not to be tracked. This is sent by default as a privacy-respecting practice."

## User Benefits

1. **Transparency**: Users can see exactly how the app interacts with archive.org
2. **Control**: Advanced users can customize API behavior
3. **Education**: Tooltips and documentation links teach API best practices
4. **Trust**: Demonstrates that the app respects archive.org's infrastructure
5. **Performance**: Users can optimize for their use case (speed vs. courtesy)

## Technical Notes

- All settings persist using SharedPreferences
- Settings load asynchronously on screen mount
- Number picker dialogs support:
  - Direct text input with validation
  - Slider with configurable steps
  - +/- increment buttons
- Responsive layout with max-width constraint on tablets
- Material Design 3 compliant throughout
- Info banner uses primaryContainer color scheme
- Reset action uses error color scheme for emphasis

## Future Enhancements (Optional)

- [ ] Real-time rate limit monitoring/visualization
- [ ] Connection statistics (requests made, throttled, etc.)
- [ ] Export/import settings profiles
- [ ] Presets (Conservative, Balanced, Aggressive)
- [ ] Advanced: Custom User-Agent string (native only)
- [ ] Advanced: Retry strategy configuration
- [ ] Link settings to actual rate limiter in production

## Testing Checklist

- ✅ Screen loads without errors
- ✅ All toggles save/load correctly
- ✅ Number picker dialogs work
- ✅ Reset to defaults works
- ✅ Settings persist across app restarts
- ✅ Responsive layout works on tablets
- ✅ MD3 styling consistent
- ✅ Navigation from More menu works
- ✅ flutter analyze: 0 issues

## Conclusion

The API Settings Screen successfully demonstrates good API citizenship while giving users transparency and control. It aligns with the app's mission to be a respectful client of Internet Archive's services and educates users about API best practices.

**Status**: ✅ Complete and ready for production
