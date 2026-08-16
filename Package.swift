// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DrawerKit",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "DrawerKit", targets: ["DrawerKit"])
    ],
    targets: [
        .target(name: "DrawerKit"),
        .testTarget(name: "DrawerKitTests", dependencies: ["DrawerKit"]),
    ]
)
