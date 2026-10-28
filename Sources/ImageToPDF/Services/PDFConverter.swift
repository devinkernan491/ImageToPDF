import Foundation
import AppKit
import PDFKit
import CoreGraphics
import ImageIO
import CoreText

public enum PageSizeOption: String, CaseIterable, Identifiable {
    case fitToImage = "Fit to Image Size"
    case usLetter = "US Letter (8.5 × 11 in)"
    case a4 = "A4 (210 × 297 mm)"

    public var id: String { rawValue }

    public func targetSize(orientation: PageOrientation, imageSize: CGSize) -> CGSize {
        switch self {
        case .fitToImage:
            let w = max(imageSize.width, 100)
            let h = max(imageSize.height, 100)
            return CGSize(width: w, height: h)
        case .usLetter:
            let base = CGSize(width: 612, height: 792)
            return orientation.adjustedSize(base: base, imageSize: imageSize)
        case .a4:
            let base = CGSize(width: 595.28, height: 841.89)
            return orientation.adjustedSize(base: base, imageSize: imageSize)
        }
    }
}

public enum PageOrientation: String, CaseIterable, Identifiable {
    case auto = "Auto (Match Content)"
    case portrait = "Portrait"
    case landscape = "Landscape"

    public var id: String { rawValue }

    public func adjustedSize(base: CGSize, imageSize: CGSize) -> CGSize {
        let isLandscapeImage = imageSize.width > imageSize.height
        let shortSide = min(base.width, base.height)
        let longSide = max(base.width, base.height)

        switch self {
        case .auto:
            return isLandscapeImage ? CGSize(width: longSide, height: shortSide) : CGSize(width: shortSide, height: longSide)
        case .portrait:
            return CGSize(width: shortSide, height: longSide)
        case .landscape:
            return CGSize(width: longSide, height: shortSide)
        }
    }
}

public enum PageMargin: String, CaseIterable, Identifiable {
    case none = "None (0 pt)"
    case small = "Small (18 pt)"
    case normal = "Normal (36 pt)"

    public var id: String { rawValue }

    public var points: CGFloat {
        switch self {
        case .none: return 0
        case .small: return 18
        case .normal: return 36
        }
    }
}

public enum ImageQuality: String, CaseIterable, Identifiable {
    case maximum = "Maximum / Original"
    case high = "High (90%)"
    case medium = "Medium (75%)"
    case low = "Low / Compressed (50%)"

    public var id: String { rawValue }

    public var compressionFactor: CGFloat? {
        switch self {
        case .maximum: return nil
        case .high: return 0.9
        case .medium: return 0.75
        case .low: return 0.5
        }
    }
}

public struct ConversionSettings {
    public var pageSize: PageSizeOption = .fitToImage
    public var orientation: PageOrientation = .auto
    public var margin: PageMargin = .none
    public var quality: ImageQuality = .maximum
    public var combineIntoSinglePDF: Bool = true

    public init() {}
}

public final class PDFConverter {
    public static let shared = PDFConverter()

    private init() {}

    public func createPDFData(from items: [ImageItem], settings: ConversionSettings) throws -> Data {
        let pdfData = NSMutableData()
        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData) else {
            throw NSError(domain: "PDFConverter", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create PDF consumer"])
        }

        var mediaBox = CGRect(x: 0, y: 0, width: 612, height: 792)
        guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            throw NSError(domain: "PDFConverter", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create PDF context"])
        }

        for item in items {
            if item.isCodeFile {
                renderCodeItem(item: item, context: context, settings: settings)
            } else {
                renderImageItem(item: item, context: context, settings: settings)
            }
        }

        context.closePDF()
        return pdfData as Data
    }

    public func convertToSinglePDF(items: [ImageItem], settings: ConversionSettings, destinationURL: URL) throws {
        let data = try createPDFData(from: items, settings: settings)
        try data.write(to: destinationURL, options: .atomic)
    }

    public func convertToIndividualPDFs(items: [ImageItem], settings: ConversionSettings, destinationDirectory: URL) throws -> [URL] {
        var createdURLs: [URL] = []
        for item in items {
            let data = try createPDFData(from: [item], settings: settings)
            let baseName = item.url.deletingPathExtension().lastPathComponent
            let outputURL = destinationDirectory.appendingPathComponent("\(baseName).pdf")
            try data.write(to: outputURL, options: .atomic)
            createdURLs.append(outputURL)
        }
        return createdURLs
    }

    // MARK: - Image Rendering

