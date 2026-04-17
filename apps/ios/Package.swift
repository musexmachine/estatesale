// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EstateSale",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "EstateSaleCore", targets: ["EstateSaleCore"]),
        .library(name: "EstateSaleSellerUI", targets: ["EstateSaleSellerUI"]),
    ],
    targets: [
        .target(name: "EstateSaleCore"),
        .target(
            name: "EstateSaleSellerUI",
            dependencies: ["EstateSaleCore"]
        ),
        .testTarget(
            name: "EstateSaleCoreTests",
            dependencies: ["EstateSaleCore"]
        ),
    ]
)
