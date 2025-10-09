# GitHub Copilot Instructions for ia-get

## Project Overview
This is a Rust CLI tool for downloading files from the Internet Archive, built with standard Cargo toolchain for simplicity and reliability.

## Development Guidelines

### Rust Standards
- Follow standard Rust conventions and idiomatic patterns
- Use `cargo fmt` and `cargo clippy` for code formatting and linting
- Prefer explicit error handling with `Result<T, E>` types
- Use `anyhow` or `thiserror` for error handling consistency

### Build System
- This project uses standard Cargo toolchain for all operations
- Use `cargo build` for development builds and `cargo build --release` for optimized builds
- Run tests with `cargo test` and linting with `cargo clippy`
- Maintain compatibility with standard Rust compilation targets
- **Always run `cargo fmt --check` and `cargo fmt` at the end of every PR to ensure consistent code formatting**

### Dependencies
- Keep dependencies minimal and well-justified
- Update Cargo.lock when adding new dependencies
- Prefer crates that are well-maintained and have good ecosystem support

### Code Structure
- Follow CLI best practices with clear subcommands and help text
- Use structured logging for better debugging
- Implement proper signal handling for long-running downloads
- Include comprehensive error messages for user-facing operations

### Testing
- Write unit tests for core functionality
- Include integration tests for CLI behavior
- Test cross-platform compatibility where relevant

### Documentation
- Update README.md for any new features or usage changes
- Include examples in help text and documentation
- Document any Internet Archive API specifics or limitations

### Documentation Organization
- **All documentation files MUST go in the `docs/` directory** with proper hierarchy and organization
- **EXCEPTION**: Only `PRIVACY_POLICY.md` stays at the repository root level
- Use subdirectories for organization:
  - `docs/features/` - Feature implementation documentation and completion reports
  - `docs/guides/` - User guides and how-to documents
  - `docs/architecture/` - System design, architecture decisions, and technical specs
  - `docs/development/` - Development workflows, setup guides, and contributing docs
  - `docs/mobile/` - Mobile app specific documentation (Flutter/Android/iOS)
- **Naming conventions**:
  - Use descriptive names: `cache-implementation.md` not `doc1.md`
  - Use lowercase with hyphens: `feature-name-guide.md`
  - Include completion status in feature docs: `FEATURE_NAME_COMPLETE.md`
- **Long-term management**:
  - Phase completion summaries → `docs/features/phase-N-complete.md`
  - Task completion reports → `docs/features/phase-N-task-M-complete.md`
  - Implementation plans → `docs/features/feature-name-plan.md`
  - Progress tracking → `docs/features/feature-name-progress.md`
- **DO NOT** create top-level documentation files except for standard files like README.md, CHANGELOG.md, CONTRIBUTING.md, LICENSE, and PRIVACY_POLICY.md

## Flutter Mobile App Guidelines

### 🎯 Design Philosophy - PARAMOUNT PRINCIPLES

**Material Design 3 (MD3) compliance and Android framework guidelines are PARAMOUNT for all Flutter development.**

#### Material Design 3 Excellence (Top Priority)
- **All UI components MUST follow Material Design 3 specifications**
- Use MD3 color system, typography, spacing, and elevation
- Implement MD3 motion system (emphasized, standard, decelerate, accelerate curves)
- Follow MD3 component guidelines (buttons, cards, dialogs, navigation)
- Maintain ~98%+ MD3 compliance at all times
- Reference: https://m3.material.io/

#### Android Framework Guidelines
- Follow Android design principles and patterns
- Respect platform conventions (back button behavior, navigation, etc.)
- Use adaptive layouts for tablets and large screens
- Implement proper accessibility (TalkBack, font scaling, contrast)
- Follow Android best practices for performance and battery usage

#### Dark Mode & Accessibility
- **100% WCAG AA+ compliance required**
- Proper contrast ratios for all text and interactive elements
- Dark mode MUST work flawlessly with all features
- Support dynamic color schemes where possible
- Test with TalkBack and other accessibility tools

### Environment Setup
- Flutter may not be available in the Copilot environment
- When Flutter is not available, focus on Dart code correctness and syntax
- Use static analysis by reading code and checking for common patterns
- Verify against Dart language specifications and Flutter best practices

### Flutter Standards
- **Material Design 3 is the primary design system - follow it strictly**
- Use `flutter analyze` for static analysis (when available)
- Prefer explicit types over `var` for better code clarity
- Use proper null safety with `?` and `!` operators
- Follow Flutter performance best practices (const constructors, efficient rebuilds)
- **CRITICAL: ANY code warnings from `flutter analyze` WILL break the build in CI/CD**
- **Always fix ALL warnings before committing - the build pipeline treats warnings as errors**
- Common warnings that break builds:
  - Non-const IconData invocations (use helper methods or `--no-tree-shake-icons`)
  - Unused imports
  - Deprecated API usage (update to new APIs immediately)
  - Type mismatches

### MD3 Implementation Guidelines
- **Animations**: Use `MD3Curves` and `MD3Durations` from `animation_constants.dart`
- **Colors**: Use theme colors, never hardcoded colors
- **Typography**: Use `Theme.of(context).textTheme` with MD3 text styles
- **Spacing**: Follow 4dp grid system (4, 8, 12, 16, 24, 32, 48, 64)
- **Elevation**: Use MD3 elevation levels (0, 1, 2, 3, 4, 5)
- **Shapes**: Use MD3 shape system (small: 8dp, medium: 12dp, large: 16dp, extra-large: 28dp)

### Common Flutter/Dart Issues to Avoid
- **Type mismatches**: Ensure `int` vs `double` compatibility (use `.toDouble()` when needed)
- **Enum values**: Check enum definitions before using (e.g., `DownloadStatus.error` not `DownloadStatus.failed`)
- **Named parameters**: Verify parameter names in `copyWith` and other methods match the model definition
- **Unused imports**: Remove imports that are not used in the file
- **Platform-specific code**: Use `path` package for paths, `defaultTargetPlatform` for platform checks
- **Hardcoded colors**: NEVER use hardcoded colors, always use theme colors
- **Non-MD3 animations**: Always use MD3 curves and durations

### Mobile App Structure
- `lib/models/` - Data models with proper serialization
- `lib/services/` - Business logic and API clients
- `lib/screens/` - UI screens and widgets (all MD3 compliant)
- `lib/widgets/` - Reusable widgets (all MD3 compliant)
- `lib/utils/` - Helper functions and utilities
- `lib/utils/animation_constants.dart` - MD3 animation curves and durations

### Testing Mobile App
- When Flutter is available: `flutter test` and `flutter analyze`
- When Flutter is not available: Review code manually for common issues
- Always verify enum values, parameter names, and type compatibility
- Check that imports are used and necessary
- **Verify MD3 compliance**: Check colors, animations, spacing, typography
- **Test dark mode**: Ensure all features work in dark mode
- **Test accessibility**: Verify contrast ratios and screen reader support