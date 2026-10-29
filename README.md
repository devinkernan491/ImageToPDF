# File to PDF

A multi-platform suite (macOS, Windows, Android) that converts images and program source code files into single or multi-page PDFs with drag-and-drop, syntax highlighting, custom page layout, compression options, and built-in PDF preview.

[![Download macOS DMG](https://img.shields.io/badge/Download-macOS%20DMG-blue?style=for-the-badge&logo=apple)](https://github.com/devinkernan491/ImageToPDF/releases/latest/download/ImageToPDF.dmg)
[![Download Windows EXE](https://img.shields.io/badge/Download-Windows%20EXE-blue?style=for-the-badge&logo=windows)](https://github.com/devinkernan491/ImageToPDF/releases/latest/download/ImageToPDF-Windows.exe)
[![Download Android APK](https://img.shields.io/badge/Download-Android%20APK-green?style=for-the-badge&logo=android)](https://github.com/devinkernan491/ImageToPDF/releases/latest/download/ImageToPDF.apk)

---

## 📱 Platform Versions

| Platform | Format | Technology | Directory |
|---|---|---|---|
| **macOS** | `.dmg` installer & `.app` | Swift, SwiftUI, PDFKit | Root (`Sources/`, `build_app.sh`, `create_dmg.sh`) |
| **Windows** | `.exe` standalone & GUI | Python, CustomTkinter, ReportLab | [`windows/`](windows/) |
| **Android** | `.apk` & Studio project | Kotlin, Material 3, Android `PdfDocument` | [`android/`](android/) |

---

## ✨ Features Across All Platforms

- **Drag-and-Drop / Multi-Select**: Drag individual image files, code files, or entire folders directly into the window.
- **Broad File Format Support**:
  - **Program Code Files**: `.py`, `.cpp`, `.c`, `.h`, `.hpp`, `.swift`, `.js`, `.ts`, `.rs`, `.go`, `.java`, `.kt`, `.sh`, `.json`, `.xml`, `.yaml`, `.sql`, `.dart`, `.md`, `.txt`, and more.
  - **Images**: PNG, JPEG/JPG, HEIC/HEIF (native iPhone camera photos), WebP, TIFF, BMP, and GIF.
- **Syntax Highlighting & Code Pagination**:
  - Monospace font with syntax coloring for keywords, types, strings, comments, numbers.
  - Line numbers gutter with subtle separators.
  - Automatic line wrapping with `↳` continuation markers.
  - Page header with file name, language badge (e.g. `[Python]`, `[C++]`), and `Page X of Y`.
- **Reordering**: Easily reorder files (Move Up, Move Down, drag) to organize the pages of your PDF.
- **Output Modes**:
  - **Single Combined PDF**: Combines all images and code files into one multi-page PDF document.
  - **Individual PDFs**: Batch converts each file into its own `.pdf` document.
- **Page Layout Options**:
  - **Fit to Image Size / Standard Paper**: Exact resolution for images, and standard US Letter or A4 for code documents.
  - **Orientation**: Auto-matches content, or lock to Portrait/Landscape.
  - **Margins**: None, Small (18 pt), or Normal (36 pt).
  - **Compression**: Choose between Original / Maximum quality, High (90%), Medium (75%), or Compressed (50%) to shrink PDF size.
- **Built-in PDF Preview & Direct Share**: Inspect before saving or share directly via the system share sheet.

---

## 🚀 Quick Start by Platform

### 🍎 macOS
1. Download [ImageToPDF.dmg](https://github.com/devinkernan491/ImageToPDF/releases/latest/download/ImageToPDF.dmg).
2. Drag **ImageToPDF** to **Applications**.
3. Launch from Spotlight (`Cmd + Space`) or terminal:
   ```bash
   open ~/ImageToPDF/ImageToPDF.app
   ```

### 🪟 Windows
1. Download [ImageToPDF-Windows.exe](https://github.com/devinkernan491/ImageToPDF/releases/latest/download/ImageToPDF-Windows.exe) (or run `python windows/app.py`).
2. Double-click `ImageToPDF-Windows.exe` to launch the modern Windows UI!
3. Or use from Command Prompt / PowerShell:
   ```powershell
   ImageToPDF.exe script.py diagram.png -o output.pdf
   ```

### 🤖 Android
1. Download [ImageToPDF.apk](https://github.com/devinkernan491/ImageToPDF/releases/latest/download/ImageToPDF.apk) to your Android phone and install.
2. Or open the [`android/`](android/) project in Android Studio and run on your device.

---

## 🛠 Multi-Platform CI/CD

This repository includes a multi-platform [GitHub Actions workflow](.github/workflows/release.yml) that builds `.dmg` for macOS, `.exe` for Windows, and `.apk` for Android automatically!
