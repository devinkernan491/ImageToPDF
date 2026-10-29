"""
PDF Converter Service for Windows / Cross-Platform ImageToPDF
Converts images and source code files to single or multi-page PDFs with syntax highlighting,
line numbers, and custom page formatting.
"""

import os
from typing import List, Dict, Any, Optional
try:
    from PIL import Image
    HAS_PIL = True
except ImportError:
    Image = None
    HAS_PIL = False

try:
    from reportlab.lib.pagesizes import letter, A4
    from reportlab.pdfgen import canvas
    from reportlab.lib import colors
    HAS_REPORTLAB = True
except ImportError:
    HAS_REPORTLAB = False
    letter = (612, 792)
    A4 = (595.27, 841.89)
    canvas = None
    colors = None

try:
    from pygments.lexers import get_lexer_for_filename, TextLexer
    from pygments.token import Token
    HAS_PYGMENTS = True
except ImportError:
    HAS_PYGMENTS = False

IMAGE_EXTENSIONS = {'.jpg', '.jpeg', '.png', '.webp', '.tiff', '.tif', '.bmp', '.gif'}
CODE_EXTENSIONS = {
    '.py': 'Python', '.cpp': 'C++', '.cc': 'C++', '.cxx': 'C++', '.hpp': 'C++', '.h': 'C/C++',
    '.c': 'C', '.swift': 'Swift', '.rs': 'Rust', '.go': 'Go', '.java': 'Java',
    '.kt': 'Kotlin', '.kts': 'Kotlin', '.js': 'JavaScript', '.jsx': 'JavaScript',
    '.ts': 'TypeScript', '.tsx': 'TypeScript', '.html': 'HTML', '.htm': 'HTML',
    '.css': 'CSS', '.scss': 'SCSS', '.json': 'JSON', '.xml': 'XML',
    '.yaml': 'YAML', '.yml': 'YAML', '.toml': 'TOML', '.sh': 'Shell',
    '.bash': 'Bash', '.zsh': 'Zsh', '.sql': 'SQL', '.r': 'R',
    '.rb': 'Ruby', '.php': 'PHP', '.dart': 'Dart', '.cs': 'C#',
    '.md': 'Markdown', '.txt': 'Text'
}

def is_code_file(filepath: str) -> bool:
    ext = os.path.splitext(filepath)[1].lower()
    return ext in CODE_EXTENSIONS

def is_image_file(filepath: str) -> bool:
    ext = os.path.splitext(filepath)[1].lower()
    return ext in IMAGE_EXTENSIONS

def is_supported_file(filepath: str) -> bool:
    return is_image_file(filepath) or is_code_file(filepath)

class ConversionSettings:
    def __init__(
        self,
        page_size: str = "fit", # "fit", "letter", "a4"
        orientation: str = "auto", # "auto", "portrait", "landscape"
        margin: str = "none", # "none", "small", "normal"
        quality: str = "max", # "max", "high", "medium", "low"
        combine_single_pdf: bool = True
    ):
        self.page_size = page_size
        self.orientation = orientation
        self.margin = margin
        self.quality = quality
        self.combine_single_pdf = combine_single_pdf

    @property
    def margin_points(self) -> float:
        if self.margin == "small":
            return 18.0
        elif self.margin == "normal":
            return 36.0
        return 0.0

    @property
    def jpeg_quality(self) -> Optional[int]:
        if self.quality == "high":
            return 90
        elif self.quality == "medium":
            return 75
        elif self.quality == "low":
            return 50
        return None

