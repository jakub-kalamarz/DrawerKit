import ProjectDescription

let project = Project(
    name: "DrawerKitDemo",
    packages: [
        .local(path: "../..")
    ],
    targets: [
        .target(
            name: "DrawerKitDemo",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.jakubkalamarz.DrawerKitDemo",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "DrawerKit",
                "UILaunchScreen": [:],
            ]),
            sources: ["Sources/**"],
            dependencies: [
                .package(product: "DrawerKit")
            ]
        ),
        .target(
            name: "DrawerKitDemoUITests",
            destinations: .iOS,
            product: .uiTests,
            bundleId: "dev.jakubkalamarz.DrawerKitDemoUITests",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .default,
            sources: ["UITests/**"],
            dependencies: [
                .target(name: "DrawerKitDemo")
            ]
        ),
    ]
)
