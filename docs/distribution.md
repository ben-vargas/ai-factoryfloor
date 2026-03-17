# Distribution Guide

## Version Release Routine

Step-by-step process for releasing a new version:

1. **Merge conventional commits to `main`.**
   Use [Conventional Commits](https://www.conventionalcommits.org/) format (`feat:`, `fix:`, etc.) so release-please can determine version bumps.

2. **release-please creates a version bump PR.**
   On each push to `main`, the Release workflow runs release-please. If there are releasable commits, it opens (or updates) a PR that bumps the version in `.release-please-manifest.json` and updates the changelog.

3. **Merge the release-please PR.**
   This creates a GitHub release with a tag (e.g., `v1.2.0`).

4. **CI builds, signs, notarizes, packages, uploads, and updates Homebrew.**
   The `build` job triggers automatically when a release is created. It handles everything end-to-end (see CI Release Workflow below).

5. **Verify the release on GitHub.**
   Check that the DMG asset is attached to the release at `https://github.com/alltuner/factoryfloor/releases`.

6. **Website deploys automatically.**
   If the release included changes under `website/`, the `deploy-website.yml` workflow builds and deploys the site to GitHub Pages. It can also be triggered manually via `workflow_dispatch`.

## CI Release Workflow

The release workflow (`.github/workflows/release.yml`) runs on every push to `main` and has two jobs:

### Job 1: `release-please` (ubuntu-latest)

Runs `googleapis/release-please-action@v4` to manage version bumps and changelogs. Outputs `release_created`, `version`, and `tag_name` for downstream jobs.

### Job 2: `build` (macos-15)

Only runs when `release_created` is true. Steps:

1. Checks out the repo with submodules (for the Ghostty xcframework)
2. Installs XcodeGen via Homebrew
3. Generates the Xcode project (`xcodegen generate`)
4. Imports the signing certificate into a temporary keychain
5. Builds the release configuration with xcodebuild
6. Signs the app and DMG with the Developer ID Application certificate
7. Stores notarization credentials in the temporary keychain
8. Submits the DMG to Apple for notarization and waits for approval
9. Staples the notarization ticket to the DMG
10. Uploads the DMG to the GitHub release via `gh release upload`
11. Updates the Homebrew cask in `alltuner/homebrew-tap` with the new version and SHA256
12. Cleans up the temporary keychain

### Required Secrets

Configure these in the repository settings (Settings > Secrets and variables > Actions):

| Secret | Description | How to get it |
|--------|-------------|---------------|
| `CERTIFICATE_P12_BASE64` | Developer ID Application certificate + private key, base64-encoded | Export from Keychain Access as .p12, then `base64 -i cert.p12` |
| `CERTIFICATE_PASSWORD` | Password for the .p12 file | Set during export from Keychain Access |
| `APPLE_ID` | Apple ID email for notarization | Your Apple Developer account email |
| `APPLE_TEAM_ID` | Apple Developer team ID | `J5TAY75Q3F` (All Tuner Labs) |
| `APPLE_APP_PASSWORD` | App-specific password for notarytool | Generate at https://appleid.apple.com > Sign-In and Security > App-Specific Passwords |
| `HOMEBREW_TAP_TOKEN` | GitHub PAT with `public_repo` scope for alltuner/homebrew-tap | Generate at https://github.com/settings/tokens |

## Website Deployment

The website deploys via `.github/workflows/deploy-website.yml`:

- **Triggers:** pushes to `main` that change files under `website/`, or manual `workflow_dispatch`
- **Build:** Hugo (extended, latest) + Bun for asset processing
- **Deploy:** GitHub Pages via `actions/deploy-pages@v4`

## Local Release Script

`scripts/release.sh` builds a signed, notarized DMG locally. Useful for testing the release pipeline or creating ad-hoc builds.

```bash
./scripts/release.sh [version]
```

If no version is provided, it reads from `Resources/Info.plist`.

### Prerequisites

- **Signing identity:** `Developer ID Application: ALL TUNER LABS S.L. (J5TAY75Q3F)` must be in your Keychain
- **Notarization profile:** stored in Keychain as `factoryfloor` (set up once with `xcrun notarytool store-credentials`)
- **XcodeGen:** installed via `brew install xcodegen`

### What it does

1. Generates the Xcode project with XcodeGen
2. Builds the release configuration
3. Signs the app with the Developer ID certificate and hardened runtime
4. Verifies the signature with `codesign` and `spctl`
5. Creates a DMG and signs it
6. Submits to Apple for notarization and waits
7. Staples the notarization ticket to the DMG

The output DMG is at `build/release/FactoryFloor-VERSION.dmg`. Upload it to a GitHub release with:

```bash
gh release upload vVERSION build/release/FactoryFloor-VERSION.dmg
```

## Code Signing and Notarization

### Prerequisites

1. **Apple Developer account** ($99/year): https://developer.apple.com/programs/
2. **Developer ID Application certificate**: Xcode > Settings > Accounts > Manage Certificates > Developer ID Application
3. **Notarization credentials**: App-specific password from https://appleid.apple.com (under Sign-In and Security > App-Specific Passwords)

### Local setup

Store notarization credentials in your Keychain so `release.sh` can use them:

```bash
xcrun notarytool store-credentials "factoryfloor" \
  --apple-id "your@email.com" \
  --team-id "J5TAY75Q3F" \
  --password "app-specific-password"
```

### CI setup

In CI, the workflow imports the certificate from `CERTIFICATE_P12_BASE64` into a temporary keychain and stores notarization credentials using `notarytool store-credentials` with the `APPLE_ID`, `APPLE_TEAM_ID`, and `APPLE_APP_PASSWORD` secrets. The temporary keychain is deleted after the build.

## Homebrew Cask

Factory Floor is distributed via a Homebrew cask in the `alltuner/homebrew-tap` repository.

### Installation

```bash
brew install alltuner/tap/factoryfloor
```

### Cask formula

The cask at `Casks/factoryfloor.rb` in `alltuner/homebrew-tap` is updated automatically by the CI release workflow. It includes:

- DMG download URL pointing to the GitHub release asset
- SHA256 checksum of the DMG
- `depends_on macos: ">= :sonoma"`
- `app "Factory Floor.app"` to copy the app to `/Applications`
- `zap trash` entries for `~/.config/factoryfloor`, `~/.factoryfloor`, and the preferences plist

### Manual cask update

If you need to update the cask manually (e.g., CI failed):

```bash
VERSION="1.2.0"
SHA256=$(shasum -a 256 build/release/FactoryFloor-${VERSION}.dmg | awk '{print $1}')
# Edit Casks/factoryfloor.rb in alltuner/homebrew-tap with the new version and SHA256
```

## CLI (`ff`)

The `ff` command is a shell script bundled inside `Factory Floor.app` at `Contents/Resources/ff`. It opens directories in Factory Floor using the `factoryfloor://` URL scheme.

When installed via Homebrew, the cask does not install the CLI binary automatically. To set it up:

```bash
sudo ln -sf "/Applications/Factory Floor.app/Contents/Resources/ff" /usr/local/bin/ff
```

Usage:

```bash
ff              # open Factory Floor
ff /path/to/dir # open a directory in Factory Floor
```
