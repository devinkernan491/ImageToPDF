import SwiftUI
import PDFKit

struct PDFKitRepresentedView: NSViewRepresentable {
    let pdfDocument: PDFDocument

    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = pdfDocument
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displaysPageBreaks = true
        pdfView.backgroundColor = NSColor.windowBackgroundColor
        return pdfView
    }

    func updateNSView(_ nsView: PDFView, context: Context) {
        nsView.document = pdfDocument
    }
}

struct PDFPreviewSheet: View {
    let pdfData: Data
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    private var pdfDocument: PDFDocument? {
        PDFDocument(data: pdfData)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header bar
            HStack {
                Text("PDF Preview")
                    .font(.headline)
                
                if let doc = pdfDocument {
                    Text("(\(doc.pageCount) \(doc.pageCount == 1 ? "page" : "pages"))")
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Save PDF...") {
                    dismiss()
                    onSave()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // PDF display
            if let doc = pdfDocument {
                PDFKitRepresentedView(pdfDocument: doc)
                    .frame(minWidth: 600, minHeight: 600)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("Unable to generate PDF preview")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 700, minHeight: 650)
    }
}
