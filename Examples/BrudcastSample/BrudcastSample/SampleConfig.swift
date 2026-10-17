import Foundation
import Brudcast

/// The values `Config/Sample.xcconfig` and `Config/Local.xcconfig` put in the Info.plist.
enum SampleConfig {
    static let deepLinkScheme = "brudcast-sample"

    static var publishableKey: String? {
        value("BrudcastPublishableKey")
    }

    static var environmentName: String {
        value("BrudcastEnvironment") ?? "production"
    }

    static var environment: BrudcastEnvironment {
        switch environmentName.lowercased() {
        case "staging": return .staging
        case "uat": return .uat
        case "development": return .development
        case "local": return .local(port: Int(value("BrudcastLocalPort") ?? "") ?? 8191)
        default: return .production
        }
    }

    static var appGroup: String? {
        value("BrudcastAppGroup")
    }

    static var sampleBackend: SampleBackend? {
        value("BrudcastSampleBackendURL").flatMap(URL.init(string:)).map(SampleBackend.init(baseURL:))
    }

    private static func value(_ key: String) -> String? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: key) as? String else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? nil : trimmed
    }
}
