import Foundation

public protocol StorageService: AnyObject {
    func loadSettings() throws -> UserSettings?
    func save(settings: UserSettings) throws
    func clear() throws
}

public final class InMemoryStorageService: StorageService {
    private var cachedSettings: UserSettings?
    private let queue = DispatchQueue(label: "com.spotrun.storage", attributes: .concurrent)

    public init() {}

    public func loadSettings() throws -> UserSettings? {
        var result: UserSettings?
        queue.sync {
            result = cachedSettings
        }
        return result
    }

    public func save(settings: UserSettings) throws {
        queue.async(flags: .barrier) {
            self.cachedSettings = settings
        }
    }

    public func clear() throws {
        queue.async(flags: .barrier) {
            self.cachedSettings = nil
        }
    }
}
