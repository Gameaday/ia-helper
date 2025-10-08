# Flutter App Migration Guide: ia-get-cli → ia-helper

**Migration Date**: October 8, 2025  
**From**: github.com/gameaday/ia-get-cli (Rust CLI + Flutter app)  
**To**: github.com/gameaday/ia-helper (Flutter app only)

## Overview

The Flutter mobile app is being separated from the Rust CLI tool into its own dedicated repository. This separation provides several benefits:

### Benefits of Separation

1. **Clear Product Separation**
   - Rust CLI: `ia-get` - Command-line tool for power users
   - Flutter app: `IA Helper` - Mobile companion app
   - Each product has its own identity and branding

2. **Faster CI/CD**
   - No need to build Rust when Flutter changes
   - No need to build Flutter when Rust changes
   - Faster feedback loop for mobile development

3. **Cleaner Play Store Submission**
   - No confusion about repository content
   - All documentation focused on mobile app
   - No unrelated Rust code in submission context

4. **Independent Versioning**
   - Flutter app can have its own release cycle
   - Rust CLI can evolve independently
   - No forced version bumps across products

5. **Better Repository Organization**
   - Mobile-focused issues and PRs
   - Mobile-specific CI/CD workflows
   - Smaller repository size and faster clones

## Rebranding: IA Get → IA Helper

### Name Change Rationale

- **"IA Get"**: Implies download-only functionality
- **"IA Helper"**: Broader scope, companion app positioning
- Better reflects full feature set (search, browse, organize, download)
- More user-friendly and approachable name
- Distinguishes mobile app from CLI tool

### Package Name Change

- **Old**: `com.gameaday.iagetcli`
- **New**: `com.gameaday.iahelper`
- Removes "cli" suffix (not relevant for mobile)
- Aligns with new app name

## Migration Checklist

### Phase 1: Prepare New Repository ✅

- [x] Create new repository: `github.com/gameaday/ia-helper`
- [ ] Initialize with:
  - [ ] README.md (mobile-focused)
  - [ ] LICENSE (same as ia-get-cli)
  - [ ] .gitignore (Flutter-specific)
  - [ ] PRIVACY_POLICY.md (copy from ia-get-cli)
  - [ ] .github/copilot-instructions.md (Flutter-focused)

### Phase 2: Update App Branding

#### Flutter App Configuration
- [ ] `mobile/flutter/pubspec.yaml`
  - [ ] Change name: `ia_get` → `ia_helper`
  - [ ] Update description
  - [ ] Update repository URL

- [ ] `mobile/flutter/android/app/build.gradle`
  - [ ] Change applicationId: `com.gameaday.iagetcli` → `com.gameaday.iahelper`
  - [ ] Update versionName and versionCode

- [ ] `mobile/flutter/android/app/src/main/AndroidManifest.xml`
  - [ ] Update package references
  - [ ] Update app label: `IA Get` → `IA Helper`
  - [ ] Update deep link schemes if needed

- [ ] `mobile/flutter/android/app/src/main/res/values/strings.xml`
  - [ ] Update app_name: `IA Get` → `IA Helper`

- [ ] `mobile/flutter/ios/Runner/Info.plist` (if iOS support added)
  - [ ] Update CFBundleName
  - [ ] Update CFBundleDisplayName

#### Code References
- [ ] Search and replace all "IA Get" → "IA Helper" in:
  - [ ] `lib/**/*.dart` (all Dart files)
  - [ ] Comments and documentation
  - [ ] User-facing strings

- [ ] Search and replace package name in:
  - [ ] `android/**/*.kt` or `*.java`
  - [ ] `android/**/*.xml`
  - [ ] Deep link handling code

#### Assets
- [ ] Update app icons with "IA Helper" branding
- [ ] Update splash screen if it shows app name
- [ ] Update any in-app logos or branding images

### Phase 3: Update Documentation

#### Play Store Documentation
- [x] `docs/PLAY_STORE_METADATA.md`
  - [x] App name: `IA Get` → `IA Helper`
  - [x] Package name updated
  - [x] Short description updated
  - [x] Full description updated
  - [x] GitHub links: `ia-get-cli` → `ia-helper`

