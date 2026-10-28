import Foundation
import AppKit

public struct ImageItem: Identifiable, Hashable {
    public let id: UUID
    public let url: URL
    public let fileName: String
    public let fileSize: Int64
    public var dimensions: CGSize
    public var thumbnail: NSImage?
    public let isCodeFile: Bool
    public let codeLanguage: String
    public let lineCount: Int

    public static let codeExtensions: [String: String] = [
        "py": "Python",
        "cpp": "C++", "cc": "C++", "cxx": "C++", "hpp": "C++", "h": "C/C++",
        "c": "C",
        "swift": "Swift",
        "rs": "Rust",
        "go": "Go",
        "java": "Java",
        "kt": "Kotlin", "kts": "Kotlin",
        "js": "JavaScript", "jsx": "JavaScript",
        "ts": "TypeScript", "tsx": "TypeScript",
        "html": "HTML", "htm": "HTML",
        "css": "CSS", "scss": "SCSS",
        "json": "JSON",
        "xml": "XML",
        "yaml": "YAML", "yml": "YAML",
        "toml": "TOML",
        "sh": "Shell", "bash": "Bash", "zsh": "Zsh",
        "sql": "SQL",
        "r": "R", "rb": "Ruby", "php": "PHP", "dart": "Dart",
        "m": "Objective-C", "mm": "Objective-C++",
        "cs": "C#", "lua": "Lua",
        "md": "Markdown", "txt": "Text"
    ]

    public static let imageExtensions: Set<String> = [
        "jpg", "jpeg", "png", "heic", "heif", "webp", "tiff", "tif", "bmp", "gif"
    ]

