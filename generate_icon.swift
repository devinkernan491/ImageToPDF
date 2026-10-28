import Cocoa
import CoreGraphics

func createIcon(size: Int) -> NSImage {
    let s = CGFloat(size)
    let image = NSImage(size: NSSize(width: s, height: s))
    image.lockFocus()

    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    let rect = CGRect(x: 0, y: 0, width: s, height: s)
    
    // Draw rounded background squircle (macOS style icon)
    let cornerRadius = s * 0.22
    let bgRect = rect.insetBy(dx: s * 0.05, dy: s * 0.05)
    let clipPath = CGPath(roundedRect: bgRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

    ctx.saveGState()
    ctx.addPath(clipPath)
    ctx.clip()

    // Vibrant gradient background (PDF red-orange)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let colors = [
        CGColor(red: 0.95, green: 0.26, blue: 0.21, alpha: 1.0),
        CGColor(red: 0.85, green: 0.12, blue: 0.18, alpha: 1.0)
    ] as CFArray
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0]) {
        ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: s), end: CGPoint(x: 0, y: 0), options: [])
    }
    ctx.restoreGState()

    // Draw document sheet in center
    let docWidth = s * 0.48
    let docHeight = s * 0.62
    let docX = (s - docWidth) / 2.0
    let docY = (s - docHeight) / 2.0
    let docRect = CGRect(x: docX, y: docY, width: docWidth, height: docHeight)
    let docCorner = s * 0.05

    ctx.saveGState()
    // Subtle shadow
    ctx.setShadow(offset: CGSize(width: 0, height: -s * 0.03), blur: s * 0.06, color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.35))
    let docPath = CGPath(roundedRect: docRect, cornerWidth: docCorner, cornerHeight: docCorner, transform: nil)
    ctx.addPath(docPath)
    ctx.setFillColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.95))
    ctx.fillPath()
    ctx.restoreGState()

    // Draw folded corner or badge
    let badgeHeight = docHeight * 0.28
    let badgeRect = CGRect(x: docX + s * 0.04, y: docY + docHeight - badgeHeight - s * 0.04, width: docWidth - s * 0.08, height: badgeHeight)
    let badgePath = CGPath(roundedRect: badgeRect, cornerWidth: s * 0.02, cornerHeight: s * 0.02, transform: nil)
    ctx.addPath(badgePath)
    ctx.setFillColor(CGColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 0.2))
    ctx.fillPath()

    // Text: "PDF"
    let fontName = "HelveticaNeue-Bold" as CFString
    let fontSize = s * 0.14
    let font = CTFontCreateWithName(fontName, fontSize, nil)
    let text = "PDF" as CFString
    let attr: [CFString: Any] = [
        kCTFontAttributeName: font,
        kCTForegroundColorAttributeName: CGColor(red: 0.85, green: 0.15, blue: 0.15, alpha: 1.0)
    ]
    let attrString = CFAttributedStringCreate(kCFAllocatorDefault, text, attr as CFDictionary)!
    let line = CTLineCreateWithAttributedString(attrString)
    let textBounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)

    let textX = docRect.midX - (textBounds.width / 2.0)
    let textY = badgeRect.midY - (textBounds.height / 2.0) + s * 0.01
    ctx.textPosition = CGPoint(x: textX, y: textY)
    CTLineDraw(line, ctx)

    // Draw little image symbol in bottom half of doc
    let iconArea = CGRect(x: docX + s * 0.06, y: docY + s * 0.06, width: docWidth - s * 0.12, height: docHeight * 0.45)
    ctx.setStrokeColor(CGColor(red: 0.65, green: 0.65, blue: 0.70, alpha: 1.0))
    ctx.setLineWidth(max(1.0, s * 0.02))
    let iconPath = CGPath(roundedRect: iconArea, cornerWidth: s * 0.02, cornerHeight: s * 0.02, transform: nil)
    ctx.addPath(iconPath)
    ctx.strokePath()

    // Sun circle in image
    let sunRect = CGRect(x: iconArea.maxX - s * 0.10, y: iconArea.maxY - s * 0.10, width: s * 0.06, height: s * 0.06)
    ctx.setFillColor(CGColor(red: 0.95, green: 0.7, blue: 0.2, alpha: 1.0))
    ctx.fillEllipse(in: sunRect)

    // Mountain triangles in image
    ctx.setFillColor(CGColor(red: 0.4, green: 0.6, blue: 0.8, alpha: 1.0))
    let mountainPath = CGMutablePath()
    mountainPath.move(to: CGPoint(x: iconArea.minX, y: iconArea.minY))
    mountainPath.addLine(to: CGPoint(x: iconArea.minX + iconArea.width * 0.4, y: iconArea.minY + iconArea.height * 0.6))
    mountainPath.addLine(to: CGPoint(x: iconArea.minX + iconArea.width * 0.7, y: iconArea.minY + iconArea.height * 0.2))
    mountainPath.addLine(to: CGPoint(x: iconArea.minX + iconArea.width * 0.85, y: iconArea.minY + iconArea.height * 0.45))
    mountainPath.addLine(to: CGPoint(x: iconArea.maxX, y: iconArea.minY))
    mountainPath.closeSubpath()
    ctx.addPath(mountainPath)
    ctx.fillPath()

    image.unlockFocus()
    return image
}

let iconsetDir = "AppIcon.iconset"
try? FileManager.default.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

let sizes: [(String, Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for (filename, size) in sizes {
    let img = createIcon(size: size)
    if let tiff = img.tiffRepresentation,
       let rep = NSBitmapImageRep(data: tiff),
       let png = rep.representation(using: .png, properties: [:]) {
        let filePath = "\(iconsetDir)/\(filename)"
        try? png.write(to: URL(fileURLWithPath: filePath))
    }
}
print("Iconset created successfully.")
