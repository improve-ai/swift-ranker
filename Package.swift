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
            targets: ["ImproveAI"]),
        .library(
            name: "ImproveAISwift",
            targets: ["ImproveAISwift"]),
    ],
    targets: [
        .target(
            name: "ImproveAI",
            path: "ImproveAI",
            exclude: [
                "Tests",
                "ThirdParty/GZip/LICENSE.md",
                "ThirdParty/Ksuid/LICENSE",
                "ThirdParty/XXHash/LICENSE"
            ],
            publicHeadersPath:"Classes",
            cSettings: [
                .headerSearchPath("**"),
                .define("IMPROVE_AI_DEBUG", .when(configuration: .debug)),
            ]),
        .target(
            name: "ImproveAISwift",
            dependencies: ["ImproveAI"],
            path: "ImproveAISwift"),
        .testTarget(
            name: "ImproveAISwiftTests",
            dependencies: ["ImproveAISwift"])
    ]
)
