# IA Helper

[![Flutter CI](https://github.com/gameaday/ia-helper/actions/workflows/flutter-ci.yml/badge.svg)](https://github.com/gameaday/ia-helper/actions/workflows/flutter-ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

**Your complete Internet Archive companion** - Download, search, and organize content from archive.org with a beautiful Material Design 3 interface.

<p align="center">
  <img src="docs/images/app-preview.png" alt="IA Helper Preview" width="800"/>
</p>

## 🚀 Quick Start

### 🌐 **[Launch Web App](https://gameaday.github.io/ia-helper/app/)** 
Try IA Helper instantly in your browser - no installation required!

### 📥 **[Download Android APK](https://gameaday.github.io/ia-helper/)**
Get the latest development build with full offline functionality.

---

## 📱 About

IA Helper is a powerful mobile app for accessing the Internet Archive (archive.org), the world's largest digital library. Whether you're downloading historical documents, discovering classic media, or building your personal digital archive, IA Helper makes it effortless.

### ✨ Key Features

- 📥 **Smart Downloads** - Resume interrupted downloads, queue management, priority scheduling
- 🔍 **Advanced Search** - Search 35+ million items with powerful filters
- 📚 **Library Management** - Organize downloads, offline access, metadata viewer
- ⚡ **Lightning Fast** - Concurrent downloads with automatic retry
- 🎨 **Material Design 3** - Beautiful UI with full dark mode support
- 🔐 **Privacy First** - No tracking, no ads, local storage only

## 📥 Download Options

### 🌐 Try It Now - Web App

**[📦 Launch Web Application](https://gameaday.github.io/ia-helper/app/)** - Full-featured web version

Perfect for:
- ✅ Quick searches and content discovery
- ✅ Previewing archives before downloading
- ✅ Cross-platform access (Windows, Mac, Linux)
- ✅ No installation or permissions required

### 📱 Mobile App

**[📦 Download Development Builds](https://gameaday.github.io/ia-helper/)** 

The downloads page automatically updates with every commit to `main`:
- 🤖 **Android Development APK** - Latest debug build with all features
- 🌐 **Web Application** - Direct link to the web app
- 📊 **Build Info** - Version, commit details, and checksums

### 📱 App Stores

[<img src="https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png" alt="Get it on Google Play" height="80">](https://play.google.com/store/apps/details?id=com.gameaday.iahelper)

*Coming soon to Google Play Store*

## 🏗️ Built With

- **Flutter** 3.35.0 - Cross-platform UI framework
- **Dart** - Programming language
- **Material Design 3** - Google's latest design system
- **SQLite** - Local database for downloads and metadata
- **HTTP/2** - Fast and efficient networking

## 🎨 Design

IA Helper follows Material Design 3 guidelines with ~98% compliance:
- ✅ MD3 color system with dynamic theming
- ✅ MD3 typography scale
- ✅ MD3 motion system (curves and durations)
- ✅ MD3 component library
- ✅ Adaptive layouts for phones and tablets
- ✅ Full dark mode support
- ✅ WCAG AA+ accessibility compliance

## 🚀 Getting Started

### Prerequisites

- Flutter 3.35.0 or higher
- Dart 3.5.0 or higher
- Android Studio or VS Code
- Android SDK (API 21+)

### Installation

```bash
# Clone the repository
git clone https://github.com/gameaday/ia-helper.git
cd ia-helper

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Building

```bash
# Debug build
flutter build apk --flavor development

# Release build
flutter build apk --flavor production --release
flutter build appbundle --flavor production --release
```

## 📖 Documentation

- [Play Store Metadata](docs/PLAY_STORE_METADATA.md) - App descriptions and store listing
- [Android Permissions](docs/ANDROID_PERMISSIONS.md) - Detailed permission explanations
- [Phase 5 Plan](docs/features/PHASE_5_PLAN.md) - Development roadmap
- [Migration Guide](docs/FLUTTER_APP_MIGRATION.md) - Migration from ia-get-cli

## 🤝 Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and development process.

### Development Guidelines

- Follow Material Design 3 principles
- Write tests for new features
- Update documentation
- Use conventional commits
- Run `flutter analyze` before committing

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔐 Privacy

IA Helper is privacy-focused:
- ❌ No user tracking or analytics
- ❌ No ads, no subscriptions
- ❌ No data collection
- ✅ All data stored locally on your device
- ✅ No account required

Read our [Privacy Policy](PRIVACY_POLICY.md) for more details.

## 🙏 Acknowledgments

- [Internet Archive](https://archive.org) - For preserving the world's knowledge
- [Flutter](https://flutter.dev) - For the amazing framework
- [Material Design](https://m3.material.io) - For design guidelines

## 📧 Contact

- **Email**: admin@historylabs.dev
- **Issues**: [GitHub Issues](https://github.com/gameaday/ia-helper/issues)
- **Discussions**: [GitHub Discussions](https://github.com/gameaday/ia-helper/discussions)

## 🔗 Related Projects

- [ia-get CLI](https://github.com/gameaday/ia-get-cli) - Rust command-line tool for Internet Archive

---

**Not affiliated with Internet Archive**  
IA Helper is an independent third-party client and is not officially affiliated with or endorsed by the Internet Archive.

Made with ❤️ by the Gameaday team