    public init(url: URL) {
        self.id = UUID()
        self.url = url
        self.fileName = url.lastPathComponent
        
        let resources = try? url.resourceValues(forKeys: [.fileSizeKey])
        self.fileSize = Int64(resources?.fileSize ?? 0)
        
        let ext = url.pathExtension.lowercased()
        if let lang = Self.codeExtensions[ext] {
            self.isCodeFile = true
            self.codeLanguage = lang
            
            // Read lines
            var lines = 0
            if let content = try? String(contentsOf: url, encoding: .utf8) {
                lines = content.components(separatedBy: .newlines).count
            } else if let content = try? String(contentsOf: url, encoding: .isoLatin1) {
                lines = content.components(separatedBy: .newlines).count
            }
            self.lineCount = max(lines, 1)
            self.dimensions = CGSize(width: 612, height: 792) // Standard Letter aspect
            self.thumbnail = Self.generateCodeThumbnail(language: lang, ext: ext)
        } else {
            self.isCodeFile = false
            self.codeLanguage = ""
            self.lineCount = 0
            
            // Read dimensions using CGImageSource
            var imageSize: CGSize = .zero
            if let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
               let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any] {
                let width = properties[kCGImagePropertyPixelWidth] as? CGFloat ?? 0
                let height = properties[kCGImagePropertyPixelHeight] as? CGFloat ?? 0
                let orientation = properties[kCGImagePropertyOrientation] as? UInt32 ?? 1
                if [5, 6, 7, 8].contains(orientation) {
                    imageSize = CGSize(width: height, height: width)
                } else {
                    imageSize = CGSize(width: width, height: height)
                }
            }
            self.dimensions = imageSize
            
            // Generate quick thumbnail using CGImageSource
            if let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) {
                let options: [CFString: Any] = [
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceShouldCacheImmediately: true,
                    kCGImageSourceCreateThumbnailWithTransform: true,
                    kCGImageSourceThumbnailMaxPixelSize: 180
                ]
                if let cgThumb = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) {
                    self.thumbnail = NSImage(cgImage: cgThumb, size: NSSize(width: cgThumb.width, height: cgThumb.height))
                } else {
                    self.thumbnail = nil
                }
            } else {
                self.thumbnail = nil
            }
        }
    }

    public var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }

    public var dimensionsString: String {
        if isCodeFile {
            return "\(codeLanguage) • \(lineCount) \(lineCount == 1 ? "line" : "lines")"
        }
        if dimensions.width > 0 && dimensions.height > 0 {
            return "\(Int(dimensions.width)) × \(Int(dimensions.height)) px"
        }
        return "Unknown size"
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: ImageItem, rhs: ImageItem) -> Bool {
        lhs.id == rhs.id
    }

    private static func generateCodeThumbnail(language: String, ext: String) -> NSImage {
        let size = NSSize(width: 96, height: 96)
        let image = NSImage(size: size)
        image.lockFocus()

        guard let ctx = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return image
        }

        // Draw document background card
        let docRect = CGRect(x: 16, y: 10, width: 64, height: 76)
        let path = CGPath(roundedRect: docRect, cornerWidth: 6, cornerHeight: 6, transform: nil)
        ctx.addPath(path)
        ctx.setFillColor(CGColor(red: 0.94, green: 0.95, blue: 0.97, alpha: 1.0))
        ctx.fillPath()

        // Border
        ctx.addPath(path)
        ctx.setStrokeColor(CGColor(red: 0.80, green: 0.82, blue: 0.86, alpha: 1.0))
        ctx.setLineWidth(1.5)
        ctx.strokePath()

        // Top banner for language tag
        let bannerRect = CGRect(x: 16, y: 58, width: 64, height: 28)
        let bannerClip = CGPath(roundedRect: bannerRect, cornerWidth: 6, cornerHeight: 6, transform: nil)
        ctx.saveGState()
        ctx.addPath(bannerClip)
        
        let (r, g, b): (CGFloat, CGFloat, CGFloat) = {
            switch ext.lowercased() {
            case "py": return (0.22, 0.44, 0.68)      // Python blue
            case "cpp", "cc", "cxx", "hpp", "h": return (0.0, 0.35, 0.65) // C++ blue
            case "c": return (0.33, 0.44, 0.55)       // C slate
            case "swift": return (0.98, 0.34, 0.16)   // Swift orange
            case "js", "jsx": return (0.92, 0.76, 0.18) // JS yellow
            case "ts", "tsx": return (0.19, 0.47, 0.77) // TS blue
            case "rs": return (0.72, 0.28, 0.12)      // Rust red/orange
            case "go": return (0.0, 0.66, 0.85)       // Go cyan
            case "sh", "bash", "zsh": return (0.25, 0.65, 0.35) // Shell green
            case "json", "yaml", "yml": return (0.55, 0.35, 0.65) // Purple
            default: return (0.45, 0.50, 0.58)        // Neutral gray
            }
        }()
        
        ctx.setFillColor(CGColor(red: r, green: g, blue: b, alpha: 1.0))
        ctx.fill(bannerRect)
        ctx.restoreGState()

        // Text inside banner: extension badge (e.g. PY, C++, SWIFT)
        let label = ext.uppercased()
        let font = CTFontCreateWithName("HelveticaNeue-Bold" as CFString, 11, nil)
        let textColor = (ext == "js" || ext == "jsx") ? CGColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0) : CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        let attr: [CFString: Any] = [
            kCTFontAttributeName: font,
            kCTForegroundColorAttributeName: textColor
        ]
        let attrString = CFAttributedStringCreate(kCFAllocatorDefault, label as CFString, attr as CFDictionary)!
        let line = CTLineCreateWithAttributedString(attrString)
        let bounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)
        let tx = bannerRect.midX - (bounds.width / 2.0)
        let ty = bannerRect.midY - (bounds.height / 2.0) + 1
        ctx.textPosition = CGPoint(x: tx, y: ty)
        CTLineDraw(line, ctx)

        // Draw 3 code lines placeholder
        ctx.setFillColor(CGColor(red: 0.68, green: 0.70, blue: 0.75, alpha: 1.0))
        let lineWidths: [CGFloat] = [44, 36, 28]
        let lineY: [CGFloat] = [44, 32, 20]
        for i in 0..<3 {
            let lRect = CGRect(x: 24, y: lineY[i], width: lineWidths[i], height: 4)
            let lPath = CGPath(roundedRect: lRect, cornerWidth: 2, cornerHeight: 2, transform: nil)
            ctx.addPath(lPath)
            ctx.fillPath()
        }

        image.unlockFocus()
        return image
    }
}

public typealias FileItem = ImageItem
