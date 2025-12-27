# GearGuard

Maintenance tracker (Flutter) — GearGuard

This README helps other contributors run the project locally, understand a couple of known issues, and shows how to record a demo video on macOS.

## Quick Setup

Prerequisites:
- Flutter SDK (project uses Flutter 3.x+, Dart 3.x). Verify with `flutter --version`.
- A Firebase project with Firestore enabled and the web config placed in `lib/firebase_config.dart`.

Steps:

1. Open a terminal in the project root:

```bash
cd /Users/shreyshah/AndroidStudioProjects/gearguard
```

2. Install dependencies:

```bash
flutter pub get
```

3. Run the app on Chrome:

```bash
flutter run -d chrome
```

If you prefer a different target, run `flutter devices` then `flutter run -d <deviceId>`.

## Firebase / Firestore notes

- This app queries `maintenanceRequests` with an equality on `type` and a range on `scheduledDate`.
  Firestore requires a composite index for that combination. Create an index with these exact settings:

  - Collection ID: `maintenanceRequests`
  - Fields (in this order):
    1. `type` — Ascending
    2. `scheduledDate` — Ascending
  - Query scope: `Collection`

- You can create the index in the Firebase Console: Firestore Database → Indexes → Add Index.
  When you run the app and the index is missing, Firestore also prints a helpful link in the browser error banner — open that link to pre-fill the index creation UI.

Quick workaround (if you cannot create the index immediately):

- The code contains a fallback option to query by `scheduledDate` only and filter `type` client-side (less efficient). If you need I can enable that permanently.

## UI notes

- Dark theme is enabled by default in `lib/main.dart` (`themeMode: ThemeMode.dark`). Modify `themeMode` or `darkTheme` in that file to adjust appearance.

- If you see a dropdown assertion error when opening the create-request form, ensure data has loaded (the UI waits by showing a spinner). If you still see it, run `flutter pub get` and re-run the app.

## Git (push your local code to a remote)

If you want to replace the remote repository contents with this local tree (force overwrite), use these commands (WARNING: this deletes remote history and remote changes):

```bash
cd /Users/shreyshah/AndroidStudioProjects/gearguard
git init
git add --all
git commit -m "Replace repo with local GearGuard snapshot"
git remote add origin <YOUR_REMOTE_URL>
# Force-push to main (or change to master if your remote uses master):
git push --force origin main
```

Replace `<YOUR_REMOTE_URL>` with your repo URL (HTTPS or SSH). Confirm with your team before forcing a push.

## Recording a demo on macOS

- Quick (built-in): Press `Shift + ⌘ + 5` and choose `Record Entire Screen` or `Record Selected Portion`.
- QuickTime: Open QuickTime Player → File → New Screen Recording.
- For advanced recording (multi-sources, overlays): install OBS Studio (https://obsproject.com).

Tips: Record the app with Chrome open via `flutter run -d chrome`, use a microphone if you want voice-over, and crop the recorded video if needed.

## Troubleshooting

- Dependencies: run `flutter pub get` then `flutter clean` and re-run if build issues appear.
- Web build errors related to older firebase_web interop were resolved by upgrading packages; run `flutter pub upgrade --major-versions` if you see incompatibilities.

## Contact / next steps

- If you'd like, I can:
  - Generate the exact Firebase Console link for the index if you paste the in-app error link.
  - Apply the client-side fallback for the index query.
  - Help push this repo to your remote and force-overwrite remote history (only after confirmation).

---
Project maintained in this workspace. See `lib/` for the app source.
# gearguard

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
