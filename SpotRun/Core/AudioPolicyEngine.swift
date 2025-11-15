import Foundation

struct PauseReason {
    enum Cause {
        case userPaused
        case zoneExit
        case sensorLoss
        case paceGate
    }

    let cause: Cause
    let shouldPausePlayback: Bool
    let volumeFloor: Double

    static let user = PauseReason(cause: .userPaused, shouldPausePlayback: true, volumeFloor: 0.0)
    static let zone = PauseReason(cause: .zoneExit, shouldPausePlayback: true, volumeFloor: 0.0)
    static let sensorSoft = PauseReason(cause: .sensorLoss, shouldPausePlayback: false, volumeFloor: 0.2)
    static let sensorHard = PauseReason(cause: .sensorLoss, shouldPausePlayback: true, volumeFloor: 0.0)
    static let pace = PauseReason(cause: .paceGate, shouldPausePlayback: true, volumeFloor: 0.0)
}

@MainActor
final class AudioPolicyEngine {
    enum State: Equatable {
        case stopped
        case waitingForZone
        case fadingIn
        case playing
        case fadingOut(PauseReason)
        case paused
    }

    private(set) var state: State = .stopped {
        didSet {
            if state != oldValue {
                notifyPlaybackChange()
            }
        }
    }

    var onPlaybackChange: ((PlaybackState) -> Void)?
    private var fadeTask: Task<Void, Never>?
    private let fadeDuration: TimeInterval

    init(fadeDuration: TimeInterval = 0.8) {
        self.fadeDuration = fadeDuration
    }

    func startSession() {
        transition(to: .waitingForZone)
    }

    func stopSession() {
        fadeTask?.cancel()
        fadeTask = nil
        transition(to: .stopped)
    }

    func requestPlay() {
        switch state {
        case .playing, .fadingIn:
            break
        case .stopped:
            transition(to: .waitingForZone)
            fallthrough
        case .waitingForZone, .paused, .fadingOut:
            beginFadeIn()
        }
    }

    func requestPause(reason: PauseReason) {
        switch state {
        case .paused where reason.shouldPausePlayback:
            break
        case .stopped:
            break
        case .waitingForZone:
            if reason.shouldPausePlayback {
                transition(to: .paused)
            }
        case .fadingOut(let existing) where !reason.shouldPausePlayback && existing.shouldPausePlayback:
            // honor softer fade when already harder fading
            break
        default:
            beginFadeOut(reason: reason)
        }
    }

    private func beginFadeIn() {
        fadeTask?.cancel()
        transition(to: .fadingIn)
        fadeTask = Task { [fadeDuration] in
            try? await Task.sleep(nanoseconds: UInt64(fadeDuration * 1_000_000_000))
            await MainActor.run {
                self.transition(to: .playing)
            }
        }
    }

    private func beginFadeOut(reason: PauseReason) {
        fadeTask?.cancel()
        transition(to: .fadingOut(reason))
        fadeTask = Task { [fadeDuration, reason] in
            try? await Task.sleep(nanoseconds: UInt64(fadeDuration * 1_000_000_000))
            await MainActor.run {
                self.transition(to: reason.shouldPausePlayback ? .paused : .waitingForZone)
            }
        }
    }

    private func transition(to newState: State) {
        if state == newState { return }
        state = newState
    }

    private func notifyPlaybackChange() {
        let playbackState: PlaybackState
        switch state {
        case .stopped:
            playbackState = .stopped
        case .waitingForZone:
            playbackState = .paused
        case .fadingIn:
            playbackState = .fadingIn
        case .playing:
            playbackState = .playing
        case .fadingOut:
            playbackState = .fadingOut
        case .paused:
            playbackState = .paused
        }
        onPlaybackChange?(playbackState)
    }
}