    private func renderImageItem(item: ImageItem, context: CGContext, settings: ConversionSettings) {
        guard let cgImage = loadCGImage(from: item.url, quality: settings.quality) else {
            return
        }

        let imgPixelWidth = CGFloat(cgImage.width)
        let imgPixelHeight = CGFloat(cgImage.height)
        let imageSize = CGSize(width: imgPixelWidth, height: imgPixelHeight)

        let pageSize = settings.pageSize.targetSize(orientation: settings.orientation, imageSize: imageSize)
        var pageRect = CGRect(origin: .zero, size: pageSize)

        context.beginPage(mediaBox: &pageRect)

        // Fill page with white background
        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        context.fill(pageRect)

        let margin = settings.pageSize == .fitToImage ? 0 : settings.margin.points
        let drawArea = pageRect.insetBy(dx: margin, dy: margin)

        if drawArea.width > 0 && drawArea.height > 0 {
            let scale = min(drawArea.width / imgPixelWidth, drawArea.height / imgPixelHeight)
            let drawnWidth = imgPixelWidth * scale
            let drawnHeight = imgPixelHeight * scale
            let originX = drawArea.midX - (drawnWidth / 2.0)
            let originY = drawArea.midY - (drawnHeight / 2.0)
            let destRect = CGRect(x: originX, y: originY, width: drawnWidth, height: drawnHeight)

            context.draw(cgImage, in: destRect)
        }

        context.endPage()
    }

