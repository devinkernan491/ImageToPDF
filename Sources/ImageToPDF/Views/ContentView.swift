import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var items: [ImageItem] = []
    @State private var settings = ConversionSettings()
    @State private var selectedItemID: UUID? = nil
    @State private var isTargetedForDrop: Bool = false
    @State private var isConverting: Bool = false
    @State private var statusMessage: String? = nil
    @State private var isErrorMessage: Bool = false
    @State private var previewPDFData: Data? = nil
    @State private var showPreviewSheet: Bool = false

    private let supportedExtensions: Set<String> = ImageItem.imageExtensions.union(ImageItem.codeExtensions.keys)

    var body: some View {
        HSplitView {
            // Main content area: Dropzone & List
            VStack(spacing: 0) {
                if items.isEmpty {
                    emptyDropView
                } else {
                    imagesListView
                }

                Divider()

                statusBarView
            }
            .frame(minWidth: 480, maxWidth: .infinity, minHeight: 500, maxHeight: .infinity)

            // Settings sidebar
            settingsSidebarView
                .frame(minWidth: 260, maxWidth: 320, minHeight: 500, maxHeight: .infinity)
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: { openFilePicker(chooseFolder: false) }) {
                    Label("Add Files", systemImage: "doc.badge.plus")
                }
                .help("Add image or code files (PNG, JPG, .py, .cpp, .swift, etc.)")

                Button(action: { openFilePicker(chooseFolder: true) }) {
                    Label("Add Folder", systemImage: "folder.badge.plus")
                }
                .help("Add all images and code files inside a folder")

                Button(action: generatePreview) {
                    Label("Preview", systemImage: "eye")
                }
                .disabled(items.isEmpty || !settings.combineIntoSinglePDF)
                .help("Preview generated PDF")

                Button(action: savePDF) {
                    Label(settings.combineIntoSinglePDF ? "Save PDF..." : "Export PDFs...", systemImage: "arrow.down.doc.fill")
                }
                .buttonStyle(.borderedProminent)
                .disabled(items.isEmpty || isConverting)
            }
        }
        .sheet(isPresented: $showPreviewSheet) {
            if let data = previewPDFData {
                PDFPreviewSheet(pdfData: data, onSave: savePDF)
            }
        }
    }

    // MARK: - Subviews

    private var emptyDropView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.image")
                .font(.system(size: 56))
                .foregroundColor(isTargetedForDrop ? .accentColor : .secondary)
                .animation(.easeInOut(duration: 0.2), value: isTargetedForDrop)

            Text("Drop Images, Code Files, or Folders Here")
                .font(.title2.weight(.medium))

            Text("Supports .py, .cpp, .c, .swift, .js, .ts, .json, PNG, JPG, HEIC, and more.\nDrag individual files or entire folders to convert.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                Button("Select Files...") {
                    openFilePicker(chooseFolder: false)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("Select Folder...") {
                    openFilePicker(chooseFolder: true)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isTargetedForDrop ? Color.accentColor : Color.secondary.opacity(0.2),
                    style: StrokeStyle(lineWidth: 2, dash: [8])
                )
                .padding(24)
        )
        .onDrop(of: [.fileURL], isTargeted: $isTargetedForDrop) { providers in
            handleDrop(providers: providers)
        }
    }

    private var imagesListView: some View {
        VStack(spacing: 0) {
            // Quick action header for the list
            HStack {
                Text("\(items.count) \(items.count == 1 ? "File" : "Files")")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: moveSelectedUp) {
                    Image(systemName: "arrow.up")
                }
                .disabled(selectedItemID == nil || selectedIndex == 0)
                .help("Move selected image up")

                Button(action: moveSelectedDown) {
                    Image(systemName: "arrow.down")
                }
                .disabled(selectedItemID == nil || selectedIndex == (items.count - 1))
                .help("Move selected image down")

                Button(action: removeSelected) {
                    Image(systemName: "trash")
                }
                .disabled(selectedItemID == nil)
                .help("Remove selected image")

                Button("Clear All") {
                    items.removeAll()
                    selectedItemID = nil
                }
                .buttonStyle(.plain)
                .foregroundColor(.red)
                .font(.subheadline)
                .padding(.leading, 8)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            List(selection: $selectedItemID) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    HStack(spacing: 12) {
                        Text("\(index + 1)")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                            .frame(width: 24, alignment: .trailing)

                        if let thumb = item.thumbnail {
                            Image(nsImage: thumb)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 48, height: 48)
                                .cornerRadius(4)
                        } else {
                            Image(systemName: "photo")
                                .font(.system(size: 28))
                                .frame(width: 48, height: 48)
                                .foregroundColor(.secondary)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.fileName)
                                .font(.headline)
                                .lineLimit(1)
                                .truncationMode(.middle)

                            HStack(spacing: 8) {
                                Text(item.dimensionsString)
                                Text("•")
                                Text(item.formattedSize)
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .tag(item.id)
                }
                .onMove { sourceIndices, destinationIndex in
                    items.move(fromOffsets: sourceIndices, toOffset: destinationIndex)
                }
            }
            .onDrop(of: [.fileURL], isTargeted: $isTargetedForDrop) { providers in
                handleDrop(providers: providers)
            }
        }
    }

    private var settingsSidebarView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("PDF Settings")
                    .font(.headline)

                Divider()

                // Output Mode
                VStack(alignment: .leading, spacing: 6) {
                    Text("Output")
                        .font(.subheadline.weight(.semibold))

                    Picker("Mode", selection: $settings.combineIntoSinglePDF) {
                        Text("Single Combined PDF").tag(true)
                        Text("Individual PDFs").tag(false)
                    }
                    .pickerStyle(.radioGroup)
                }

                Divider()

                // Page Size
                VStack(alignment: .leading, spacing: 6) {
                    Text("Page Layout")
                        .font(.subheadline.weight(.semibold))

                    Picker("Page Size", selection: $settings.pageSize) {
                        ForEach(PageSizeOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }

                    if settings.pageSize != .fitToImage {
                        Picker("Orientation", selection: $settings.orientation) {
                            ForEach(PageOrientation.allCases) { opt in
                                Text(opt.rawValue).tag(opt)
                            }
                        }

                        Picker("Margins", selection: $settings.margin) {
                            ForEach(PageMargin.allCases) { opt in
                                Text(opt.rawValue).tag(opt)
                            }
                        }
                    }
                }

                Divider()

                // Image Quality
                VStack(alignment: .leading, spacing: 6) {
                    Text("Image Compression")
                        .font(.subheadline.weight(.semibold))

                    Picker("Quality", selection: $settings.quality) {
                        ForEach(ImageQuality.allCases) { opt in
                            Text(opt.rawValue).tag(opt)
                        }
                    }

                    Text(settings.quality == .maximum ? "Preserves full source quality." : "Reduces PDF file size.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(16)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }

    private var statusBarView: some View {
        HStack {
            if let msg = statusMessage {
                HStack(spacing: 6) {
                    Image(systemName: isErrorMessage ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                        .foregroundColor(isErrorMessage ? .red : .green)
                    Text(msg)
                        .font(.caption)
                        .foregroundColor(isErrorMessage ? .red : .primary)
                }
            } else {
                Text(items.isEmpty ? "No files selected" : "\(items.count) \(items.count == 1 ? "file" : "files") ready for conversion")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isConverting {
                ProgressView()
                    .controlSize(.small)
                Text("Converting...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
    }

    // MARK: - Actions

    private var selectedIndex: Int? {
        guard let id = selectedItemID else { return nil }
        return items.firstIndex(where: { $0.id == id })
    }

    private func moveSelectedUp() {
        guard let idx = selectedIndex, idx > 0 else { return }
        items.swapAt(idx, idx - 1)
    }

    private func moveSelectedDown() {
        guard let idx = selectedIndex, idx < (items.count - 1) else { return }
        items.swapAt(idx, idx + 1)
    }

    private func removeSelected() {
        guard let idx = selectedIndex else { return }
        items.remove(at: idx)
        if idx < items.count {
            selectedItemID = items[idx].id
        } else if !items.isEmpty {
            selectedItemID = items.last?.id
        } else {
            selectedItemID = nil
        }
    }

    private func openFilePicker(chooseFolder: Bool = false) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canCreateDirectories = false

        if chooseFolder {
            panel.canChooseDirectories = true
            panel.canChooseFiles = false
            panel.prompt = "Add Folder"
        } else {
            panel.canChooseDirectories = false
            panel.canChooseFiles = true
            panel.allowsOtherFileTypes = true
            var contentTypes: [UTType] = [.image, .sourceCode, .plainText, .text, .json]
            for ext in supportedExtensions {
                if let ut = UTType(filenameExtension: ext) {
                    contentTypes.append(ut)
                }
            }
            panel.allowedContentTypes = contentTypes
        }

        if panel.runModal() == .OK {
            addURLs(panel.urls)
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else {
                    return
                }
                DispatchQueue.main.async {
                    self.addURLs([url])
                }
            }
        }
        return true
    }

    private func collectImageURLs(from url: URL) -> [URL] {
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
            var foundURLs: [URL] = []
            if let enumerator = FileManager.default.enumerator(
                at: url,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) {
                for case let fileURL as URL in enumerator {
                    let ext = fileURL.pathExtension.lowercased()
                    if supportedExtensions.contains(ext) {
                        foundURLs.append(fileURL)
                    }
                }
            }
            // Sort naturally (e.g. page 1, page 2, page 10)
            return foundURLs.sorted {
                $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending
            }
        } else {
            let ext = url.pathExtension.lowercased()
            if supportedExtensions.contains(ext) {
                return [url]
            }
            return []
        }
    }

    private func addURLs(_ urls: [URL]) {
        var newCount = 0
        for inputURL in urls {
            let imageFiles = collectImageURLs(from: inputURL)
            for fileURL in imageFiles {
                if !items.contains(where: { $0.url == fileURL }) {
                    items.append(ImageItem(url: fileURL))
                    newCount += 1
                }
            }
        }

        if selectedItemID == nil, let first = items.first {
            selectedItemID = first.id
        }

        if newCount > 0 {
            statusMessage = "Added \(newCount) file\(newCount == 1 ? "" : "s")"
            isErrorMessage = false
        }
    }

    private func generatePreview() {
        guard !items.isEmpty else { return }
        isConverting = true
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let data = try PDFConverter.shared.createPDFData(from: self.items, settings: self.settings)
                DispatchQueue.main.async {
                    self.previewPDFData = data
                    self.showPreviewSheet = true
                    self.isConverting = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.isConverting = false
                    self.isErrorMessage = true
                    self.statusMessage = "Preview failed: \(error.localizedDescription)"
                }
            }
        }
    }

    private func savePDF() {
        guard !items.isEmpty else { return }

        if settings.combineIntoSinglePDF {
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.pdf]
            panel.canCreateDirectories = true
            panel.nameFieldStringValue = defaultPDFName()

            if panel.runModal() == .OK, let destination = panel.url {
                isConverting = true
                statusMessage = nil
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        try PDFConverter.shared.convertToSinglePDF(items: self.items, settings: self.settings, destinationURL: destination)
                        DispatchQueue.main.async {
                            self.isConverting = false
                            self.isErrorMessage = false
                            self.statusMessage = "Successfully saved PDF to \(destination.lastPathComponent)!"
                            NSWorkspace.shared.activateFileViewerSelecting([destination])
                        }
                    } catch {
                        DispatchQueue.main.async {
                            self.isConverting = false
                            self.isErrorMessage = true
                            self.statusMessage = "Failed to save: \(error.localizedDescription)"
                        }
                    }
                }
            }
        } else {
            // Export individual PDFs to a folder
            let panel = NSOpenPanel()
            panel.canChooseFiles = false
            panel.canChooseDirectories = true
            panel.canCreateDirectories = true
            panel.prompt = "Export Here"

            if panel.runModal() == .OK, let destinationDir = panel.url {
                isConverting = true
                statusMessage = nil
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        let urls = try PDFConverter.shared.convertToIndividualPDFs(items: self.items, settings: self.settings, destinationDirectory: destinationDir)
                        DispatchQueue.main.async {
                            self.isConverting = false
                            self.isErrorMessage = false
                            self.statusMessage = "Successfully exported \(urls.count) PDFs!"
                            if let first = urls.first {
                                NSWorkspace.shared.activateFileViewerSelecting([first])
                            }
                        }
                    } catch {
                        DispatchQueue.main.async {
                            self.isConverting = false
                            self.isErrorMessage = true
                            self.statusMessage = "Export failed: \(error.localizedDescription)"
                        }
                    }
                }
            }
        }
    }

    private func defaultPDFName() -> String {
        if let first = items.first {
            let base = first.url.deletingPathExtension().lastPathComponent
            return items.count > 1 ? "\(base)_and_\(items.count - 1)_more.pdf" : "\(base).pdf"
        }
        return "Images.pdf"
    }
}
