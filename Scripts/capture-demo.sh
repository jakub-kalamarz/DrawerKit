#!/bin/zsh

set -euo pipefail

if [[ $# -ne 1 ]]; then
    print -u2 "Usage: Scripts/capture-demo.sh <simulator-udid>"
    exit 64
fi

drawerkit_simulator_udid="$1"
drawerkit_root="${0:A:h:h}"
drawerkit_demo="$drawerkit_root/Examples/DrawerKitDemo"
drawerkit_derived="/tmp/drawerkit-demo-derived"
drawerkit_resources="$drawerkit_root/Sources/DrawerKit/Documentation.docc/Resources"
drawerkit_bundle_id="dev.jakubkalamarz.DrawerKitDemo"

xcodebuild build -quiet \
    -workspace "$drawerkit_demo/DrawerKitDemo.xcworkspace" \
    -scheme DrawerKitDemo \
    -destination "platform=iOS Simulator,id=$drawerkit_simulator_udid" \
    -derivedDataPath "$drawerkit_derived" \
    CODE_SIGNING_ALLOWED=NO

xcrun simctl boot "$drawerkit_simulator_udid" 2>/dev/null || true
xcrun simctl bootstatus "$drawerkit_simulator_udid" -b
xcrun simctl install \
    "$drawerkit_simulator_udid" \
    "$drawerkit_derived/Build/Products/Debug-iphonesimulator/DrawerKitDemo.app"
xcrun simctl status_bar "$drawerkit_simulator_udid" override \
    --time "9:41" \
    --batteryState charged \
    --batteryLevel 100 \
    --wifiBars 3 \
    --cellularBars 4

for drawerkit_appearance in light dark; do
    xcrun simctl launch --terminate-running-process \
        "$drawerkit_simulator_udid" \
        "$drawerkit_bundle_id" \
        -drawer-open \
        "-$drawerkit_appearance"
    sleep 2
    xcrun simctl io \
        "$drawerkit_simulator_udid" \
        screenshot \
        "$drawerkit_resources/drawer-$drawerkit_appearance.png"
done

print "Captured light and dark DrawerKit screenshots in $drawerkit_resources"
