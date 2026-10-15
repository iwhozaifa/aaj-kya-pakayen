# Releasing

## 1. One-time: create the upload key

Play App Signing holds the real app-signing key. Builds are signed with an **upload key**, which you create once and keep safe, outside the repository:

```bash
keytool -genkey -v -keystore ~/aaj-kya-pakayen-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Back up the `.jks` file and its passwords, for example in a password manager. If they are lost, the upload key has to be reset through Play Console.

## 2. Sign builds locally

Create `android/key.properties`. It is git-ignored, as are `*.jks` and `*.keystore`, and a test checks that they stay ignored.

```properties
storePassword=<keystore password>
keyPassword=<key password>
keyAlias=upload
storeFile=/home/<you>/aaj-kya-pakayen-upload.jks
```

`storeFile` is resolved from `android/app/`, so use an absolute path or one relative to that folder. Then build:

```bash
flutter build appbundle --release   # build/app/outputs/bundle/release/app-release.aab, for Play
flutter build apk --release         # build/app/outputs/flutter-apk/app-release.apk, to install directly
```

Without `key.properties`, release builds fall back to the debug key. They run, but they can't be published and won't install over a store version.

## 3. Sign builds in CI (optional)

`.github/workflows/release.yml` runs when a `v*` tag is pushed. It tests, builds the release APK and App Bundle, and attaches them to the GitHub release. To sign them with the upload key, add these repository secrets (Settings → Secrets and variables → Actions):

| Secret | Value |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | `base64 -w0 ~/aaj-kya-pakayen-upload.jks` |
| `ANDROID_KEYSTORE_PASSWORD` | keystore password |
| `ANDROID_KEY_PASSWORD` | key password |
| `ANDROID_KEY_ALIAS` | `upload` |

Without the secrets, the workflow still runs and labels its files `debug-signed`.

## 4. Cut a release

The full Git steps are in [GIT_WORKFLOW.md](GIT_WORKFLOW.md). In short:

1. Branch `release/x.y.z` from `develop`.
2. Bump `version:` in `pubspec.yaml`. The build number after `+` must always increase.
3. Add a dated `## [x.y.z] - YYYY-MM-DD` section to `CHANGELOG.md`. `test/release/release_readiness_test.dart` checks it.
4. Open a PR into `main` and merge it with a **merge commit** once CI is green.
5. Tag `main` with `git tag -a vx.y.z -m "vx.y.z" && git push origin vx.y.z`. The release workflow builds and attaches the files.
6. Merge `main` back into `develop` and delete the release branch.