class PDFConverter:
    @staticmethod
    def convert_files(filepaths: List[str], output_path: str, settings: ConversionSettings) -> None:
        """Converts multiple files to a single combined PDF."""
        if not HAS_REPORTLAB or canvas is None:
            raise RuntimeError("ReportLab is required. Please install it using: pip install reportlab Pillow")
        c = canvas.Canvas(output_path)
        for filepath in filepaths:
            if not os.path.exists(filepath):
                continue
            if is_code_file(filepath):
                PDFConverter._render_code(c, filepath, settings)
            elif is_image_file(filepath):
                PDFConverter._render_image(c, filepath, settings)
        c.save()

    @staticmethod
    def convert_to_individual_pdfs(filepaths: List[str], output_dir: str, settings: ConversionSettings) -> List[str]:
        """Converts files to individual PDFs in the destination directory."""
        output_files = []
        os.makedirs(output_dir, exist_ok=True)
        for filepath in filepaths:
            if not os.path.exists(filepath):
                continue
            base = os.path.splitext(os.path.basename(filepath))[0]
            out_pdf = os.path.join(output_dir, f"{base}.pdf")
            c = canvas.Canvas(out_pdf)
            if is_code_file(filepath):
                PDFConverter._render_code(c, filepath, settings)
            elif is_image_file(filepath):
                PDFConverter._render_image(c, filepath, settings)
            c.save()
            output_files.append(out_pdf)
        return output_files

    @staticmethod
    def _render_image(c: canvas.Canvas, filepath: str, settings: ConversionSettings) -> None:
        try:
            with Image.open(filepath) as img:
                img_width, img_height = img.size

                # Determine target page size
                if settings.page_size == "letter":
                    base_w, base_h = letter
                elif settings.page_size == "a4":
                    base_w, base_h = A4
                else:
                    # Fit to image size (72 DPI points)
                    base_w, base_h = float(img_width), float(img_height)

                # Orientation
                is_landscape = img_width > img_height
                if settings.orientation == "auto":
                    pw = max(base_w, base_h) if is_landscape else min(base_w, base_h)
                    ph = min(base_w, base_h) if is_landscape else max(base_w, base_h)
                elif settings.orientation == "landscape":
                    pw = max(base_w, base_h)
                    ph = min(base_w, base_h)
                else: # portrait
                    pw = min(base_w, base_h)
                    ph = max(base_w, base_h)

                c.setPageSize((pw, ph))

                # Background white
                c.setFillColor(colors.white)
                c.rect(0, 0, pw, ph, fill=1, stroke=0)

                # Margins
                margin = 0.0 if settings.page_size == "fit" else settings.margin_points
                draw_w = max(10, pw - (2 * margin))
                draw_h = max(10, ph - (2 * margin))

                scale = min(draw_w / img_width, draw_h / img_height)
                final_w = img_width * scale
                final_h = img_height * scale
                x = margin + (draw_w - final_w) / 2.0
                y = margin + (draw_h - final_h) / 2.0

                c.drawImage(filepath, x, y, width=final_w, height=final_h, preserveAspectRatio=True)
                c.showPage()
        except Exception as e:
            print(f"Error rendering image {filepath}: {e}")

    @staticmethod
    def _render_code(c: canvas.Canvas, filepath: str, settings: ConversionSettings) -> None:
        try:
            with open(filepath, "r", encoding="utf-8", errors="replace") as f:
                content = f.read()
        except Exception:
            return

        lines = content.splitlines()
        filename = os.path.basename(filepath)
        ext = os.path.splitext(filename)[1].lower()
        language = CODE_EXTENSIONS.get(ext, ext.upper().lstrip('.'))

        # Page dimension (standard Letter or A4)
        if settings.page_size == "a4":
            base_w, base_h = A4
        else:
            base_w, base_h = letter

        if settings.orientation == "landscape":
            pw, ph = max(base_w, base_h), min(base_w, base_h)
        else:
            pw, ph = min(base_w, base_h), max(base_w, base_h)

        left_margin = 36.0
        right_margin = 36.0
        bottom_margin = 40.0
        header_y = ph - 32.0
        divider_y = ph - 40.0
        content_start_y = ph - 56.0

        font_name = "Courier"
        font_size = 9.0
        line_height = 13.5

        # Gutter width
        total_raw_lines = len(lines)
        digits = max(2, len(str(total_raw_lines)))
        gutter_width = float(digits * 7 + 14)
        code_start_x = left_margin + gutter_width + 10
        code_available_width = max(50.0, pw - right_margin - code_start_x)
        char_width = 5.4 # Approximate monospace character width for Courier 9pt
        max_chars_per_line = max(20, int(code_available_width / char_width))

        # Tokenize lines for coloring
        tokens_map = PDFConverter._tokenize_code(filepath, content)

        # Pre-wrap lines
        visual_lines = []
        for line_idx, raw_line in enumerate(lines):
            line_num = line_idx + 1
            expanded = raw_line.replace("\t", "    ")
            line_tokens = tokens_map.get(line_idx, [(colors.black, expanded)])

            if len(expanded) <= max_chars_per_line or not expanded:
                visual_lines.append((line_num, line_tokens))
            else:
                # Wrap long line
                start = 0
                first = True
                while start < len(expanded):
                    sub = expanded[start:start + max_chars_per_line]
                    if first:
                        visual_lines.append((line_num, [(colors.black, sub)]))
                        first = False
                    else:
                        visual_lines.append((None, [(colors.HexColor("#777777"), "  ↳ "), (colors.black, sub)]))
                    start += max_chars_per_line

        lines_per_page = max(1, int((content_start_y - bottom_margin) / line_height))
        total_pages = max(1, (len(visual_lines) + lines_per_page - 1) // lines_per_page)

        current_line_idx = 0
        page_num = 1

        while current_line_idx < len(visual_lines) or (not visual_lines and page_num == 1):
            c.setPageSize((pw, ph))

            # White background
            c.setFillColor(colors.white)
            c.rect(0, 0, pw, ph, fill=1, stroke=0)

            # Header
            c.setFillColor(colors.HexColor("#222222"))
            c.setFont("Helvetica-Bold", 10)
            c.drawString(left_margin, header_y, f"{filename}  [{language}]")

            c.setFillColor(colors.HexColor("#666666"))
            c.setFont("Helvetica", 9)
            page_text = f"Page {page_num} of {total_pages}"
            c.drawRightString(pw - right_margin, header_y, page_text)

            # Header divider
            c.setStrokeColor(colors.HexColor("#dddddd"))
            c.setLineWidth(0.8)
            c.line(left_margin, divider_y, pw - right_margin, divider_y)

            # Gutter background
            c.setFillColor(colors.HexColor("#f8f9fa"))
            c.rect(left_margin, bottom_margin, gutter_width, divider_y - bottom_margin, fill=1, stroke=0)

            # Gutter divider
            c.setStrokeColor(colors.HexColor("#e5e7eb"))
            c.line(left_margin + gutter_width, divider_y, left_margin + gutter_width, bottom_margin)

            # Draw lines
            curr_y = content_start_y
            lines_rendered = 0

            while current_line_idx < len(visual_lines) and lines_rendered < lines_per_page:
                line_no, token_list = visual_lines[current_line_idx]

                # Draw line number
                if line_no is not None:
                    c.setFillColor(colors.HexColor("#888888"))
                    c.setFont("Courier", 8.5)
                    c.drawRightString(left_margin + gutter_width - 6, curr_y, str(line_no))

                # Draw text chunks
                curr_x = code_start_x
                c.setFont(font_name, font_size)
                for color_val, text_chunk in token_list:
                    c.setFillColor(color_val)
                    c.drawString(curr_x, curr_y, text_chunk)
                    curr_x += len(text_chunk) * char_width

                curr_y -= line_height
                lines_rendered += 1
                current_line_idx += 1

            c.showPage()
            page_num += 1
            if not visual_lines:
                break

    @staticmethod
    def _tokenize_code(filepath: str, content: str) -> Dict[int, List[Any]]:
        """Extracts syntax highlighting tokens per line using Pygments if available."""
        lines_dict = {}
        if not HAS_PYGMENTS:
            return lines_dict

        try:
            lexer = get_lexer_for_filename(filepath, content)
        except Exception:
            lexer = TextLexer()

        color_map = {
            Token.Keyword: colors.HexColor("#8a2be2"),
            Token.Name.Class: colors.HexColor("#0066cc"),
            Token.Name.Function: colors.HexColor("#0066cc"),
            Token.String: colors.HexColor("#b22222"),
            Token.Comment: colors.HexColor("#2e8b57"),
            Token.Number: colors.HexColor("#ff8c00"),
            Token.Operator: colors.HexColor("#333333"),
        }

        current_line_tokens = []
        line_index = 0

        for ttype, value in lexer.get_tokens(content):
            c_color = colors.HexColor("#222222")
            for parent_token, col in color_map.items():
                if ttype in parent_token:
                    c_color = col
                    break

            parts = value.split("\n")
            for idx, part in enumerate(parts):
                if part:
                    current_line_tokens.append((c_color, part))
                if idx < len(parts) - 1:
                    lines_dict[line_index] = current_line_tokens
                    current_line_tokens = []
                    line_index += 1

        if current_line_tokens:
            lines_dict[line_index] = current_line_tokens

        return lines_dict
