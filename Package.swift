// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let improveAIVersion = "7.2"

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
                .define("ImproveAI_VERSION", to: improveAIVersion),
                .define("IMPROVE_AI_DEBUG", .when(configuration: .debug)),
            ]),
        .target(
            name: "ImproveAI",
            dependencies: ["ImproveAICore"],
            path: "ImproveAISwift"),
        .testTarget(
            name: "ImproveAISwiftTests",
            dependencies: ["ImproveAI"])
    ]
)
