"""
ImageToPDF - Windows Application
Modern desktop graphical user interface and CLI converter for Windows.
"""

import os
import sys
import argparse
from typing import List

try:
    import customtkinter as ctk
    USE_CUSTOMTKINTER = True
except ImportError:
    import tkinter as ctk
    USE_CUSTOMTKINTER = False

import tkinter as tk
from tkinter import filedialog, messagebox
from PIL import Image, ImageTk

from pdf_converter import (
    PDFConverter, ConversionSettings, is_supported_file,
    is_code_file, is_image_file, CODE_EXTENSIONS
)

class FileItem:
    def __init__(self, filepath: str):
        self.filepath = filepath
        self.filename = os.path.basename(filepath)
        self.size = os.path.getsize(filepath) if os.path.exists(filepath) else 0
        self.is_code = is_code_file(filepath)
        self.is_image = is_image_file(filepath)
        self.ext = os.path.splitext(self.filename)[1].lower()

        if self.is_code:
            self.language = CODE_EXTENSIONS.get(self.ext, self.ext.upper().lstrip('.'))
            try:
                with open(filepath, "r", encoding="utf-8", errors="replace") as f:
                    self.line_count = len(f.readlines())
            except Exception:
                self.line_count = 0
            self.subtitle = f"{self.language} • {self.line_count} lines"
        elif self.is_image:
            try:
                with Image.open(filepath) as img:
                    w, h = img.size
                    self.subtitle = f"{w} × {h} px"
            except Exception:
                self.subtitle = "Image"
        else:
            self.subtitle = "File"

    @property
    def formatted_size(self) -> str:
        s = self.size
        for unit in ['B', 'KB', 'MB', 'GB']:
            if s < 1024.0:
                return f"{s:.1f} {unit}"
            s /= 1024.0
        return f"{s:.1f} TB"

