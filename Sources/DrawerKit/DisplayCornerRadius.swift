import SwiftUI

#if canImport(UIKit)
    import UIKit
#endif

@available(iOS 18.0, macOS 15.0, *)
extension Color {
    /// The system's own window/page background, used when a host sets no ``DrawerConfiguration``
    /// background of its own.
    static var platformBackground: Color {
        #if canImport(UIKit)
            Color(.systemBackground)
        #elseif canImport(AppKit)
            Color(nsColor: .windowBackgroundColor)
        #else
            .white
        #endif
    }
}

/// The radius of the display's own rounded corners, so content moved aside can keep the shape of
/// the screen it came from. The system exposes no API for this, so it is read from a table of
/// device identifiers; unknown hardware falls back to the current generation's radius.
enum DisplayCornerRadius {
    static var current: CGFloat {
        #if canImport(UIKit)
            let modelIdentifier = modelIdentifier
            if modelIdentifier.hasPrefix("iPad") { return 18 }
            return radii[modelIdentifier] ?? 55
        #else
            return 0
        #endif
    }

    #if canImport(UIKit)
        private static var modelIdentifier: String {
            if let simulatorIdentifier = ProcessInfo.processInfo.environment[
                "SIMULATOR_MODEL_IDENTIFIER"]
            {
                return simulatorIdentifier
            }

            var systemInfo = utsname()
            uname(&systemInfo)
            return Mirror(reflecting: systemInfo.machine).children.reduce(into: "") {
                identifier, element in
                guard let value = element.value as? Int8, value != 0 else { return }
                identifier.append(Character(UnicodeScalar(UInt8(value))))
            }
        }

        private static let radii: [String: CGFloat] = [
            "iPhone10,1": 0, "iPhone10,2": 0, "iPhone10,4": 0, "iPhone10,5": 0,
            "iPhone10,3": 39, "iPhone10,6": 39,
            "iPhone11,2": 39, "iPhone11,4": 39, "iPhone11,6": 39, "iPhone11,8": 41.5,
            "iPhone12,1": 41.5, "iPhone12,3": 39, "iPhone12,5": 39, "iPhone12,8": 0,
            "iPhone13,1": 44, "iPhone13,2": 47.33, "iPhone13,3": 47.33, "iPhone13,4": 53.33,
            "iPhone14,2": 47.33, "iPhone14,3": 53.33, "iPhone14,4": 44, "iPhone14,5": 47.33,
            "iPhone14,6": 0, "iPhone14,7": 47.33, "iPhone14,8": 53.33,
            "iPhone15,2": 55, "iPhone15,3": 55, "iPhone15,4": 55, "iPhone15,5": 55,
            "iPhone16,1": 55, "iPhone16,2": 55,
            "iPhone17,1": 62, "iPhone17,2": 62, "iPhone17,3": 55, "iPhone17,4": 55,
            "iPhone17,5": 55,
            "iPhone18,1": 62, "iPhone18,2": 62, "iPhone18,3": 62, "iPhone18,4": 62,
        ]
    #endif
}
