# ImageToPDF 📄

A native macOS application built with Swift and SwiftUI that converts images and program source code files into single or multi-page PDFs with drag-and-drop, syntax highlighting, custom page layout, compression options, and built-in PDF preview.

[![Download DMG](https://img.shields.io/badge/Download-ImageToPDF.dmg-blue?style=for-the-badge&logo=apple)](https://github.com/devinkernan491/ImageToPDF/releases/latest/download/ImageToPDF.dmg)

---

## ✨ Features

- **Drag-and-Drop**: Drag individual image files, code files, or entire folders directly into the window. All supported files are recursively found and automatically sorted naturally (e.g. `file_1`, `file_2`, `file_10`).
- **Broad File Format Support**:
  - **Program Code Files**: `.py`, `.cpp`, `.c`, `.h`, `.hpp`, `.swift`, `.js`, `.ts`, `.rs`, `.go`, `.java`, `.kt`, `.sh`, `.json`, `.xml`, `.yaml`, `.sql`, `.dart`, `.md`, `.txt`, and more.
  - **Images**: PNG, JPEG/JPG, HEIC/HEIF (native iPhone camera photos), WebP, TIFF, BMP, and GIF.
- **Syntax Highlighting & Code Pagination**:
  - Monospace font (`Menlo`) with syntax coloring for keywords, types, strings, comments, numbers.
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
- **Built-in PDF Preview**: Inspect your multi-page document before saving.
- **Dual Mode (GUI + CLI)**: Run as a full macOS graphical app or automate directly from Terminal.

---

## 🚀 Quick Start

### 1. Launch the Graphical App
To run the app right away:
```bash
open ~/ImageToPDF/ImageToPDF.app
```
Then simply **drag and drop any image, code file (.py, .cpp, etc.), or folder** right onto the app window!

### 2. Install to Applications (Optional)
To copy the app into your Mac's `/Applications` folder:
```bash
cd ~/ImageToPDF
./build_app.sh --install
```
Once installed, you can launch **Image to PDF** from Spotlight (`Cmd + Space`), Launchpad, or pin it to your Dock!

---

## 💻 Terminal / CLI Usage

You can pass code files, images, or entire folders via terminal:

```bash
# Convert Python and C++ source code to PDF
~/ImageToPDF/ImageToPDF.app/Contents/MacOS/ImageToPDF main.py controller.cpp -o code_review.pdf

# Convert a mix of code files and images
~/ImageToPDF/ImageToPDF.app/Contents/MacOS/ImageToPDF script.py diagram.png -o documentation.pdf

# Convert an entire folder of source code
~/ImageToPDF/ImageToPDF.app/Contents/MacOS/ImageToPDF ~/my_project/src -o project_code.pdf

# View CLI options
~/ImageToPDF/ImageToPDF.app/Contents/MacOS/ImageToPDF --help
```

---

## 🛠 Rebuilding & Packaging

To recompile the app after making changes:
```bash
cd ~/ImageToPDF
./build_app.sh
```

To create a new **`.dmg` installer**:
```bash
cd ~/ImageToPDF
./create_dmg.sh
```
Zero third-party dependencies required. Uses Apple's native CoreGraphics, CoreText, PDFKit, and ImageIO frameworks.
