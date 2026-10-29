# ImageToPDF for Windows 🪟

Standalone Windows desktop application and CLI tool that converts images and code files to PDF with syntax highlighting.

---

## 🚀 Running on Windows

### 1. Prebuilt Executable
Download `ImageToPDF.exe` from the [GitHub Releases](https://github.com/devinkernan491/ImageToPDF/releases) and double-click to run. No installation or Python setup required!

### 2. Run from Source
```powershell
# Clone the repository
git clone https://github.com/devinkernan491/ImageToPDF.git
cd ImageToPDF/windows

# Install requirements
pip install -r requirements.txt

# Launch the app
python app.py
```

### 3. Command Line Interface (CLI)
```powershell
# Convert multiple files to a single PDF
python app.py image1.png main.py script.cpp -o output.pdf

# Convert an entire folder
python app.py path\to\folder -o project.pdf
```

---

## 🛠 Building the Windows .exe

To compile your own standalone `.exe`:
```powershell
pip install pyinstaller
python build_exe.py
```
The resulting executable will be created in `dist/ImageToPDF.exe`.
