# SpotRun MVP

This repository contains the SpotRun MVP prototype built with SwiftUI and a shared `SpotRunCore` module that encapsulates the workout business rules. The project is organized as:

- `SpotRun/`: Swift Package with the `SpotRunCore` library and unit tests
- `App/`: SwiftUI application scaffolding that consumes `SpotRunCore`

Key capabilities implemented:

- Heart-rate zone modeling with hysteresis control and tolerance
- Audio policy engine for fade-in/out transitions mapped to workout state
- Session coordination that fuses heart rate, pace, and cadence metrics
- Spotify service abstractions and onboarding flows with mock implementations
- SwiftUI interface for onboarding, home dashboard, live session, summary, stats, and settings screens

The unit tests cover zone math, hysteresis behavior, and pace gating logic.

To run the Swift package tests:

```bash
cd SpotRun
swift test
```

The SwiftUI app scaffolding is provided for Xcode integration and previews. It uses mock services so it can run in the simulator without HealthKit or Spotify credentials.
