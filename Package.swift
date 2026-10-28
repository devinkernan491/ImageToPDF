// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ImageToPDF",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "ImageToPDF",
            targets: ["ImageToPDF"]
        )
    ],
    targets: [
        .executableTarget(
            name: "ImageToPDF",
            path: "Sources/ImageToPDF"
        )
    ]
)
