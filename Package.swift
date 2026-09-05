// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AutoClicker",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "AutoClicker",
            path: "Sources/AutoClicker"
        )
    ]
)
