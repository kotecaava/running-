import Foundation

public protocol SpotifyService: AnyObject {
    var authorizationStatus: SpotifyAuthorizationStatus { get }
    func connect() async throws
    func disconnect()
    func resume() async throws
    func pause() async throws
    func skipToNext() async throws
    func currentPlaybackState() async throws -> SpotifyPlayback
    func prepareAutoDJPlaylist(for zone: HRZone, settings: AutoDJSettings) async throws -> Playlist
    func availablePlaylists() async throws -> [Playlist]
}

public enum SpotifyAuthorizationStatus: Equatable {
    case notConnected
    case connecting
    case connected
    case failed(message: String)
}

public struct SpotifyPlayback: Equatable {
    public enum State: Equatable {
        case playing
        case paused
        case stopped
    }

    public let state: State
    public let track: Track?

    public init(state: State, track: Track?) {
        self.state = state
        self.track = track
    }
}

public struct Track: Codable, Equatable {
    public let id: String
    public let name: String
    public let artist: String
    public let artworkURL: URL?
    public let duration: TimeInterval

    public init(id: String, name: String, artist: String, artworkURL: URL?, duration: TimeInterval) {
        self.id = id
        self.name = name
        self.artist = artist
        self.artworkURL = artworkURL
        self.duration = duration
    }
}

public struct Playlist: Codable, Equatable, Identifiable {
    public let id: String
    public let name: String
    public let description: String?
    public let artworkURL: URL?

    public init(id: String, name: String, description: String?, artworkURL: URL?) {
        self.id = id
        self.name = name
        self.description = description
        self.artworkURL = artworkURL
    }
}

public struct AutoDJSettings: Equatable {
    public let energyRange: ClosedRange<Double>
    public let tempoRange: ClosedRange<Double>
    public let seedGenres: [String]

    public init(energyRange: ClosedRange<Double>, tempoRange: ClosedRange<Double>, seedGenres: [String]) {
        self.energyRange = energyRange
        self.tempoRange = tempoRange
        self.seedGenres = seedGenres
    }
}
