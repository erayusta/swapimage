import SwiftUI

struct AppRootView: View {
    @StateObject private var viewModel = PhotoCleanerViewModel()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var hasBootstrapped = false
    @State private var showOnboarding = false

    var body: some View {
        ContentView(viewModel: viewModel)
            .onAppear {
                if hasCompletedOnboarding {
                    bootstrapIfNeeded()
                } else {
                    showOnboarding = true
                }
            }
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingView {
                    hasCompletedOnboarding = true
                    showOnboarding = false
                    bootstrapIfNeeded()
                }
            }
    }

    private func bootstrapIfNeeded() {
        guard hasCompletedOnboarding, !hasBootstrapped else { return }
        hasBootstrapped = true
        viewModel.bootstrap()
    }
}