- [ ] `docs/ANDROID_PERMISSIONS.md`
  - [ ] Update app name references
  - [ ] Update GitHub links
  - [ ] Update contact information

- [ ] `PRIVACY_POLICY.md`
  - [ ] Update app name: `IA Get` → `IA Helper`
  - [ ] Update repository links
  - [ ] Verify all sections accurate

#### Development Documentation
- [ ] Update README.md (new mobile-focused README)
- [ ] Update CONTRIBUTING.md if exists
- [ ] Update CHANGELOG.md
- [ ] Create MIGRATION.md (this file) in new repo

### Phase 4: Migrate Files to New Repository

#### Directory Structure in ia-helper
```
ia-helper/
├── android/              (from mobile/flutter/android/)
├── ios/                  (from mobile/flutter/ios/)
├── lib/                  (from mobile/flutter/lib/)
├── test/                 (from mobile/flutter/test/)
├── assets/               (from mobile/flutter/assets/)
├── docs/                 (Play Store and development docs)
│   ├── PLAY_STORE_METADATA.md
│   ├── ANDROID_PERMISSIONS.md
│   └── features/         (Phase completion docs)
├── .github/
│   ├── workflows/        (Flutter CI only, no Rust)
│   └── copilot-instructions.md
├── .gitignore            (Flutter-specific)
├── pubspec.yaml          (from mobile/flutter/)
├── analysis_options.yaml (from mobile/flutter/)
├── README.md             (new mobile-focused README)
├── PRIVACY_POLICY.md
├── LICENSE
└── CHANGELOG.md
```

#### Files to Copy
1. **Flutter app** (entire `mobile/flutter/` directory contents)
2. **Documentation** (from `docs/` - mobile-relevant only)
3. **CI/CD** (`.github/workflows/flutter-ci.yml` only)
4. **Privacy policy** (`PRIVACY_POLICY.md`)
5. **License** (`LICENSE`)

#### Files to Create New
1. **README.md** - Mobile app focused, Play Store links
2. **CHANGELOG.md** - Start fresh with 1.0.0
3. **CONTRIBUTING.md** - Mobile development guidelines
4. **.github/copilot-instructions.md** - Flutter/mobile focus

#### Files NOT to Copy
- ❌ Rust source code (`src/`, `Cargo.toml`, `Cargo.lock`)
- ❌ Rust build artifacts (`target/`)
- ❌ Rust CI/CD workflows
- ❌ Rust-specific documentation
- ❌ Benchmark code (`benches/`)
- ❌ Rust examples (`examples/`)

### Phase 5: Update CI/CD

#### New Flutter-Only CI Workflow
**File**: `.github/workflows/flutter-ci.yml`

Changes needed:
- ✅ Already uses `--flavor production` for builds
- ✅ Already uploads APK and AAB artifacts
- ✅ Already generates checksums
- ✅ Already runs Flutter analyze
- ❌ Remove Rust build steps (none currently, but verify)
- ✅ Adjust paths (no `mobile/flutter/` prefix needed)

#### Simplified Build Process
Before (in ia-get-cli):
```
mobile/flutter/
├── lib/
├── android/
└── pubspec.yaml
```

After (in ia-helper):
```
lib/
android/
pubspec.yaml
```

CI commands change:
- Before: `cd mobile/flutter && flutter build apk`
- After: `flutter build apk`

### Phase 6: Update ia-get-cli Repository

After migration complete, update original repository:

#### README.md Updates
```markdown
## Mobile App

The mobile companion app has moved to its own repository:
**[IA Helper](https://github.com/gameaday/ia-helper)**

The mobile app provides a beautiful Material Design 3 interface for:
- Searching the Internet Archive
- Downloading and managing files
- Organizing your digital library
- Offline access to downloaded content

[Download IA Helper from Google Play Store](#) (coming soon)
```

#### Remove or Archive Mobile Code
- Option A: Delete `mobile/` directory entirely
- Option B: Keep as `mobile.archived/` for reference
- Option C: Create `mobile/README.md` pointing to new repo