class ImageToPDFApp:
    def __init__(self):
        if USE_CUSTOMTKINTER:
            ctk.set_appearance_mode("System")
            ctk.set_default_color_theme("blue")
            self.root = ctk.CTk()
        else:
            self.root = tk.Tk()

        self.root.title("Image to PDF - Windows")
        self.root.geometry("860x580")
        self.root.minsize(760, 480)

        self.items: List[FileItem] = []
        self.selected_index: int = -1

        self.settings = ConversionSettings()

        self._build_ui()

    def _build_ui(self):
        # Main split container
        main_frame = ctk.CTkFrame(self.root) if USE_CUSTOMTKINTER else tk.Frame(self.root)
        main_frame.pack(fill=tk.BOTH, expand=True, padx=12, pady=12)

        # Left: File list and dropzone
        left_frame = ctk.CTkFrame(main_frame) if USE_CUSTOMTKINTER else tk.Frame(main_frame)
        left_frame.pack(side=tk.LEFT, fill=tk.BOTH, expand=True, padx=(0, 8))

        # Top toolbar
        toolbar = ctk.CTkFrame(left_frame, height=44) if USE_CUSTOMTKINTER else tk.Frame(left_frame)
        toolbar.pack(fill=tk.X, padx=8, pady=(8, 4))

        add_files_btn = ctk.CTkButton(toolbar, text="Add Files...", command=self.add_files, width=110) if USE_CUSTOMTKINTER else tk.Button(toolbar, text="Add Files...", command=self.add_files)
        add_files_btn.pack(side=tk.LEFT, padx=(0, 6))

        add_folder_btn = ctk.CTkButton(toolbar, text="Add Folder...", command=self.add_folder, width=110) if USE_CUSTOMTKINTER else tk.Button(toolbar, text="Add Folder...", command=self.add_folder)
        add_folder_btn.pack(side=tk.LEFT, padx=(0, 6))

        move_up_btn = ctk.CTkButton(toolbar, text="▲ Up", command=self.move_up, width=60) if USE_CUSTOMTKINTER else tk.Button(toolbar, text="▲ Up", command=self.move_up)
        move_up_btn.pack(side=tk.LEFT, padx=(0, 4))

        move_down_btn = ctk.CTkButton(toolbar, text="▼ Down", command=self.move_down, width=60) if USE_CUSTOMTKINTER else tk.Button(toolbar, text="▼ Down", command=self.move_down)
        move_down_btn.pack(side=tk.LEFT, padx=(0, 4))

        remove_btn = ctk.CTkButton(toolbar, text="Remove", command=self.remove_selected, width=70) if USE_CUSTOMTKINTER else tk.Button(toolbar, text="Remove", command=self.remove_selected)
        remove_btn.pack(side=tk.LEFT, padx=(0, 6))

        clear_btn = ctk.CTkButton(toolbar, text="Clear", command=self.clear_all, width=60, fg_color="#c93b3b" if USE_CUSTOMTKINTER else None) if USE_CUSTOMTKINTER else tk.Button(toolbar, text="Clear", command=self.clear_all)
        clear_btn.pack(side=tk.RIGHT)

        # Listbox for files
        self.listbox = tk.Listbox(left_frame, selectmode=tk.SINGLE, font=("Segoe UI", 10), bg="#ffffff" if not USE_CUSTOMTKINTER else "#2b2b2b", fg="#000000" if not USE_CUSTOMTKINTER else "#ffffff", selectbackground="#0078d4", selectforeground="#ffffff", borderwidth=0, highlightthickness=1)
        self.listbox.pack(fill=tk.BOTH, expand=True, padx=8, pady=4)
        self.listbox.bind('<<ListboxSelect>>', self._on_select)

        # Status Bar
        self.status_var = tk.StringVar(value="Drag and drop or add files (.py, .cpp, .png, .jpg, etc.)")
        status_bar = ctk.CTkLabel(left_frame, textvariable=self.status_var, anchor="w", font=("Segoe UI", 10)) if USE_CUSTOMTKINTER else tk.Label(left_frame, textvariable=self.status_var, anchor="w", font=("Segoe UI", 9))
        status_bar.pack(fill=tk.X, padx=8, pady=(4, 6))

        # Right: Settings sidebar
        sidebar = ctk.CTkFrame(main_frame, width=240) if USE_CUSTOMTKINTER else tk.Frame(main_frame, width=240)
        sidebar.pack(side=tk.RIGHT, fill=tk.Y, padx=(8, 0))

        title = ctk.CTkLabel(sidebar, text="PDF Settings", font=("Segoe UI", 14, "bold")) if USE_CUSTOMTKINTER else tk.Label(sidebar, text="PDF Settings", font=("Segoe UI", 12, "bold"))
        title.pack(anchor="w", padx=12, pady=(12, 10))

        # Mode
        mode_label = ctk.CTkLabel(sidebar, text="Output Mode:", font=("Segoe UI", 11, "bold")) if USE_CUSTOMTKINTER else tk.Label(sidebar, text="Output Mode:", font=("Segoe UI", 10, "bold"))
        mode_label.pack(anchor="w", padx=12, pady=(6, 2))

        self.mode_var = tk.StringVar(value="single")
        r1 = ctk.CTkRadioButton(sidebar, text="Single Combined PDF", variable=self.mode_var, value="single") if USE_CUSTOMTKINTER else tk.Radiobutton(sidebar, text="Single Combined PDF", variable=self.mode_var, value="single")
        r1.pack(anchor="w", padx=12, pady=2)
        r2 = ctk.CTkRadioButton(sidebar, text="Individual PDFs", variable=self.mode_var, value="individual") if USE_CUSTOMTKINTER else tk.Radiobutton(sidebar, text="Individual PDFs", variable=self.mode_var, value="individual")
        r2.pack(anchor="w", padx=12, pady=2)

        # Page Size
        size_label = ctk.CTkLabel(sidebar, text="Page Size:", font=("Segoe UI", 11, "bold")) if USE_CUSTOMTKINTER else tk.Label(sidebar, text="Page Size:", font=("Segoe UI", 10, "bold"))
        size_label.pack(anchor="w", padx=12, pady=(12, 2))

        self.page_size_var = tk.StringVar(value="fit")
        sizes = [("Fit to Image Size", "fit"), ("US Letter (8.5 × 11 in)", "letter"), ("A4 (210 × 297 mm)", "a4")]
        for text, val in sizes:
            rb = ctk.CTkRadioButton(sidebar, text=text, variable=self.page_size_var, value=val) if USE_CUSTOMTKINTER else tk.Radiobutton(sidebar, text=text, variable=self.page_size_var, value=val)
            rb.pack(anchor="w", padx=12, pady=2)

        # Orientation
        orient_label = ctk.CTkLabel(sidebar, text="Orientation:", font=("Segoe UI", 11, "bold")) if USE_CUSTOMTKINTER else tk.Label(sidebar, text="Orientation:", font=("Segoe UI", 10, "bold"))
        orient_label.pack(anchor="w", padx=12, pady=(12, 2))

        self.orient_var = tk.StringVar(value="auto")
        orients = [("Auto (Match Content)", "auto"), ("Portrait", "portrait"), ("Landscape", "landscape")]
        for text, val in orients:
            rb = ctk.CTkRadioButton(sidebar, text=text, variable=self.orient_var, value=val) if USE_CUSTOMTKINTER else tk.Radiobutton(sidebar, text=text, variable=self.orient_var, value=val)
            rb.pack(anchor="w", padx=12, pady=2)

        # Quality
        qual_label = ctk.CTkLabel(sidebar, text="Image Compression:", font=("Segoe UI", 11, "bold")) if USE_CUSTOMTKINTER else tk.Label(sidebar, text="Image Compression:", font=("Segoe UI", 10, "bold"))
        qual_label.pack(anchor="w", padx=12, pady=(12, 2))

        self.qual_var = tk.StringVar(value="max")
        quals = [("Maximum / Original", "max"), ("High (90%)", "high"), ("Medium (75%)", "medium"), ("Low / Compressed", "low")]
        for text, val in quals:
            rb = ctk.CTkRadioButton(sidebar, text=text, variable=self.qual_var, value=val) if USE_CUSTOMTKINTER else tk.Radiobutton(sidebar, text=text, variable=self.qual_var, value=val)
            rb.pack(anchor="w", padx=12, pady=2)

        # Bottom Save Button
        save_btn = ctk.CTkButton(sidebar, text="Save PDF...", command=self.save_pdf, height=38, font=("Segoe UI", 12, "bold")) if USE_CUSTOMTKINTER else tk.Button(sidebar, text="Save PDF...", command=self.save_pdf, font=("Segoe UI", 11, "bold"), bg="#0078d4", fg="#ffffff")
        save_btn.pack(side=tk.BOTTOM, fill=tk.X, padx=12, pady=16)

    def add_files(self):
        files = filedialog.askopenfilenames(
            title="Select Images or Code Files",
            filetypes=[
                ("All Supported Files", "*.png *.jpg *.jpeg *.webp *.tiff *.tif *.bmp *.gif *.py *.cpp *.c *.h *.hpp *.swift *.js *.ts *.rs *.go *.java *.kt *.sh *.json *.md *.txt"),
                ("Images", "*.png *.jpg *.jpeg *.webp *.tiff *.bmp *.gif"),
                ("Code Files", "*.py *.cpp *.c *.h *.hpp *.swift *.js *.ts *.rs *.go *.java *.kt *.sh *.json *.md *.txt"),
                ("All Files", "*.*")
            ]
        )
        if files:
            self._add_paths(list(files))

    def add_folder(self):
        folder = filedialog.askdirectory(title="Select Folder to Import")
        if folder:
            discovered = []
            for root, _, filenames in os.walk(folder):
                for f in sorted(filenames):
                    path = os.path.join(root, f)
                    if is_supported_file(path):
                        discovered.append(path)
            self._add_paths(discovered)

    def _add_paths(self, paths: List[str]):
        added = 0
        existing = {item.filepath for item in self.items}
        for p in paths:
            if p not in existing and is_supported_file(p):
                self.items.append(FileItem(p))
                added += 1
        self._refresh_listbox()
        if added > 0:
            self.status_var.set(f"Added {added} file(s) ({len(self.items)} total)")

    def _refresh_listbox(self):
        self.listbox.delete(0, tk.END)
        for idx, item in enumerate(self.items):
            badge = f"[{item.ext.upper().lstrip('.')}]"
            line = f" {idx+1}. {item.filename:<30} {badge:<8} {item.subtitle:<20} {item.formatted_size}"
            self.listbox.insert(tk.END, line)

    def _on_select(self, event):
        sel = self.listbox.curselection()
        if sel:
            self.selected_index = sel[0]

    def move_up(self):
        if self.selected_index > 0:
            i = self.selected_index
            self.items[i], self.items[i-1] = self.items[i-1], self.items[i]
            self.selected_index -= 1
            self._refresh_listbox()
            self.listbox.selection_set(self.selected_index)

    def move_down(self):
        if 0 <= self.selected_index < len(self.items) - 1:
            i = self.selected_index
            self.items[i], self.items[i+1] = self.items[i+1], self.items[i]
            self.selected_index += 1
            self._refresh_listbox()
            self.listbox.selection_set(self.selected_index)

    def remove_selected(self):
        if 0 <= self.selected_index < len(self.items):
            del self.items[self.selected_index]
            self.selected_index = -1
            self._refresh_listbox()
            self.status_var.set(f"{len(self.items)} file(s) ready")

    def clear_all(self):
        self.items.clear()
        self.selected_index = -1
        self._refresh_listbox()
        self.status_var.set("Ready")

    def save_pdf(self):
        if not self.items:
            messagebox.showwarning("No Files", "Please add at least one image or code file.")
            return

        settings = ConversionSettings(
            page_size=self.page_size_var.get(),
            orientation=self.orient_var.get(),
            quality=self.qual_var.get(),
            combine_single_pdf=(self.mode_var.get() == "single")
        )

        filepaths = [item.filepath for item in self.items]

        if settings.combine_single_pdf:
            default_name = os.path.splitext(self.items[0].filename)[0] + ".pdf"
            dest = filedialog.asksaveasfilename(
                title="Save Combined PDF As",
                defaultextension=".pdf",
                initialfile=default_name,
                filetypes=[("PDF Document", "*.pdf")]
            )
            if dest:
                try:
                    self.status_var.set("Generating PDF...")
                    self.root.update_idletasks()
                    PDFConverter.convert_files(filepaths, dest, settings)
                    self.status_var.set(f"Successfully saved to {os.path.basename(dest)}!")
                    messagebox.showinfo("Success", f"PDF created successfully!\n\nSaved to: {dest}")
                except Exception as e:
                    self.status_var.set("Error during conversion")
                    messagebox.showerror("Error", f"Failed to convert: {e}")
        else:
            dest_dir = filedialog.askdirectory(title="Select Folder to Export PDFs")
            if dest_dir:
                try:
                    self.status_var.set("Exporting PDFs...")
                    self.root.update_idletasks()
                    out_files = PDFConverter.convert_to_individual_pdfs(filepaths, dest_dir, settings)
                    self.status_var.set(f"Exported {len(out_files)} PDF(s)!")
                    messagebox.showinfo("Success", f"Successfully exported {len(out_files)} PDFs to:\n{dest_dir}")
                except Exception as e:
                    self.status_var.set("Error during export")
                    messagebox.showerror("Error", f"Failed to export: {e}")

    def run(self):
        self.root.mainloop()

