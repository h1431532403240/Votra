# Contributing to Votra

Thank you for your interest in contributing to Votra! This guide will help you get started.

## Development Environment Setup

### Prerequisites

- **macOS 26.2** (Tahoe) or later
- **Xcode 26** or later
- **Apple Silicon** Mac (M1 or later)
- **SwiftLint**: `brew install swiftlint`

### Getting Started

1. Fork the repository on GitHub
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/votra.git
   cd votra
   ```
3. Open the project in Xcode:
   ```bash
   open Votra.xcodeproj
   ```
4. Build and run to verify everything works

## Building Locally

### Debug Build

```bash
xcodebuild build \
  -project Votra.xcodeproj \
  -scheme Votra \
  -destination 'platform=macOS,arch=arm64' \
  -configuration Debug \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO
```

### Running Tests

```bash
xcodebuild test \
  -project Votra.xcodeproj \
  -scheme Votra \
  -destination 'platform=macOS,arch=arm64' \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO
```

## Code Style

We use SwiftLint to enforce consistent code style. Run SwiftLint before committing:

```bash
swiftlint lint --strict
```

### Key Style Guidelines

- Use `foregroundStyle()` instead of `foregroundColor()`
- Use `clipShape(.rect(cornerRadius:))` instead of `cornerRadius()`
- Use `@Observable` classes instead of `ObservableObject`
- Use `NavigationStack` instead of `NavigationView`
- Prefer modern Swift concurrency over GCD
- Mark `@Observable` classes with `@MainActor`

See `.swiftlint.yml` for the complete rule configuration.

## Optional: Local Pre-commit Hooks

For an extra layer of security, you can install local git hooks that scan for secrets before commits:

### Using pre-commit framework (recommended)

```bash
brew install gitleaks pre-commit
pre-commit install
```

### Manual installation

```bash
./scripts/install-hooks.sh
```

### Bypassing hooks

If you need to bypass the secret scanning for a legitimate reason:

```bash
SKIP=gitleaks git commit -m "message"
# or
git commit --no-verify -m "message"
```

Note: CI will still scan for secrets regardless of local hooks.

## Pull Request Guidelines

### Branch Naming

Use descriptive branch names:
- `feature/add-speaker-detection`
- `fix/audio-capture-crash`
- `docs/update-readme`

### Commit Messages

Write clear, descriptive commit messages:
- Use imperative mood ("Add feature" not "Added feature")
- Keep the first line under 72 characters
- Add details in the body if needed

### PR Checklist

Before submitting a PR, ensure:

- [ ] All tests pass: `xcodebuild test ...`
- [ ] SwiftLint passes: `swiftlint lint --strict`
- [ ] Code follows project conventions (see CLAUDE.md)
- [ ] New features have tests
- [ ] Documentation is updated if needed
- [ ] Commit messages are clear and descriptive

### CI Requirements

All PRs must pass the CI workflow which includes:
- SwiftLint check (zero warnings, zero errors)
- Build verification
- All unit tests

## Reporting Issues

### Bug Reports

Use the bug report template when creating issues. Include:
- macOS version
- Steps to reproduce
- Expected vs actual behavior
- Relevant logs or screenshots

### Feature Requests

Use the feature request template. Describe:
- The problem you're trying to solve
- Your proposed solution
- Any alternatives you've considered

## Code of Conduct

Be respectful and constructive in all interactions. We're all here to build something great together.

## Questions?

If you have questions about contributing, feel free to open a discussion on GitHub.
