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
    ],
    targets: [
        .target(
            name: "ImproveAI",
            path: "ImproveAI",
            exclude: ["Tests"],
            publicHeadersPath:"Classes",
            cSettings: [
                .headerSearchPath("**"),
                .define("IMPROVE_AI_DEBUG", .when(configuration: .debug)),
            ])
    ]
)