    private func loadCGImage(from url: URL, quality: ImageQuality) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return nil
        }

        let options: [CFString: Any] = [
            kCGImageSourceShouldCache: true,
            kCGImageSourceShouldAllowFloat: true
        ]
        guard var cgImage = CGImageSourceCreateImageAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }

        // Apply compression if requested
        if let compression = quality.compressionFactor, compression < 1.0 {
            let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
            if let tiffData = nsImage.tiffRepresentation,
               let rep = NSBitmapImageRep(data: tiffData),
               let jpegData = rep.representation(using: .jpeg, properties: [.compressionFactor: compression]),
               let compressedSource = CGImageSourceCreateWithData(jpegData as CFData, nil),
               let compressedCG = CGImageSourceCreateImageAtIndex(compressedSource, 0, nil) {
                cgImage = compressedCG
            }
        }

        return cgImage
    }

    // MARK: - Code / Program File Rendering

    private func renderCodeItem(item: ImageItem, context: CGContext, settings: ConversionSettings) {
        guard let content = (try? String(contentsOf: item.url, encoding: .utf8)) ??
                            (try? String(contentsOf: item.url, encoding: .isoLatin1)) else {
            return
        }

        let ext = item.url.pathExtension.lowercased()
        let language = CodeLanguage.forExtension(ext)
        let rawLines = content.components(separatedBy: .newlines)

        let targetPageSize: CGSize
        if settings.pageSize == .fitToImage {
            // For code, default to standard US Letter or A4
            let base = CGSize(width: 612, height: 792)
            targetPageSize = settings.orientation.adjustedSize(base: base, imageSize: CGSize(width: 612, height: 792))
        } else {
            targetPageSize = settings.pageSize.targetSize(orientation: settings.orientation, imageSize: CGSize(width: 612, height: 792))
        }

        let pageWidth = targetPageSize.width
        let pageHeight = targetPageSize.height

        let leftMargin: CGFloat = 36
        let rightMargin: CGFloat = 36
        let bottomMargin: CGFloat = 40

        let headerY = pageHeight - 32
        let dividerY = pageHeight - 40
        let contentStartY = pageHeight - 56

        let codeFont = NSFont(name: "Menlo-Regular", size: 9.0) ?? NSFont.monospacedSystemFont(ofSize: 9.0, weight: .regular)
        let headerFont = CTFontCreateWithName("HelveticaNeue-Medium" as CFString, 10, nil)
        let headerSubFont = CTFontCreateWithName("HelveticaNeue" as CFString, 9, nil)
        let gutterFont = CTFontCreateWithName("Menlo-Regular" as CFString, 8.5, nil)

        let lineHeight: CGFloat = 13.5

        // Calculate gutter width based on total lines
        let totalLines = rawLines.count
        let digits = max(2, String(totalLines).count)
        let gutterWidth: CGFloat = CGFloat(digits * 7 + 14)
        let codeStartX = leftMargin + gutterWidth + 10
        let codeAvailableWidth = max(50, pageWidth - rightMargin - codeStartX)

        struct VisualLine {
            let lineNumber: Int?
            let attributedString: NSAttributedString
        }

        var visualLines: [VisualLine] = []
        for (idx, rawLine) in rawLines.enumerated() {
            let lineNum = idx + 1
            // Expand tabs to 4 spaces for consistent rendering
            let expandedLine = rawLine.replacingOccurrences(of: "\t", with: "    ")
            let highlighted = CodeHighlighter.shared.highlight(code: expandedLine, language: language, font: codeFont)

            let ctLine = CTLineCreateWithAttributedString(highlighted)
            let lineWidth = CGFloat(CTLineGetTypographicBounds(ctLine, nil, nil, nil))

            if lineWidth <= codeAvailableWidth || expandedLine.isEmpty {
                visualLines.append(VisualLine(lineNumber: lineNum, attributedString: highlighted))
            } else {
                let typesetter = CTTypesetterCreateWithAttributedString(highlighted)
                var startIndex = 0
                var isFirst = true
                let fullLen = highlighted.length

                while startIndex < fullLen {
                    let count = CTTypesetterSuggestLineBreak(typesetter, startIndex, Double(codeAvailableWidth))
                    if count <= 0 { break }
                    let range = NSRange(location: startIndex, length: count)
                    let subStr = highlighted.attributedSubstring(from: range)

                    if isFirst {
                        visualLines.append(VisualLine(lineNumber: lineNum, attributedString: subStr))
                        isFirst = false
                    } else {
                        let contAttr = NSMutableAttributedString(
                            string: "  ↳ ",
                            attributes: [
                                .font: codeFont,
                                .foregroundColor: NSColor.secondaryLabelColor
                            ]
                        )
                        contAttr.append(subStr)
                        visualLines.append(VisualLine(lineNumber: nil, attributedString: contAttr))
                    }
                    startIndex += count
                }
            }
        }

        let linesPerPage = max(1, Int((contentStartY - bottomMargin) / lineHeight))
        let totalPages = max(1, Int(ceil(Double(visualLines.count) / Double(linesPerPage))))

        var currentLineIndex = 0
        var pageNum = 1

        while currentLineIndex < visualLines.count || (visualLines.isEmpty && pageNum == 1) {
            var pageRect = CGRect(origin: .zero, size: targetPageSize)
            context.beginPage(mediaBox: &pageRect)

            // Fill page background
            context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
            context.fill(pageRect)

            // Draw Header
            let headerTitle = "\(item.fileName)  [\(language.name)]"
            let titleAttr: [CFString: Any] = [
                kCTFontAttributeName: headerFont,
                kCTForegroundColorAttributeName: CGColor(red: 0.15, green: 0.18, blue: 0.22, alpha: 1.0)
            ]
            let titleString = CFAttributedStringCreate(kCFAllocatorDefault, headerTitle as CFString, titleAttr as CFDictionary)!
            let titleLine = CTLineCreateWithAttributedString(titleString)
            context.textMatrix = .identity
            context.textPosition = CGPoint(x: leftMargin, y: headerY)
            CTLineDraw(titleLine, context)

            // Right header: Page X of Y
            let pageStr = "Page \(pageNum) of \(totalPages)"
            let pageAttr: [CFString: Any] = [
                kCTFontAttributeName: headerSubFont,
                kCTForegroundColorAttributeName: CGColor(red: 0.5, green: 0.52, blue: 0.56, alpha: 1.0)
            ]
            let pageString = CFAttributedStringCreate(kCFAllocatorDefault, pageStr as CFString, pageAttr as CFDictionary)!
            let pageLine = CTLineCreateWithAttributedString(pageString)
            let pageBounds = CTLineGetBoundsWithOptions(pageLine, .useOpticalBounds)
            context.textPosition = CGPoint(x: pageWidth - rightMargin - pageBounds.width, y: headerY)
            CTLineDraw(pageLine, context)

            // Header divider line
            context.setStrokeColor(CGColor(red: 0.85, green: 0.86, blue: 0.90, alpha: 1.0))
            context.setLineWidth(0.8)
            context.beginPath()
            context.move(to: CGPoint(x: leftMargin, y: dividerY))
            context.addLine(to: CGPoint(x: pageWidth - rightMargin, y: dividerY))
            context.strokePath()

            // Gutter background
            let gutterRect = CGRect(x: leftMargin, y: bottomMargin, width: gutterWidth, height: dividerY - bottomMargin)
            context.setFillColor(CGColor(red: 0.97, green: 0.98, blue: 0.99, alpha: 1.0))
            context.fill(gutterRect)

            // Gutter separator line
            context.setStrokeColor(CGColor(red: 0.88, green: 0.90, blue: 0.93, alpha: 1.0))
            context.setLineWidth(0.8)
            context.beginPath()
            context.move(to: CGPoint(x: leftMargin + gutterWidth, y: dividerY))
            context.addLine(to: CGPoint(x: leftMargin + gutterWidth, y: bottomMargin))
            context.strokePath()

            // Draw code lines for this page
            var currentY = contentStartY
            var linesRenderedThisPage = 0

            while currentLineIndex < visualLines.count && linesRenderedThisPage < linesPerPage {
                let vLine = visualLines[currentLineIndex]

                // Line number in gutter
                if let num = vLine.lineNumber {
                    let numStr = "\(num)"
                    let numAttr: [CFString: Any] = [
                        kCTFontAttributeName: gutterFont,
                        kCTForegroundColorAttributeName: CGColor(red: 0.58, green: 0.60, blue: 0.65, alpha: 1.0)
                    ]
                    let numString = CFAttributedStringCreate(kCFAllocatorDefault, numStr as CFString, numAttr as CFDictionary)!
                    let numLine = CTLineCreateWithAttributedString(numString)
                    let numBounds = CTLineGetBoundsWithOptions(numLine, .useOpticalBounds)
                    let numX = leftMargin + gutterWidth - numBounds.width - 6
                    context.textPosition = CGPoint(x: numX, y: currentY)
                    CTLineDraw(numLine, context)
                }

                // Code text
                let ctLine = CTLineCreateWithAttributedString(vLine.attributedString)
                context.textPosition = CGPoint(x: codeStartX, y: currentY)
                CTLineDraw(ctLine, context)

                currentY -= lineHeight
                linesRenderedThisPage += 1
                currentLineIndex += 1
            }

            context.endPage()
            pageNum += 1

            if visualLines.isEmpty { break }
        }
    }
}