#### Update CI/CD
- Remove Flutter build steps (if any)
- Focus only on Rust builds
- Faster CI for Rust development

### Phase 7: First Commit to ia-helper

#### Commit Message Template
```
feat: Initial commit - IA Helper mobile app

Migrated Flutter mobile app from ia-get-cli repository to dedicated ia-helper repository.

Changes from ia-get-cli:
- Rebranded from "IA Get" to "IA Helper"
- Updated package name: com.gameaday.iagetcli → com.gameaday.iahelper
- Updated all documentation with new branding
- Simplified directory structure (removed mobile/flutter/ prefix)
- Updated CI/CD for Flutter-only builds
- Updated all GitHub links to new repository

Features (carried over from ia-get-cli):
- ✅ Internet Archive search and browse
- ✅ Download queue with priority management
- ✅ Resumable downloads with auto-retry
- ✅ Material Design 3 UI with dark mode
- ✅ Offline library management
- ✅ Advanced search filters
- ✅ Download scheduling
- ✅ Network-aware downloads

App Status:
- Phase 4 complete (Download Queue Management)
- Phase 5 in progress (Play Store preparation)
- 0 compile errors, 0 warnings
- ~78% Material Design 3 compliant
- Ready for internal testing

Migration documented in: docs/FLUTTER_APP_MIGRATION.md

Original repository: https://github.com/gameaday/ia-get-cli
New repository: https://github.com/gameaday/ia-helper
```

## Code Changes Required

### 1. Package Name Changes

#### android/app/build.gradle
```gradle
android {
    defaultConfig {
        // OLD: applicationId "com.gameaday.iagetcli"
        applicationId "com.gameaday.iahelper"  // NEW
    }
}
```

#### android/app/src/main/AndroidManifest.xml
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    <!-- OLD: package="com.gameaday.iagetcli" -->
    package="com.gameaday.iahelper">  <!-- NEW -->
```

#### android/app/src/main/kotlin/com/gameaday/iagetcli/MainActivity.kt
**Move file to**: `android/app/src/main/kotlin/com/gameaday/iahelper/MainActivity.kt`
```kotlin
// OLD: package com.gameaday.iagetcli
package com.gameaday.iahelper  // NEW
```

### 2. App Name Changes

#### android/app/src/main/res/values/strings.xml
```xml
<resources>
    <!-- OLD: <string name="app_name">IA Get</string> -->
    <string name="app_name">IA Helper</string>  <!-- NEW -->
</resources>
```

#### pubspec.yaml
```yaml
# OLD: name: ia_get
name: ia_helper  # NEW

# OLD: description: Internet Archive download manager
description: Your Internet Archive companion app  # NEW

# Update repository URL
repository: https://github.com/gameaday/ia-helper  # NEW
```

### 3. User-Facing Strings in Code

Search for these patterns and update:
- "IA Get" → "IA Helper"
- "ia-get" → "ia-helper"
- "ia_get" → "ia_helper"
- "iagetcli" → "iahelper"

Common locations:
- `lib/screens/about_screen.dart` (if exists)
- `lib/screens/settings_screen.dart`
- `lib/utils/constants.dart`
- App bar titles
- Dialogs and snackbars
- Error messages

### 4. Deep Links (if applicable)

#### AndroidManifest.xml
```xml
<!-- OLD scheme -->
<data android:scheme="iagetcli" />

