// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "Improve",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "Improve",
            targets: ["Improve"]),
    ],
    targets: [
        .target(
            name: "Improve",
            path: "Improve",
            exclude: ["Tests"],
            publicHeadersPath:"Classes",
            cSettings: [
                .headerSearchPath("Categories"),
                .headerSearchPath("Classes/Utils"),
                .headerSearchPath("Classes/FeatureEncoder"),
                .headerSearchPath("Classes/Utils"),
                .headerSearchPath("Classes/Downloader"),
                .headerSearchPath("Thirdparty/GZip"),
                .headerSearchPath("Thirdparty/XXHash"),
            ])
    ]
)
