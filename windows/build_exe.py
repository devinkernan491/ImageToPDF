"""
Build script to compile ImageToPDF into a standalone Windows .exe using PyInstaller.
"""

import os
import subprocess
import sys

def build():
    print("🔨 Building ImageToPDF for Windows...")
    cmd = [
        sys.executable, "-m", "PyInstaller",
        "--name=ImageToPDF",
        "--onefile",
        "--windowed",
        "--add-data=pdf_converter.py;.",
        "app.py"
    ]
    
    # Add icon if available
    if os.path.exists("../AppIcon.ico"):
        cmd.insert(-1, "--icon=../AppIcon.ico")
    elif os.path.exists("icon.ico"):
        cmd.insert(-1, "--icon=icon.ico")

    result = subprocess.run(cmd)
    if result.returncode == 0:
        print("✅ Standalone Windows executable created in dist/ImageToPDF.exe")
    else:
        print(f"❌ Build failed with return code {result.returncode}")
        sys.exit(result.returncode)

if __name__ == "__main__":
    build()
