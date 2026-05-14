// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ITabPager",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "ITabPager", targets: ["ITabPager"]),
    ],
    targets: [
        .target(name: "ITabPager"),
        .testTarget(name: "ITabPagerTests", dependencies: ["ITabPager"]),
    ]
)
