// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MapleKit",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "MapleKit",
            targets: ["MapleKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/theos/orion", branch: "master")
    ],
    targets: [
        .target(
            name: "MapleKit",
            dependencies: [])
    ]
)
