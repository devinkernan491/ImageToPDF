# ImageToPDF for Android 📱

Native Android application that converts images and code files to PDF with syntax highlighting.

---

## 🚀 Building & Running

### 1. In Android Studio
Open the `android/` directory directly in Android Studio. Gradle will sync automatically and you can run it on any Android device or emulator!

### 2. From Command Line (Gradle)
```bash
cd android
./gradlew assembleDebug
```
The APK will be generated at `app/build/outputs/apk/debug/app-debug.apk`.

---

## ✨ Features
- Pick multiple images and code files (`.py`, `.cpp`, `.c`, `.swift`, `.js`, etc.)
- Multi-page PDF generation using Android's native `android.graphics.pdf.PdfDocument`
- Syntax highlighting and line numbers for code
- One-tap Android Share Sheet to open or share via Gmail, Drive, WhatsApp, Slack, etc.
