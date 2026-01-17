# Tasks: Open Source Release with CI/CD and DMG Packaging

**Input**: Design documents from `/specs/002-opensource-cicd-dmg/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: GitHub Actions workflows are tested locally using [nektos/act](https://github.com/nektos/act) before pushing.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

**CI/CD Platform**: GitHub Actions only (fully transparent — all logs publicly visible)

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

## Path Conventions

Based on plan.md structure:
- `.github/workflows/` - GitHub Actions workflows (ci.yml, release.yml)
- `scripts/` - Build helper scripts (create-dmg.sh)
- Root level - LICENSE, README.md, CONTRIBUTING.md
- `.github/ISSUE_TEMPLATE/` - Issue templates

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Repository structure and basic configuration

- [X] T001 Create `.github/workflows/` directory structure
- [X] T002 [P] Create `scripts/` directory for build helper scripts
- [X] T003 [P] Create `.github/ISSUE_TEMPLATE/` directory structure
- [X] T004 [P] Verify Xcode project has hardened runtime enabled in Votra.xcodeproj

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**CRITICAL**: No user story work can begin until this phase is complete

- [X] T005 Verify SwiftLint is installed locally and `.swiftlint.yml` is configured
- [X] T006 Ensure Xcode project builds successfully with `CODE_SIGN_IDENTITY=""` for CI
- [X] T007 Verify Xcode project ARCHS is set to `arm64` only (exclude x86_64 to ensure Apple Silicon-only builds)
- [ ] T008 Verify all existing unit tests pass before CI setup (note: UI tests require signing)
- [X] T008.1 [P] Enable GitHub Secret Scanning in repository settings (FR-013 verification):
  - GitHub → Repository → Settings → Code security and analysis
  - Enable "Secret scanning" (free for public repos)
  - Enable "Push protection" to block commits containing secrets
- [X] T008.2 [P] Add gitleaks secret scanning step to ci.yml (FR-013 verification):
  - Add step using `gitleaks/gitleaks-action@v2` before build step
  - Fails CI if secrets detected in committed code
- [X] T008.3 [P] Add optional local pre-commit hook for secret scanning (FR-013 defense-in-depth):
  - Create `.pre-commit-config.yaml` with gitleaks hook (version matching CI action)
  - Create `.gitleaks.toml` with project-specific allowlists (build artifacts, test fixtures, docs)
  - Create `scripts/install-hooks.sh` for contributors without pre-commit framework
  - Update CONTRIBUTING.md with local hook setup: `brew install gitleaks pre-commit && pre-commit install`
  - Document bypass procedure: `SKIP=gitleaks git commit` or `git commit --no-verify`
  - **Note**: This is defense-in-depth; CI scanning (T008.2) is the primary gate

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Download and Install DMG (Priority: P1) MVP

**Goal**: Users can download DMG from GitHub Releases and install without Gatekeeper blocking

**Independent Test**: Download DMG from GitHub Release, install on clean Mac, verify app launches without Gatekeeper warning

### Implementation for User Story 1

#### Secrets Setup (One-time, Manual)

- [ ] T009 [US1] Export Developer ID Application certificate as .p12:
  - Open Keychain Access → My Certificates
  - Find "Developer ID Application: Your Name (TEAM_ID)"
  - Right-click → Export → Save as .p12 with password
  - Base64 encode: `base64 -i certificate.p12 | pbcopy`
- [ ] T010 [US1] Create App Store Connect API Key for notarization:
  - App Store Connect → Users and Access → Integrations → App Store Connect API
  - Click + to create new key with "Developer" access
  - Note the Key ID and Issuer ID
  - Download .p8 file (only available once!)
  - Base64 encode: `base64 -i AuthKey_XXXXXX.p8 | pbcopy`
- [ ] T011 [US1] Add all secrets to GitHub repository:
  - GitHub → Repository → Settings → Secrets and variables → Actions
  - Add secrets:
    - `DEVELOPER_CERTIFICATE_P12`: base64-encoded .p12 file
    - `DEVELOPER_CERTIFICATE_PASSWORD`: password for .p12
    - `KEYCHAIN_PASSWORD`: any secure random string
    - `APPLE_TEAM_ID`: your 10-character team ID
    - `NOTARY_KEY_ID`: API Key ID from App Store Connect
    - `NOTARY_ISSUER_ID`: Issuer ID from App Store Connect
    - `NOTARY_KEY_P8`: base64-encoded .p8 file

#### Release Workflow

- [X] T012 [US1] Create `.github/workflows/release.yml` with:
  - Trigger: `push: tags: ['v*.*.*']`
  - Runner: `macos-26` (Apple Silicon)
  - Job timeout: `timeout-minutes: 45` (15m notarization + 30m buffer for build/sign/DMG steps)
  - Steps: checkout, setup keychain, import certificate, build archive, sign, notarize, staple, create DMG, upload to GitHub Releases
  - Notarization MUST use `xcrun notarytool submit --wait --timeout 15m` (15 minutes is generous; typical notarization completes in 2-5 minutes — fail fast to avoid wasting runner minutes)
  - Keychain cleanup MUST run in `if: always()` step to prevent credential leakage
  - All shell steps MUST use `set -euo pipefail` for strict error handling
  - Each critical step MUST have explicit error message on failure
- [X] T013 [US1] Create `scripts/create-dmg.sh` helper script:
  - Create temp DMG with hdiutil (read-write format)
  - Copy app and create Applications symlink
  - Convert to ULFO format (LZFSE compression — optimal for macOS 10.11+, best size/speed ratio)
  - Sign DMG with Developer ID Application certificate
- [X] T014 [US1] Make scripts executable: `chmod +x scripts/*.sh`
- [ ] T015 [US1] Test release by pushing tag v0.1.0-test:
  - `git tag v0.1.0-test && git push origin v0.1.0-test`
  - Verify GitHub Actions workflow starts (visible in Actions tab)
  - Verify DMG appears in GitHub Releases
  - Download DMG and verify Gatekeeper passes: `spctl -a -v -t install Votra-0.1.0-test.dmg`

**Checkpoint**: DMG can be created, signed, notarized, stapled, and downloaded. All logs visible in GitHub Actions. Gatekeeper passes.

---

## Phase 4: User Story 2 - Automated Release Pipeline (Priority: P2)

**Goal**: Pushing a version tag automatically creates a GitHub Release with signed DMG

**Independent Test**: Push tag `v*.*.*`, verify Release appears with DMG attached

### Implementation for User Story 2

- [X] T016 [US2] Verify release.yml includes all required steps:
  - Version extraction from tag
  - SwiftLint check (fail-fast, blocks release on warnings/errors)
  - Unit tests via `xcodebuild test` (fail-fast, blocks release on test failures)
  - Archive, sign, notarize, staple
  - DMG creation with checksums.txt
  - GitHub Release with auto-generated notes
- [X] T017 [US2] Add SHA-256 checksum generation to release workflow: `shasum -a 256 "$DMG_NAME" > checksums.txt`
- [ ] T018 [US2] Test automated release with tag v0.2.0-test:
  - Push tag: `git tag v0.2.0-test && git push origin v0.2.0-test`
  - Verify GitHub Actions workflow runs (publicly visible in Actions tab)
  - Verify GitHub Release created with DMG and checksums.txt
  - Review workflow logs to confirm transparency
- [X] T018.1 [US2] Document notarization timeout behavior in quickstart.md troubleshooting:
  - If Apple notarization service is unavailable, `--wait --timeout 15m` causes workflow to fail fast
  - 15 minutes is generous for typical notarization (usually completes in 2-5 minutes)
  - If consistently timing out, check Apple Developer System Status before re-running
  - Rationale: Fail fast avoids wasting GitHub Actions minutes on unrecoverable situations
- [ ] T018.2 [US2] Verify SC-002 timing compliance:
  - After T018 release test completes, check workflow duration in Actions tab
  - Total duration SHOULD be < 30 minutes (including notarization wait)
  - If exceeding 30 minutes, investigate bottlenecks:
    - Notarization queue delays (check Apple Developer System Status)
    - Build cache misses (consider caching SwiftLint via Homebrew)
    - Runner availability (public repo runners may have queue delays)
  - Document baseline timing in quickstart.md troubleshooting section

**Checkpoint**: Tag push triggers full automated release pipeline. All steps visible in GitHub Actions logs.

---

## Phase 5: User Story 3 - Continuous Integration for PRs (Priority: P3)

**Goal**: PRs are automatically built and tested before merge

**Independent Test**: Open PR with intentional test failure, verify CI reports failure

### Implementation for User Story 3

- [X] T019 [P] [US3] Create `.github/workflows/ci.yml` based on contracts/ci-workflow.yml:
  - Triggers: `pull_request: branches: [main]`, `push: branches: [main]`
  - Runner: `macos-26` (Apple Silicon, free for public repos)
  - Steps: checkout, gitleaks secret scan (FR-013), SwiftLint (`--strict`), build (no signing), test
  - **FR-007 Verification**: The `--strict` flag changes exit code behavior — without it, SwiftLint exits 0 even with warnings; with `--strict`, exit code is non-zero (2) on ANY violation (warning or error). This satisfies FR-007 "zero warnings AND zero errors" because exit code 0 only occurs when there are zero violations of any severity. Note: `--strict` does NOT visually convert warnings to errors in output, it only affects the exit code.
- [X] T020 [US3] Configure concurrency settings to cancel in-progress runs:
  - `concurrency: group: ci-${{ github.ref }}, cancel-in-progress: true`
- [X] T021 [US3] Add CODE_SIGN_IDENTITY="" and CODE_SIGNING_REQUIRED=NO to xcodebuild commands
- [ ] T022 [US3] Test CI workflow by opening a PR with a small change
- [ ] T023 [US3] Test CI failure handling by introducing intentional test failure in PR
- [ ] T023.1 [US3] Verify SC-003 timing compliance:
  - After T022 PR test completes, check workflow duration in Actions tab
  - Duration MUST be < 10 minutes for typical changes (≤20 files, ≤1000 lines)
  - If exceeding 10 minutes, investigate caching opportunities (SwiftLint, dependencies)
  - Document baseline timing in quickstart.md troubleshooting section

**Checkpoint**: PR CI runs automatically, logs are public, and blocks merge on failure

---

## Phase 6: User Story 4 - Open Source Repository Setup (Priority: P4)

**Goal**: Repository has proper open source documentation and templates

**Independent Test**: Review repository files, create test issue using template

### Implementation for User Story 4

- [X] T024 [P] [US4] Create LICENSE file with MIT License text
- [X] T025 [P] [US4] Create README.md with:
  - Project description
  - Requirements: macOS 26.2+, Apple Silicon only
  - Installation (3-step: download, mount, drag)
  - Build instructions for contributors
  - CI/CD badges (build status, release version)
  - Verify: README contains all sections required by FR-012
- [X] T026 [P] [US4] Create CONTRIBUTING.md with:
  - **Development environment setup**: Xcode 26+ installation, clone instructions, `open Votra.xcodeproj`
  - **Building locally**: `xcodebuild build` command with required flags
  - **Running tests**: `xcodebuild test` command
  - **Code style**: SwiftLint configuration, `swiftlint lint --strict` before commit
  - **PR guidelines**: Branch naming, commit message format, PR checklist reference
  - **Optional local hooks**: Reference to T008.3 pre-commit hook setup (`brew install gitleaks pre-commit && pre-commit install`)
  - Verify: CONTRIBUTING.md satisfies US4 acceptance criteria #3 (developer can set up environment and submit PRs)
- [X] T027 [P] [US4] Create .github/ISSUE_TEMPLATE/bug_report.yml with structured bug report form
- [X] T028 [P] [US4] Create .github/ISSUE_TEMPLATE/feature_request.yml with feature request form
- [X] T029 [P] [US4] Create .github/PULL_REQUEST_TEMPLATE.md with checklist
- [X] T030 [US4] Add CI status badge to README.md after CI workflow is active
- [X] T030.1 [US4] Configure GitHub branch protection rules for main branch:
  - GitHub → Repository → Settings → Branches → Add rule for `main`
  - Enable "Require a pull request before merging"
  - Enable "Require status checks to pass before merging"
  - Add required status check: `build-and-test` (from ci.yml)
  - Enable "Do not allow bypassing the above settings"

**Checkpoint**: Repository has complete open source documentation and templates

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final improvements and verification

### Local Workflow Testing with act

- [ ] T031 Install nektos/act for local GitHub Actions testing: `brew install act`
- [ ] T032 [P] Test ci.yml locally with act: `act pull_request --dryrun` then `act pull_request`
- [ ] T033 [P] Test release.yml locally with act (using mock secrets): `act push --secret-file .secrets.example -e event.json`
- [ ] T034 Verify all workflow steps execute correctly in act before pushing

### Final Verification

- [X] T035 [P] Update .gitignore to exclude new build artifacts:
  - `build/` - xcodebuild output directory
  - `*.dmg` - generated disk images
  - `*.xcarchive` - Xcode archives
  - `TestResults.xcresult` - test result bundles
  - `.secrets*` - local secret files for act testing
  - `certificate.p12` - temporary certificate files
- [ ] T036 Run full release workflow test with final tag (e.g., v1.0.0-rc1)
- [ ] T037 Verify DMG passes `spctl --assess --type install Votra-*.dmg` on clean Mac
- [ ] T038 Verify app passes all security checks after installation (SC-006, SC-007, SC-008):
  - `codesign --verify --deep --strict Votra.app` (SC-007: code signature valid)
  - `spctl --assess --type exec Votra.app` (SC-006: Gatekeeper accepts executable)
  - `stapler validate Votra.app` (SC-008: notarization ticket stapled)
- [ ] T039 Run quickstart.md validation - follow all steps on fresh setup
- [ ] T040 Clean up any test tags and releases from GitHub

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-6)**: All depend on Foundational phase completion
  - US1 (DMG) must complete before US2 (Automated Release) can be fully tested
  - US3 (PR CI) is independent of US1/US2
  - US4 (Documentation) is independent of all other stories
- **Polish (Phase 7)**: Depends on all user stories being complete

### User Story Dependencies

```
Phase 1 (Setup)
    |
Phase 2 (Foundational)
    |
    +-- US1 (DMG + Release Workflow) --> US2 (Verify Automation)
    |
    +-- US3 (PR CI) <-- Independent
    |
    +-- US4 (Documentation) <-- Independent
    |
Phase 7 (Polish)
```

### Parallel Opportunities

**Phase 1 (all parallel)**:
- T002, T003, T004 can run in parallel

**Phase 2 (partial parallel)**:
- T008.1, T008.2, T008.3 can run in parallel (all independent secret scanning setup)

**Phase 6 (all parallel)**:
- T024, T025, T026, T027, T028, T029 can all run in parallel (T030 depends on CI being active)

**Cross-story parallel**:
- US3 (PR CI) can be worked on in parallel with US1/US2
- US4 (Documentation) can be worked on in parallel with all other stories

---

## Manual Steps Summary

These tasks require manual action in external systems:

| Task | System | Action |
|------|--------|--------|
| T009 | Keychain Access | Export Developer ID certificate as .p12 |
| T010 | App Store Connect | Create API Key for notarization |
| T011 | GitHub | Add 7 secrets to repository settings |

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- **All workflow logs are publicly visible** in GitHub Actions tab
- Manual steps are clearly marked and documented in quickstart.md
- No additional unit test implementation tasks included; verification tasks (T022, T023, T036-T039) cover workflow testing
