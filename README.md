# SRP AI APP 🤖

A kid-friendly voice chatbot powered by on-device AI using Gemma 2B. Kids can talk to "Sparky" — a friendly robot buddy who responds with voice, all running offline on the device!

## ✨ Features

- **🔐 Secure Login** — Username/password authentication with secure storage
- **🤖 Sparky the Robot** — Playful AI persona designed for kids ages 4-12
- **🎤 Voice Input** — Speak to Sparky using speech-to-text
- **🔊 Auto-Read Responses** — Text-to-speech reads all AI responses (with stop option)
- **⌨️ Keyboard Fallback** — Type messages when voice isn't available
- **🛡️ Kid-Safe Content** — Built-in filters block inappropriate content
- **📱 Offline First** — AI runs entirely on-device, no internet needed after model download
- **🎨 Fun Animated UI** — Colorful, kid-friendly interface with animated robot avatar

![SRP AI App](https://github.com/user-attachments/assets/0e27399f-4603-4e51-8101-86ace29b6ae8)

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK** 3.8.0 or higher
- **VS Code** with Flutter extension (recommended)
- **Android Studio** (for Android builds) or **Xcode** (for iOS builds)
- **Hugging Face Account** — For model download token

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/srp_ai_app.git
cd srp_ai_app
```

### 2. Add Your Hugging Face Token

Open `lib/data/downloader_datasource.dart` and replace the placeholder with your token:

```dart
final accessToken = "YOUR_HUGGING_FACE_TOKEN_HERE";
```

> Get your token at: https://huggingface.co/settings/tokens

### 3. Install Dependencies

```bash
flutter pub get
```

---

## 💻 Running in VS Code

### Option A: Using VS Code Run Button

1. Open the project folder in VS Code
2. Open `lib/main.dart`
3. Click **Run > Start Debugging** (or press `F5`)
4. Select your target device (emulator or connected device)

### Option B: Using Terminal in VS Code

1. Open VS Code integrated terminal (`Ctrl+`` or `Cmd+``)
2. Run the app:

```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d <device_id>

# Run on all connected devices
flutter run -d all
```

### Option C: Using VS Code Command Palette

1. Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on macOS)
2. Type "Flutter: Select Device" and choose your device
3. Type "Flutter: Run Flutter Project" to start the app

---

## 📱 Building for Android

### Debug APK (for testing)

```bash
flutter build apk --debug
```

Output: `build/app/outputs/flutter-apk/app-debug.apk`

### Release APK (for distribution)

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Split APKs (smaller file sizes per architecture)

```bash
flutter build apk --split-per-abi
```

Outputs:
- `app-armeabi-v7a-release.apk` (32-bit ARM)
- `app-arm64-v8a-release.apk` (64-bit ARM) ← Most common
- `app-x86_64-release.apk` (x86_64 emulators)

### App Bundle (for Google Play Store)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### Install APK on Connected Device

```bash
# Build and install in one step
flutter install

# Or manually install the APK
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## 🍎 Building for iOS

### Prerequisites for iOS

1. **macOS** with Xcode 15+ installed
2. **Apple Developer Account** (free for testing, paid for App Store)
3. **CocoaPods** installed:
   ```bash
   sudo gem install cocoapods
   ```

### Setup iOS Project

```bash
cd ios
pod install
cd ..
```

### Run on iOS Simulator

```bash
flutter run -d "iPhone 15 Pro"
```

### Build iOS App (Debug)

```bash
flutter build ios --debug --no-codesign
```

### Build iOS App (Release)

```bash
flutter build ios --release
```

### Open in Xcode for Distribution

```bash
open ios/Runner.xcworkspace
```

In Xcode:
1. Select **Product > Archive**
2. Click **Distribute App**
3. Choose distribution method (App Store, Ad Hoc, Enterprise)

---

## 🔧 Configuration

### Android Configuration

Edit `android/app/build.gradle.kts`:

```kotlin
android {
    namespace = "com.yourcompany.srp_ai_app"
    
    defaultConfig {
        applicationId = "com.yourcompany.srp_ai_app"
        minSdk = 24  // Required for flutter_gemma
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
    }
}
```

### iOS Configuration

Edit `ios/Runner/Info.plist` to add required permissions:

```xml
<!-- Microphone for speech-to-text -->
<key>NSMicrophoneUsageDescription</key>
<string>SRP AI App needs microphone access so you can talk to Sparky!</string>

<!-- Speech recognition -->
<key>NSSpeechRecognitionUsageDescription</key>
<string>SRP AI App uses speech recognition to understand what you say.</string>
```

---

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point
├── data/
│   ├── chat_service.dart     # Gemma AI integration with kid-safe prompts
│   ├── speech_service.dart   # TTS & STT wrapper
│   └── downloader_datasource.dart  # Model download manager
├── domain/
│   └── download_model.dart   # Model data class
└── ui/
    ├── screens/
    │   ├── login_screen.dart         # Authentication
    │   ├── model_download_screen.dart # Model download progress
    │   └── chat_screen.dart          # Main chat interface
    └── widgets/
        └── robot_avatar.dart         # Animated Sparky avatar
```

---

## 🛠️ Tech Stack

| Package | Purpose |
|---------|---------|
| `flutter_gemma` | On-device Gemma AI inference |
| `flutter_tts` | Text-to-speech for auto-read |
| `speech_to_text` | Voice input recognition |
| `flutter_secure_storage` | Secure credential storage |
| `lottie` | Smooth animations |
| `flutter_markdown_plus` | Markdown rendering in chat |

---

## 🛡️ Safety Features

Sparky is designed to be safe for kids:

- ✅ Age-appropriate responses (4-12 years)
- ✅ Content filters block violence, profanity, adult topics
- ✅ Redirects inappropriate questions positively
- ✅ Encourages learning, creativity, and kindness
- ✅ Never asks for or reveals personal information

---

## 🐛 Troubleshooting

### Model Download Fails
- Check your Hugging Face token is valid
- Ensure stable internet connection for initial download
- Model is ~1.5GB, ensure sufficient storage

### Voice Not Working
- Check microphone permissions in device settings
- iOS: Enable Speech Recognition in Settings > Privacy
- Android: Grant microphone permission when prompted

### App Crashes on Launch
- Ensure minimum SDK is 24 (Android) or iOS 12+
- Run `flutter clean && flutter pub get`
- Check device has enough RAM (2GB+ recommended)

---

## 📄 License

MIT License - feel free to use this for learning and building!

---

## 🙏 Acknowledgments

- [flutter_gemma](https://pub.dev/packages/flutter_gemma) package
- Google's Gemma 2B model
- Original project inspiration: [Medium Article](https://medium.com/@vogelcsongorbenedek/using-gemma-for-flutter-apps-91f746e3347c)

---

**Made with ❤️ for kids who love to chat with robots!**
