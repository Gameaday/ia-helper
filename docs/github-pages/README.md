# GitHub Pages Artifacts Site

This directory contains the static site files for the GitHub Pages deployment that provides access to development and production builds.

## 🎯 Purpose

The GitHub Pages site serves as a central location for:
- **Development APK builds** - Automatically built and deployed on every push to `main`
- **Web application** - Live production web app
- **Build information** - Version, commit info, checksums, and build times
- **Easy distribution** - Share builds with testers without GitHub account required

## 🏗️ Architecture

### Workflow: `.github/workflows/deploy-github-pages.yml`

The workflow runs on every push to `main` and:

1. **Builds Android Development APK**
   - Uses `--flavor development` for development builds
   - Debug mode for easier testing and debugging
   - Generates SHA-256 checksums for integrity verification

2. **Builds Web Application**
   - Production build optimized for deployment
   - Sets proper `--base-href` for GitHub Pages
   - Deployed to root of GitHub Pages site

3. **Generates Build Manifest**
   - Creates `artifacts/manifest.json` with build metadata
   - Includes version, commit info, build time, file sizes
   - Used by the web page to display current build information

4. **Deploys to GitHub Pages**
   - Uses GitHub's official Pages deployment action
   - Automatic deployment with proper permissions
   - No manual intervention required

### Static Site: `docs/github-pages/index.html`

The main page features:
- **Responsive design** - Works on desktop and mobile
- **Dark mode support** - Automatic based on system preference
- **Material Design** - Clean, modern UI following MD3 principles
- **Real-time updates** - Fetches latest build info via manifest.json
- **Download tracking** - Links to APKs with checksums

## 📦 Artifacts Structure

```
github-pages/
├── artifacts/
│   ├── manifest.json          # Build metadata (auto-generated)
│   ├── android/
│   │   └── development/
│   │       ├── app-development-debug.apk
│   │       └── app-development-debug.apk.sha256
│   └── web/                   # Web app files
│       ├── index.html
│       ├── flutter.js
│       └── ...
└── index.html                 # Main landing page (this directory)
```

## 🚀 Setup Instructions

### 1. Enable GitHub Pages

1. Go to repository **Settings** → **Pages**
2. Under **Source**, select **GitHub Actions**
3. Save changes

### 2. Push to Main Branch

The workflow will automatically run on the next push to `main`:

```bash
git push origin main
```

### 3. Access the Site

After the workflow completes (2-5 minutes), access the site at:

```
https://[username].github.io/ia-helper/
```

For this repository:
```
https://gameaday.github.io/ia-helper/
```

## 🔧 Configuration

### Modify Base URL

If you need to change the base URL (e.g., custom domain), update these locations:

1. **Workflow file** (`.github/workflows/deploy-github-pages.yml`):
   ```yaml
   flutter build web --release --base-href /ia-helper/
   ```

2. **Manifest generation** (same workflow file):
   ```yaml
   "url": "https://${{ github.repository_owner }}.github.io/ia-helper/"
   ```

### Add Production Builds

To add production APK/AAB builds, modify the workflow to include:

```yaml
- name: Build Android Production APK
  run: |
    flutter build apk --release --flavor production
```

And update the manifest generation to include production artifacts.

## 📊 Build Information

The `manifest.json` file contains:

```json
{
  "version": "1.0.0+1",
  "buildTime": "2025-10-08 12:00:00 UTC",
  "commitSha": "abc1234",
  "commitMessage": "Latest commit message",
  "branch": "main",
  "buildType": "development",
  "artifacts": {
    "android": { ... },
    "web": { ... }
  },
  "repository": "Gameaday/ia-helper",
  "runId": "12345",
  "runNumber": "42"
}
```

## 🔒 Security

- **Checksums**: SHA-256 checksums provided for all APK files
- **HTTPS**: All downloads served over HTTPS
- **Version tracking**: Every build includes commit SHA for traceability
- **No secrets**: Workflow uses only public data and GitHub tokens

## 🐛 Troubleshooting

### Site not updating after push

1. Check workflow run status: `Actions` tab in GitHub
2. Verify workflow completed successfully
3. Wait 1-2 minutes for CDN cache to clear
4. Hard refresh browser (Ctrl+F5 or Cmd+Shift+R)

### Manifest not loading

1. Check browser console for errors
2. Verify `artifacts/manifest.json` exists in deployed site
3. Check workflow logs for build failures

### APK download fails

1. Verify APK was built successfully in workflow
2. Check file size isn't too large for GitHub Pages (100MB limit)
3. Ensure proper file permissions in workflow

## 📝 Customization

### Change styling

Edit `docs/github-pages/index.html` CSS variables:

```css
:root {
    --primary: #1976d2;
    --secondary: #424242;
    /* ... more variables ... */
}
```

### Add more build types

1. Add build step to workflow
2. Update manifest generation to include new artifact
3. Add new build card to `index.html`

## 📄 License

Same as main project - see LICENSE file in repository root.
