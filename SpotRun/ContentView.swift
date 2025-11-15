//
//  ContentView.swift
//  SpotRun
//
//  Created by konstantine tsaava on 13.11.25.
//

import SwiftUI

import SpotRun // if it’s a separate module; otherwise just skip this
import SpotRunCore

struct ContentView: View {
    @State private var engine = AudioPolicyEngine()

    var body: some View {
        VStack(spacing: 20) {
            Text("SpotRun Demo")

            HStack {
                Button("Play") {
                    engine.requestPlay()
                }
                Button("Pause") {
                    engine.requestPause(
                        reason: PauseReason(cause: .userPaused,
                                            shouldPausePlayback: true,
                                            volumeFloor: 0.0)
                    )
                }
            }
        }
        .padding()
    }
}

@main
struct SpotRunApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
