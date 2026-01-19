# Votra

[![CI](https://github.com/h1431532403240/Votra/actions/workflows/ci.yml/badge.svg)](https://github.com/h1431532403240/Votra/actions/workflows/ci.yml)
[![Release](https://github.com/h1431532403240/Votra/actions/workflows/release.yml/badge.svg)](https://github.com/h1431532403240/Votra/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Real-time voice translation for macOS, powered by Apple Intelligence.

## Requirements

- **macOS 26.0** (Tahoe) or later
- **Apple Silicon** (M1 or later) — required for FoundationModels and Translation APIs
- Microphone access for voice capture

## Installation

1. Download the latest `Votra-X.Y.Z.dmg` from [Releases](https://github.com/h1431532403240/Votra/releases)
2. Open the DMG and drag Votra to your Applications folder
3. Launch Votra from Applications

The app is code-signed and notarized by Apple, so it will open without Gatekeeper warnings.

## Features

- Real-time speech recognition and transcription
- Instant translation powered by Apple's on-device Translation framework
- AI-powered meeting summaries using FoundationModels
- Speaker identification and diarization
- Subtitle export (SRT format)
- Privacy-focused: all processing happens on-device

## Building from Source

### Prerequisites

- Xcode 26 or later
- macOS 26.0 or later
- SwiftLint (`brew install swiftlint`)

### Build

```bash
# Clone the repository
git clone https://github.com/h1431532403240/Votra.git
cd Votra

# Open in Xcode
open Votra.xcodeproj

# Or build from command line
xcodebuild build \
  -project Votra.xcodeproj \
  -scheme Votra \
  -destination 'platform=macOS,arch=arm64' \
  -configuration Debug
```

### Run Tests

```bash
xcodebuild test \
  -project Votra.xcodeproj \
  -scheme Votra \
  -destination 'platform=macOS,arch=arm64'
```

### Code Style

We use SwiftLint to enforce consistent code style:

```bash
swiftlint lint --strict
```

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

Votra is released under the MIT License. See [LICENSE](LICENSE) for details.

## Security

Please report security vulnerabilities privately via GitHub's security advisory feature. Do not create public issues for security reports.
