import SwiftUI
import AppKit

@main
struct ImageToPDFApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        // If CLI arguments were provided with files, run CLI mode
        if CommandLine.arguments.count > 1 && !CommandLine.arguments[1].starts(with: "-NS") && !CommandLine.arguments[1].starts(with: "-psn") {
            runCLIModeIfRequested()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 780, minHeight: 520)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandGroup(replacing: .help) {
                Button("Image to PDF Help") {
                    if let url = URL(string: "https://support.apple.com/guide/preview/welcome/mac") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
    }

    private func runCLIModeIfRequested() {
        let args = Array(CommandLine.arguments.dropFirst())
        if args.contains("-h") || args.contains("--help") {
            print("""
            ImageToPDF - macOS Image & Code to PDF Converter
            Usage:
              ImageToPDF [files or folders...] -o <output.pdf>
              ImageToPDF (no arguments to open GUI)
            
            Supported Formats:
              Images:  .png, .jpg, .jpeg, .heic, .webp, .tiff, .bmp, .gif
              Code:    .py, .cpp, .c, .h, .hpp, .swift, .js, .ts, .rs, .go, .java, .sh, .json, .md, .txt, etc.
            
            Options:
              -o, --output <file>    Output PDF file path (default: output.pdf)
              --page-size <size>     fit, letter, or a4 (default: fit)
              --quality <quality>    max, high, med, low (default: max)
              -h, --help             Show this help message
            """)
            exit(0)
        }

        var outputFilename = "output.pdf"
        var imagePaths: [String] = []
        var pageSize: PageSizeOption = .fitToImage
        var quality: ImageQuality = .maximum

        var i = 0
        while i < args.count {
            let arg = args[i]
            if arg == "-o" || arg == "--output" {
                if i + 1 < args.count {
                    outputFilename = args[i + 1]
                    i += 2
                    continue
                }
            } else if arg == "--page-size" {
                if i + 1 < args.count {
                    let val = args[i + 1].lowercased()
                    if val == "letter" { pageSize = .usLetter }
                    else if val == "a4" { pageSize = .a4 }
                    i += 2
                    continue
                }
            } else if arg == "--quality" {
                if i + 1 < args.count {
                    let val = args[i + 1].lowercased()
                    if val == "high" { quality = .high }
                    else if val == "med" || val == "medium" { quality = .medium }
                    else if val == "low" { quality = .low }
                    i += 2
                    continue
                }
            } else if !arg.starts(with: "-") {
                imagePaths.append(arg)
            }
            i += 1
        }

        guard !imagePaths.isEmpty else {
            return // No image paths specified; launch normal GUI
        }

        let supportedExts: Set<String> = ImageItem.imageExtensions.union(ImageItem.codeExtensions.keys)

        var resolvedURLs: [URL] = []
        for path in imagePaths {
            let url = URL(fileURLWithPath: path)
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) {
                if isDir.boolValue {
                    var folderURLs: [URL] = []
                    if let enumerator = FileManager.default.enumerator(
                        at: url,
                        includingPropertiesForKeys: [.isRegularFileKey],
                        options: [.skipsHiddenFiles, .skipsPackageDescendants]
                    ) {
                        for case let fileURL as URL in enumerator {
                            if supportedExts.contains(fileURL.pathExtension.lowercased()) {
                                folderURLs.append(fileURL)
                            }
                        }
                    }
                    folderURLs.sort {
                        $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending
                    }
                    resolvedURLs.append(contentsOf: folderURLs)
                } else if supportedExts.contains(url.pathExtension.lowercased()) {
                    resolvedURLs.append(url)
                }
            } else {
                print("Warning: File or folder does not exist at \(path)")
            }
        }

        guard !resolvedURLs.isEmpty else {
            print("Error: No valid images or code files found in the specified path(s).")
            exit(1)
        }

        print("Converting \(resolvedURLs.count) file(s) to \(outputFilename)...")
        let items = resolvedURLs.map { ImageItem(url: $0) }

        var settings = ConversionSettings()
        settings.pageSize = pageSize
        settings.quality = quality
        let outputURL = URL(fileURLWithPath: outputFilename)

        do {
            try PDFConverter.shared.convertToSinglePDF(items: items, settings: settings, destinationURL: outputURL)
            print("✓ Successfully created \(outputURL.path)")
            exit(0)
        } catch {
            print("Error converting images: \(error.localizedDescription)")
            exit(1)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
