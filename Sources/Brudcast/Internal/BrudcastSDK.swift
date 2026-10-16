import Foundation

/// Facts about this build of the SDK.
public enum BrudcastSDK {
    public static let version = "0.1.0"

    public static let platform = "ios"

    static var appVersion: String? {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }

    static var userAgent: String {
        "BrudcastSDK-iOS/\(version)"
    }
}
