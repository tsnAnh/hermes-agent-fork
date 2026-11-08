// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "HermesKit",
    platforms: [.iOS("26.0"), .macOS("26.0")],
    products: [
        .library(name: "HermesProtocol", targets: ["HermesProtocol"]),
        .library(name: "HermesDiagnostics", targets: ["HermesDiagnostics"]),
        .library(name: "HermesREST", targets: ["HermesREST"]),
        .library(name: "HermesAuth", targets: ["HermesAuth"]),
        .library(name: "HermesTransport", targets: ["HermesTransport"]),
        .library(name: "HermesClient", targets: ["HermesClient"]),
        .library(name: "HermesChat", targets: ["HermesChat"]),
        .library(name: "HermesRoster", targets: ["HermesRoster"]),
        .library(name: "HermesSettings", targets: ["HermesSettings"]),
    ],
    targets: [
        .target(name: "HermesProtocol", dependencies: ["HermesDiagnostics"]),
        .target(name: "HermesDiagnostics"),
        .target(name: "HermesREST", dependencies: ["HermesProtocol", "HermesDiagnostics"]),
        .target(name: "HermesAuth", dependencies: ["HermesREST", "HermesDiagnostics"]),
        .target(name: "HermesTransport", dependencies: ["HermesProtocol", "HermesDiagnostics"]),
        .target(
            name: "HermesClient",
            dependencies: ["HermesProtocol", "HermesDiagnostics", "HermesREST", "HermesAuth", "HermesTransport"]
        ),
        .target(
            name: "HermesChat",
            dependencies: [
                "HermesProtocol", "HermesDiagnostics", "HermesTransport", "HermesClient", "HermesREST", "HermesAuth",
            ]
        ),
        .target(name: "HermesRoster", dependencies: ["HermesProtocol", "HermesDiagnostics", "HermesTransport"]),
        .target(name: "HermesSettings", dependencies: ["HermesProtocol", "HermesTransport"]),
        .testTarget(
            name: "HermesKitTests",
            dependencies: [
                "HermesProtocol", "HermesDiagnostics", "HermesREST", "HermesAuth", "HermesTransport", "HermesClient",
                "HermesChat", "HermesRoster", "HermesSettings",
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
