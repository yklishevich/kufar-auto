// swift-tools-version: 5.9
import PackageDescription

// Маршруты и публичные модели вертикали «Авто».

let package = Package(
    name: "KufarAutoContracts",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "AutoInterface", targets: ["AutoInterface"])
    ],
    dependencies: [
        .package(id: "kufar.Foundation", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "AutoInterface",
            dependencies: [
                .product(name: "SharedKernel", package: "kufar.Foundation")
            ]
        )
    ]
)
