// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let improveAIVersion = "8.0.0"

let package = Package(
    name: "ImproveAI",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(name: "ImproveAI", targets: ["utils", "ImproveAI"]),
    ],
    targets: [
        .target(
            name: "utils",
            path: "./Sources/utils",
            cSettings: [
                .define("ImproveAI_VERSION", to: improveAIVersion),
            ]),
        .target(
            name: "ImproveAI",
            dependencies: ["utils"],
            path: "./Sources/ImproveAI"),
        .testTarget(
            name: "ImproveAITests",
            dependencies: ["ImproveAI"],
            path: "Tests",
            resources: [.process("Resources")]
        )
    ]
)
