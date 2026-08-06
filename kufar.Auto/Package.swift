// swift-tools-version: 5.9
import PackageDescription

// Симметрично «Товарам», но со своими блоками карточки:
// проверка по VIN, история владельцев, гарантия дилера.

let package = Package(
    name: "KufarAuto",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "Auto", targets: ["Auto"])
    ],
    dependencies: [
        .package(id: "kufar.AutoContracts", from: "1.0.0"),
        .package(id: "kufar.SearchContracts", from: "1.0.0"),
        .package(id: "kufar.IdentityContracts", from: "1.0.0"),
        .package(id: "kufar.Foundation", from: "1.0.0"),
        .package(id: "kufar.Navigation", from: "1.0.0"),
        .package(id: "kufar.Analytics", from: "1.0.0"),
        .package(id: "kufar.DesignTokens", from: "1.0.0"),
        .package(id: "kufar.DesignComponents", from: "1.0.0"),
        .package(id: "kufar.SchemaKit", from: "1.0.0"),
        .package(id: "kufar.ListingKit", from: "1.0.0"),
        // Слот шага подачи: вертикаль участвует в чужом флоу, поэтому знает
        // его контракт. Оба пакета контрактные — это не горизонталь.
        .package(id: "kufar.PostingContracts", from: "1.0.0"),
        .package(id: "kufar.CatalogContracts", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "AutoDomain",
            dependencies: [
                .product(name: "SharedKernel", package: "kufar.Foundation")
            ]
        ),
        .target(
            name: "AutoData",
            dependencies: [
                "AutoDomain",
                .product(name: "Networking", package: "kufar.Foundation"),
                .product(name: "SharedKernel", package: "kufar.Foundation")
            ]
        ),
        .target(
            name: "AutoUI",
            dependencies: [
                "AutoDomain",
                .product(name: "AutoInterface", package: "kufar.AutoContracts"),
                .product(name: "SearchInterface", package: "kufar.SearchContracts"),
                .product(name: "ProfileInterface", package: "kufar.IdentityContracts"),
                .product(name: "Navigation", package: "kufar.Navigation"),
                .product(name: "DesignTokens", package: "kufar.DesignTokens"),
                .product(name: "DesignComponents", package: "kufar.DesignComponents"),
                .product(name: "SchemaKit", package: "kufar.SchemaKit"),
                .product(name: "ListingKit", package: "kufar.ListingKit"),
                .product(name: "AnalyticsAPI", package: "kufar.Analytics"),
                .product(name: "SharedKernel", package: "kufar.Foundation"),
                .product(name: "PostingInterface", package: "kufar.PostingContracts"),
                .product(name: "CatalogContracts", package: "kufar.CatalogContracts")
            ]
        ),
        .target(
            name: "Auto",
            dependencies: [
                "AutoUI",
                "AutoData",
                "AutoDomain",
                .product(name: "AnalyticsAPI", package: "kufar.Analytics"),
                .product(name: "Networking", package: "kufar.Foundation"),
                // ListingRef в сигнатуре rowAccessory(for:).
                .product(name: "SharedKernel", package: "kufar.Foundation"),
                // CatalogCategory и PostingDraft в сигнатуре postingStep(_:draft:).
                .product(name: "PostingInterface", package: "kufar.PostingContracts"),
                .product(name: "CatalogContracts", package: "kufar.CatalogContracts")
            ]
        )
    ]
)
