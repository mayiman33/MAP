## Malaysia Travel (Flutter)

### Run (Web)

```bash
flutter pub get
flutter run -d web-server --debug --web-port 0 --web-hostname 127.0.0.1
```

Flutter prints a URL like `http://127.0.0.1:54348` — open it in your browser.

### Run (Android Emulator) — Setup on Windows

Your project is already Android-ready, but your machine is missing the **Android SDK** (so `flutter doctor` shows Android toolchain as failing). Do this once:

1. Install **Android Studio**.
2. Open Android Studio → **More Actions** → **SDK Manager** and install:
   - **Android SDK Platform** (latest stable)
   - **Android SDK Build-Tools**
   - **Android SDK Command-line Tools (latest)**
   - **Android Emulator**
   - **Android SDK Platform-Tools**
3. Create an emulator:
   - Android Studio → **Device Manager** → **Create device**
4. Point Flutter at your SDK (default path shown below):

```bash
flutter config --android-sdk "%LOCALAPPDATA%\\Android\\Sdk"
flutter doctor --android-licenses
flutter doctor -v
```

5. Start the emulator, then run:

```bash
flutter devices
flutter run
```

### Common issues on this PC

- **JAVA_HOME is set to JDK 8**. Android builds commonly require **Java 17**.
  - Easiest fix: install **Temurin JDK 17** and set `JAVA_HOME` to it (or install Android Studio and use its bundled JDK).
- **Windows desktop build** may be blocked by application control policy on your machine (unrelated to Android).

