import Foundation

public enum AudioAction: Equatable {
    case play
    case pause
    case fadeTo(Double)
    case stop
}

public protocol AudioPolicyEngineDelegate: AnyObject {
    func audioPolicyEngine(_ engine: AudioPolicyEngine, didEmit action: AudioAction)
    func audioPolicyEngine(_ engine: AudioPolicyEngine, didTransitionFrom oldState: AudioEngineState, to newState: AudioEngineState)
}

public enum AudioEngineState: Equatable {
    case stopped
    case waitingForZone
    case playing
    case fadingOut
    case fadingIn
    case paused
}

public final class AudioPolicyEngine {
    public weak var delegate: AudioPolicyEngineDelegate?
    private(set) public var state: AudioEngineState
    private var lastTransitionDate: Date
    private let fadeDuration: TimeInterval

    public init(state: AudioEngineState = .stopped, fadeDuration: TimeInterval = 0.8) {
        self.state = state
        self.fadeDuration = fadeDuration
        self.lastTransitionDate = Date()
    }

    public func reset() {
        transition(to: .stopped)
    }

    public func startSession() {
        transition(to: .waitingForZone)
    }

    public func requestPlay() {
        switch state {
        case .playing, .fadingIn:
            break
        case .waitingForZone, .paused, .fadingOut:
            transition(to: .fadingIn)
            delegate?.audioPolicyEngine(self, didEmit: .fadeTo(1.0))
            DispatchQueue.main.asyncAfter(deadline: .now() + fadeDuration) { [weak self] in
                guard let self else { return }
                self.transition(to: .playing)
                self.delegate?.audioPolicyEngine(self, didEmit: .play)
            }
        case .stopped:
            startSession()
            requestPlay()
        }
    }

    public func requestPause(reason: PauseReason) {
        switch state {
        case .playing, .fadingIn:
            transition(to: .fadingOut)
            delegate?.audioPolicyEngine(self, didEmit: .fadeTo(reason.volumeFloor))
            DispatchQueue.main.asyncAfter(deadline: .now() + fadeDuration) { [weak self] in
                guard let self else { return }
                self.transition(to: .paused)
                if reason.shouldPausePlayback {
                    self.delegate?.audioPolicyEngine(self, didEmit: .pause)
                }
            }
        case .paused, .fadingOut:
            break
        case .waitingForZone:
            transition(to: .paused)
        case .stopped:
            break
        }
    }

    private func transition(to newState: AudioEngineState) {
        guard state != newState else { return }
        let oldState = state
        state = newState
        lastTransitionDate = Date()
        delegate?.audioPolicyEngine(self, didTransitionFrom: oldState, to: newState)
    }
}

public struct PauseReason: Equatable {
    public enum Cause: Equatable {
        case outOfZone
        case paceRequirementFailed
        case sensorLost
        case userPaused
    }

    public let cause: Cause
    public let shouldPausePlayback: Bool
    public let volumeFloor: Double

    public init(cause: Cause, shouldPausePlayback: Bool, volumeFloor: Double = 0.0) {
        self.cause = cause
        self.shouldPausePlayback = shouldPausePlayback
        self.volumeFloor = volumeFloor
    }
}