<!-- NEW scheme -->
<data android:scheme="iahelper" />
```

## Testing After Migration

### Build Verification
```bash
# In new ia-helper repository
flutter clean
flutter pub get
flutter analyze
flutter build apk --flavor production
flutter build appbundle --flavor production
```

### Test Checklist
- [ ] App builds successfully
- [ ] App launches without crashes
- [ ] App name shows as "IA Helper" in launcher
- [ ] Package name is com.gameaday.iahelper
- [ ] All screens load correctly
- [ ] Search functionality works
- [ ] Download queue works
- [ ] Settings persist
- [ ] Dark mode toggles correctly
- [ ] Deep links work (if applicable)
- [ ] Notifications show "IA Helper" name

### Device Testing
- [ ] Test on Android 5.0 (API 21) - minimum version
- [ ] Test on Android 14 (API 34) - target version
- [ ] Test on phone (portrait)
- [ ] Test on tablet (landscape)
- [ ] Test in light mode
- [ ] Test in dark mode

## Play Store Submission Changes

### Before Submission
- [ ] Verify package name: `com.gameaday.iahelper`
- [ ] Verify app name: `IA Helper`
- [ ] Update all screenshots with new branding
- [ ] Update feature graphic with new name
- [ ] Update app icon if it includes name
- [ ] Review all metadata for consistency

### Play Console Setup
- [ ] Create new app entry for "IA Helper"
- [ ] Use package name: `com.gameaday.iahelper`
- [ ] Upload AAB from new ia-helper repository
- [ ] Link to github.com/gameaday/ia-helper
- [ ] Use updated privacy policy
- [ ] Use updated metadata

## Post-Migration Tasks

### ia-get-cli Repository
- [ ] Update README to link to ia-helper
- [ ] Archive or remove mobile/ directory
- [ ] Update CI/CD to skip Flutter builds
- [ ] Create release notes mentioning migration
- [ ] Pin issue about mobile app relocation

### ia-helper Repository
- [ ] Set up branch protection rules
- [ ] Configure GitHub Actions secrets (if needed)
- [ ] Create initial release (v1.0.0)
- [ ] Set up issue templates (mobile-focused)
- [ ] Enable Discussions for user feedback
- [ ] Add topics: flutter, dart, android, internet-archive

### Communication
- [ ] Announce migration in ia-get-cli issues
- [ ] Update any external documentation
- [ ] Update blog posts or articles (if any)
- [ ] Update social media links (if any)

## Rollback Plan

If migration encounters critical issues:

1. **Keep ia-get-cli mobile code**: Don't delete until ia-helper is proven stable
2. **Parallel development**: Can maintain both during transition
3. **Rollback procedure**:
   - Revert branding changes in ia-get-cli
   - Continue development in original location
   - Archive ia-helper repository
   - Update documentation

## Timeline

**Estimated Duration**: 4-6 hours total

1. **Branding Updates** (1-2 hours)
   - Update all "IA Get" → "IA Helper" references
   - Update package name throughout codebase
   - Update documentation

2. **Repository Setup** (30 minutes)
   - Create ia-helper repository
   - Set up initial files
   - Configure settings

3. **File Migration** (1 hour)
   - Copy Flutter app files
   - Copy relevant documentation
   - Set up directory structure

4. **Testing** (1-2 hours)
   - Build verification
   - Functional testing
   - Device testing

5. **CI/CD Setup** (30 minutes)
   - Configure GitHub Actions
   - Test build workflows
   - Verify artifact uploads

6. **Cleanup** (30 minutes)
   - Update ia-get-cli README
   - Archive mobile directory
   - Update cross-references

## Success Criteria

Migration is successful when:
- ✅ ia-helper repository builds successfully
- ✅ All tests pass
- ✅ App runs on physical device
- ✅ All branding shows "IA Helper"
- ✅ Package name is com.gameaday.iahelper
- ✅ CI/CD workflows pass
- ✅ No broken links in documentation
- ✅ Play Store metadata updated
- ✅ ia-get-cli updated to reference new repo

## Questions & Answers

**Q: What happens to git history?**
A: Git history is NOT preserved in new repository. This is a fresh start. If history is important, use `git subtree` or `git filter-branch` (more complex).

**Q: Can we maintain both repositories?**
A: Yes, but not recommended. Choose one location to avoid confusion and duplicate work.

**Q: What about existing users?**
A: No existing users yet (not published to Play Store). This is perfect time to migrate.

**Q: Will package name change affect upgrades?**
A: No existing installations. Fresh installs only. Perfect timing for rebranding.

**Q: Should we bump version to 2.0.0?**
A: No, keep as 1.0.0. This is still initial release, just with new branding.

---

**Last Updated**: October 8, 2025  
**Migration Status**: In Progress  
**Target Completion**: October 8, 2025  
**New Repository**: https://github.com/gameaday/ia-helper
