# DAYFLOW Flutter starter

This is a first installable Android MVP of DAYFLOW.

## Included
- Daily dashboard and task completion percentage
- Add, complete and delete planner tasks
- Start/pause a single activity timer
- Create measurable goals and increment/decrement progress
- Basic current-state reports
- On-device persistence using shared_preferences

## Important limitations
- This starter saves data locally on the phone. Firebase cloud login/sync is NOT configured yet.
- The timer total is cumulative, not a full historical activity ledger.
- No notifications or background timer guarantee yet.

## Build
Use Flutter 3.24+ and run:
```bash
flutter pub get
flutter build apk --release
```
APK output: `build/app/outputs/flutter-apk/app-release.apk`

## Cloud build using Codemagic
1. Create a GitHub account and a new repository named `dayflow`.
2. Upload the contents of this folder to the repository (not the ZIP itself).
3. Sign in to Codemagic with GitHub and grant access to the `dayflow` repository.
4. Add an Android workflow and select Flutter.
5. Set build mode to release and Android artifact to APK.
6. Start the build. Download the generated APK from the successful build's Artifacts section.

Firebase cloud sync needs a Firebase project and Android app registration before it can be enabled. Do not put private service-account keys in the repository.
