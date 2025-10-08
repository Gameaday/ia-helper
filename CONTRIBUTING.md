# Contributing to Internet Archive Helper

Thank you for your interest in contributing to IA Helper! This document provides guidelines and instructions for contributing to the project.

## 🌟 Ways to Contribute

- 🐛 **Bug Reports**: Submit detailed bug reports with reproduction steps
- ✨ **Feature Requests**: Suggest new features or improvements
- 📝 **Documentation**: Improve or expand documentation
- 💻 **Code Contributions**: Submit pull requests with bug fixes or new features
- 🎨 **Design**: Suggest UI/UX improvements following Material Design 3
- 🌍 **Translations**: Help translate the app (coming soon)

## 🚀 Getting Started

### Prerequisites

- Flutter 3.35.0 or higher
- Dart 3.5.0 or higher
- Git
- Android Studio or VS Code with Flutter plugin
- Android SDK (API 21+)

### Setting Up Development Environment

1. **Fork and Clone**
   ```bash
   git clone https://github.com/YOUR_USERNAME/ia-helper.git
   cd ia-helper
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the App**
   ```bash
   flutter run
   ```

4. **Run Tests**
   ```bash
   flutter test
   flutter analyze
   ```

## 📋 Development Guidelines

### Code Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `flutter analyze` to check for issues
- Run `flutter format .` before committing
- Maintain ~98% Material Design 3 compliance

### Material Design 3 Compliance

**CRITICAL**: All UI contributions MUST follow Material Design 3 guidelines:

- ✅ Use theme colors, never hardcoded colors
- ✅ Use `MD3Curves` and `MD3Durations` from `lib/utils/animation_constants.dart`
- ✅ Follow 4dp grid system for spacing (4, 8, 12, 16, 24, 32, 48, 64)
- ✅ Use proper elevation levels (0-5)
- ✅ Test in both light and dark mode
- ✅ Ensure WCAG AA+ contrast ratios
- ✅ Support dynamic font scaling

Reference: https://m3.material.io/

### Commit Messages

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add search history autocomplete
fix: resolve crash on file download
docs: update API documentation
style: format code with flutter format
refactor: simplify download queue logic
test: add unit tests for metadata cache
chore: update dependencies
```

### Branch Naming

- `feature/description` - New features
- `fix/description` - Bug fixes
- `docs/description` - Documentation updates
- `refactor/description` - Code refactoring

## 🔄 Pull Request Process

1. **Create a Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make Changes**
   - Write clean, well-documented code
   - Add tests for new features
   - Update documentation as needed
   - Follow Material Design 3 guidelines

3. **Test Thoroughly**
   ```bash
   flutter test
   flutter analyze
   flutter build apk --flavor development
   ```

4. **Commit Changes**
   ```bash
   git add .
   git commit -m "feat: add your feature"
   ```

5. **Push to Fork**
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Create Pull Request**
   - Go to GitHub and create a PR
   - Provide clear description of changes
   - Reference any related issues
   - Add screenshots for UI changes
   - Ensure CI/CD passes

### Pull Request Checklist

- [ ] Code follows Dart style guidelines
- [ ] All tests pass (`flutter test`)
- [ ] No analyzer warnings (`flutter analyze`)
- [ ] UI follows Material Design 3 guidelines
- [ ] Dark mode tested and working
- [ ] Documentation updated
- [ ] Conventional commit message used
- [ ] PR description is clear and complete

## 🐛 Reporting Bugs

When reporting bugs, please include:

1. **Description**: Clear description of the bug
2. **Steps to Reproduce**: Numbered steps to reproduce
3. **Expected Behavior**: What should happen
4. **Actual Behavior**: What actually happens
5. **Environment**:
   - App version
   - Android version
   - Device model
6. **Logs**: Relevant error messages or logs
7. **Screenshots**: If applicable

## 💡 Suggesting Features

When suggesting features, please include:

1. **Use Case**: Why is this feature needed?
2. **Proposed Solution**: How should it work?
3. **Alternatives**: Other ways to solve the problem
4. **Material Design**: How does it fit MD3 guidelines?
5. **Mockups**: UI mockups if applicable

## 🧪 Testing

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test
flutter test test/services/metadata_cache_test.dart

# Run tests with coverage
flutter test --coverage
```

### Writing Tests

- Write unit tests for services and models
- Write widget tests for UI components
- Aim for good coverage on critical paths
- Mock external dependencies

## 📝 Documentation

### Code Documentation

- Add dartdoc comments to public APIs
- Document complex logic
- Explain "why" not just "what"
- Include examples for complex functions

### User Documentation

- Update README.md for major changes
- Add to appropriate docs/ files
- Keep Play Store metadata up to date
- Include screenshots for visual changes

## 🎨 Design Guidelines

### Colors

```dart
// ✅ Correct - Use theme colors
Theme.of(context).colorScheme.primary

// ❌ Wrong - Never hardcode colors
Color(0xFF0175C2)
```

### Animations

```dart
// ✅ Correct - Use MD3 constants
duration: MD3Durations.short1,
curve: MD3Curves.emphasized,

// ❌ Wrong - Magic numbers
duration: Duration(milliseconds: 150),
curve: Curves.easeInOut,
```

### Spacing

```dart
// ✅ Correct - Use AppSpacing constants
padding: EdgeInsets.all(AppSpacing.md),

// ❌ Wrong - Magic numbers
padding: EdgeInsets.all(14),
```

## 🔐 Security

- Never commit API keys or secrets
- Report security vulnerabilities privately
- Email: gameaday.project@gmail.com
- Do not create public issues for security bugs

## 📄 License

By contributing, you agree that your contributions will be licensed under the MIT License.

## 💬 Communication

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: Questions and general discussion
- **Pull Requests**: Code review and collaboration

## ❓ Questions?

If you have questions about contributing:

- Check existing issues and discussions
- Read the documentation in `docs/`
- Ask in GitHub Discussions
- Email: gameaday.project@gmail.com

## 🙏 Thank You

Thank you for contributing to Internet Archive Helper! Every contribution, no matter how small, helps make this project better.

---

**Happy Coding!** 🎉
