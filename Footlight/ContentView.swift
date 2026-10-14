import SwiftUI

/// Root chrome. The cap grid stays put. Sheets cover pets, routines, settings, and the curtain ledger.
struct ContentView: View {
    @StateObject private var session = HouseSession.live()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        GridScreen(session: session)
            .sheet(isPresented: $session.petsPresented) {
                PetSheet(session: session)
            }
            .sheet(isPresented: $session.routinesPresented) {
                RoutineSheet(session: session)
            }
            .sheet(isPresented: $session.settingsPresented) {
                SettingsSheet(session: session)
            }
            .sheet(isPresented: $session.curtainPresented) {
                CurtainSheet(session: session)
            }
            .fullScreenCover(isPresented: $session.showOnboarding) {
                OnboardingFlow(session: session)
                    .interactiveDismissDisabled()
            }
            .task { await session.start() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    Task { await session.refreshDay() }
                } else {
                    Task { await session.flush() }
                }
            }
    }
}
