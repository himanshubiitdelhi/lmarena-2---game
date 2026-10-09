# Browser gameplay playtest

This optional, dependency-free browser harness exists so the core one-tap timing loop can be tried without an Android device or Flutter SDK. It is a development preview only; it is not included in the Flutter app or Play release.

## Run locally

From the repository root:

```sh
python3 -m http.server 4173 --bind 0.0.0.0 --directory playtest
```

Open `http://localhost:4173`. On a phone, use the same URL on the computer's LAN address. The hosted Arena preview runs the same static `playtest/` files.

## Controls

- Press **Start Playtest**, then tap/click the game area or press **Space** to launch.
- Watch the gold arc around the current planet; tapping as the blob crosses it gives a perfect landing.
- Chain five perfect launches to trigger Fever Mode. Later planets introduce movement, spikes, shrinking, and the rising danger line.
- Use the pause button to pause/resume, or **Restart Playtest** to start over. The browser preview stores only its best score in local storage.

This harness reproduces the main orbit/launch/landing timing and a subset of game feel for quick playtesting. It does not execute the Dart/Flame code, Android lifecycle, haptics/audio, reward economy, ads, purchases, or Google Play Games. Verify final balance and integrations with the Android build described in [`SETUP.md`](SETUP.md) and [`TESTING.md`](TESTING.md).
