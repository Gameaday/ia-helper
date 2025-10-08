# 🚀 GitHub Pages Setup Guide

This guide will help you enable GitHub Pages for the ia-helper repository to host the automated builds and artifacts site.

## ✅ Prerequisites

- Repository admin/owner access
- GitHub Actions enabled (default for public repos)
- Main branch with the new workflow file committed

## 📋 Step-by-Step Instructions

### 1. Enable GitHub Pages

1. Go to your repository on GitHub: https://github.com/Gameaday/ia-helper
2. Click **Settings** (gear icon in the top navigation)
3. Scroll down to **Pages** in the left sidebar (under "Code and automation")
4. Under **Source**, select **GitHub Actions** from the dropdown
5. Click **Save** (if available)

That's it! The site will automatically deploy on the next push to `main`.

### 2. Verify Deployment

After pushing to `main` (or manually triggering the workflow):

1. Go to the **Actions** tab
2. Look for the "Deploy to GitHub Pages" workflow
3. Wait for it to complete (usually 2-5 minutes)
4. Once complete, visit: https://gameaday.github.io/ia-helper/

### 3. Badge (Optional)

Add a deployment status badge to your README:

```markdown
[![GitHub Pages](https://github.com/Gameaday/ia-helper/actions/workflows/deploy-github-pages.yml/badge.svg)](https://github.com/Gameaday/ia-helper/actions/workflows/deploy-github-pages.yml)
```

## 🔧 Manual Trigger (If Needed)

If you want to manually trigger a deployment:

1. Go to **Actions** tab
2. Click "Deploy to GitHub Pages" workflow
3. Click **Run workflow** button
4. Select `main` branch
5. Click **Run workflow**

## 🌐 Custom Domain (Optional)

If you want to use a custom domain:

1. In repository **Settings** → **Pages**
2. Under **Custom domain**, enter your domain (e.g., `builds.iahelper.app`)
3. Update the workflow file to use your custom domain:
   ```yaml
   flutter build web --release --base-href /
   ```
4. Add DNS records as shown in GitHub Pages settings
5. Wait for DNS propagation (can take up to 24 hours)

## 🎯 What Happens on Each Push

Every time you push to `main`:

1. ✅ GitHub Actions workflow triggers automatically
2. 🏗️ Builds Android development APK
3. 🌐 Builds web application
4. 📊 Generates build manifest with metadata
5. 📦 Creates checksums for integrity verification
6. 🚀 Deploys everything to GitHub Pages
7. ⏰ Site updates automatically (1-2 minute CDN delay)

## 📊 Build Artifacts Include

- **Android APK**: `app-development-debug.apk`
- **Checksum**: SHA-256 hash for verification
- **Web App**: Full production build
- **Manifest**: JSON with version, commit, timestamps

## 🔍 Troubleshooting

### Pages not showing

**Check:**
- GitHub Pages is enabled in Settings → Pages
- Source is set to "GitHub Actions"
- Workflow completed successfully in Actions tab
- Wait 1-2 minutes for CDN cache

**Fix:**
- Hard refresh browser (Ctrl+F5 or Cmd+Shift+R)
- Check workflow logs for errors
- Verify permissions in workflow file

### Builds not updating

**Check:**
- Workflow triggered and completed
- Manifest.json has latest timestamp
- Browser cache cleared

**Fix:**
- Manually trigger workflow from Actions tab
- Check workflow logs for build failures
- Verify artifact upload succeeded

### 404 errors

**Check:**
- Base href in web build matches deployment path
- All files uploaded correctly
- Paths in manifest.json are correct

**Fix:**
- Verify `--base-href /ia-helper/` in workflow
- Check deployed files in gh-pages branch
- Update paths in index.html if needed

## 📝 Important Notes

- **Automatic**: No manual intervention needed after setup
- **Free**: GitHub Pages is free for public repositories
- **Fast**: CDN-backed for global distribution
- **Secure**: HTTPS by default
- **Storage**: 1GB size limit, 100GB bandwidth/month
- **Retention**: Artifacts kept for 30 days

## 🔐 Permissions

The workflow uses these permissions:
- `contents: read` - Read repository files
- `pages: write` - Write to GitHub Pages
- `id-token: write` - Authenticate deployments

These are standard and secure for GitHub Pages deployment.

## 📚 Additional Resources

- [GitHub Pages Documentation](https://docs.github.com/en/pages)
- [GitHub Actions for Pages](https://github.com/actions/deploy-pages)
- [Flutter Web Deployment](https://docs.flutter.dev/deployment/web)

## ✅ Success Checklist

- [ ] GitHub Pages enabled in Settings → Pages
- [ ] Source set to "GitHub Actions"
- [ ] Workflow file committed to main branch
- [ ] First deployment completed successfully
- [ ] Site accessible at https://gameaday.github.io/ia-helper/
- [ ] Build manifest loads correctly
- [ ] Download links work
- [ ] Web app launches successfully

---

## 🎉 You're All Set!

Once enabled, your GitHub Pages site will automatically update with every push to main. Share the link with your team and testers!

**Site URL**: https://gameaday.github.io/ia-helper/

For questions or issues, see the [main README](../../docs/github-pages/README.md) or open an issue on GitHub.
