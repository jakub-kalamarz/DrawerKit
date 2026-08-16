# Contributing to DrawerKit

Thanks for helping improve DrawerKit.

1. Discuss large API or behavior changes in an issue first.
2. Create a focused branch and keep public API additions documented.
3. Run `swift format lint --recursive --strict Sources Tests Examples` and `swift test`.
4. For interaction changes, regenerate the demo project and run its UI tests.
5. Include screenshots or a recording for visible changes.

To refresh the documented light and dark screenshots, boot an iPhone simulator and run
`Scripts/capture-demo.sh <simulator-udid>` from the repository root.

Pull requests should explain the problem, the chosen behavior, and the verification performed.
Keep the package dependency-free unless a dependency is essential and agreed on in advance.
