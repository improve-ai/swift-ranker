// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "ImproveAI",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "ImproveAI",
            targets: ["ImproveAICore", "ImproveAI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Flight-School/AnyCodable", .upToNextMajor(from: "0.6.5")),
    ],
    targets: [
        .target(
            name: "ImproveAICore",
            path: "ImproveAI",
            exclude: [
                "Tests",
                "ThirdParty/GZip/LICENSE.md",
                "ThirdParty/Ksuid/LICENSE",
                "ThirdParty/XXHash/LICENSE"
            ],
            publicHeadersPath:"include",
            cSettings: [
                .headerSearchPath("**"),
                .define("IMPROVE_AI_DEBUG", .when(configuration: .debug)),
            ]),
        .target(
            name: "ImproveAI",
            dependencies: ["ImproveAICore", .product(name: "AnyCodable", package: "AnyCodable")],
            path: "ImproveAISwift"),
        .testTarget(
            name: "ImproveAISwiftTests",
            dependencies: ["ImproveAI"])
    ]
)
