import Foundation
import Security

/// Small values the SDK keeps between launches.
public final class BrudcastStorage {
    let defaults: UserDefaults
    public let directory: URL

    init(defaults: UserDefaults, directory: URL) {
        self.defaults = defaults
        self.directory = directory
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var url = directory
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? url.setResourceValues(values)
    }

    static func standard() -> BrudcastStorage {
        let defaults = UserDefaults(suiteName: "com.brudcast.sdk") ?? .standard
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return BrudcastStorage(defaults: defaults, directory: base.appendingPathComponent("Brudcast", isDirectory: true))
    }

    /// Reads a string.
    ///
    /// - Parameter key: The key.
    /// - Returns: The stored string, or nil.
    public func string(_ key: String) -> String? {
        defaults.string(forKey: key)
    }

    /// Stores a string, or removes the key when the value is nil.
    ///
    /// - Parameters:
    ///   - value: The value.
    ///   - key: The key.
    public func set(_ value: String?, for key: String) {
        if let value = value {
            defaults.set(value, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }

    /// Reads a boolean, false when absent.
    ///
    /// - Parameter key: The key.
    /// - Returns: The stored value.
    public func bool(_ key: String) -> Bool {
        defaults.bool(forKey: key)
    }

    /// Stores a boolean.
    ///
    /// - Parameters:
    ///   - value: The value.
    ///   - key: The key.
    public func set(_ value: Bool, for key: String) {
        defaults.set(value, forKey: key)
    }

    /// Reads a JSON document from a file in the SDK's directory.
    ///
    /// - Parameter name: The file name.
    /// - Returns: The decoded document, or nil when the file is missing or unreadable.
    public func readJSON(_ name: String) -> Any? {
        let url = directory.appendingPathComponent(name)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: [])
    }

    /// Writes a JSON document atomically to a file in the SDK's directory.
    ///
    /// - Parameters:
    ///   - object: The document.
    ///   - name: The file name.
    public func writeJSON(_ object: Any, to name: String) {
        let url = directory.appendingPathComponent(name)
        guard JSONSerialization.isValidJSONObject(object),
              let data = try? JSONSerialization.data(withJSONObject: object, options: []) else {
            BrudcastLogger.shared.error("Could not encode \(name)")
            return
        }
        do {
            try data.write(to: url, options: [.atomic])
        } catch {
            BrudcastLogger.shared.error("Could not write \(name): \(error.localizedDescription)")
        }
    }

    /// Deletes a file in the SDK's directory.
    ///
    /// - Parameter name: The file name.
    public func remove(_ name: String) {
        try? FileManager.default.removeItem(at: directory.appendingPathComponent(name))
    }
}

enum DeviceIdentifier {
    private static let service = "com.brudcast.sdk"
    private static let account = "device_id"
    private static let fallbackKey = "brudcast.device_id"

    static func load(storage: BrudcastStorage) -> String {
        if let existing = readKeychain() {
            return existing
        }
        if let fallback = storage.string(fallbackKey) {
            if writeKeychain(fallback) {
                storage.set(nil, for: fallbackKey)
            }
            return fallback
        }
        let created = UUID().uuidString.lowercased()
        if !writeKeychain(created) {
            storage.set(created, for: fallbackKey)
        }
        return created
    }

    private static func readKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8),
              !value.isEmpty else {
            return nil
        }
        return value
    }

    private static func writeKeychain(_ value: String) -> Bool {
        let identity: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(identity as CFDictionary)
        var attributes = identity
        attributes[kSecValueData as String] = Data(value.utf8)
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        attributes[kSecAttrSynchronizable as String] = false
        return SecItemAdd(attributes as CFDictionary, nil) == errSecSuccess
    }
}