def run_cli():
    parser = argparse.ArgumentParser(description="ImageToPDF - Convert images & code to PDF")
    parser.add_argument("inputs", nargs="*", help="Image or code files / folders to convert")
    parser.add_argument("-o", "--output", default="output.pdf", help="Output PDF file path")
    parser.add_argument("--page-size", choices=["fit", "letter", "a4"], default="fit", help="Page size")
    parser.add_argument("--orientation", choices=["auto", "portrait", "landscape"], default="auto")
    parser.add_argument("--quality", choices=["max", "high", "medium", "low"], default="max")
    args = parser.parse_args()

    if not args.inputs:
        app = ImageToPDFApp()
        app.run()
        return

    collected = []
    for inp in args.inputs:
        if os.path.isdir(inp):
            for root, _, filenames in os.walk(inp):
                for f in sorted(filenames):
                    p = os.path.join(root, f)
                    if is_supported_file(p):
                        collected.append(p)
        elif os.path.isfile(inp) and is_supported_file(inp):
            collected.append(inp)

    if not collected:
        print("Error: No valid images or code files found.")
        sys.exit(1)

    print(f"Converting {len(collected)} file(s) to {args.output}...")
    settings = ConversionSettings(
        page_size=args.page_size,
        orientation=args.orientation,
        quality=args.quality
    )
    PDFConverter.convert_files(collected, args.output, settings)
    print(f"✓ Successfully created {args.output}")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        run_cli()
    else:
        app = ImageToPDFApp()
        app.run()
