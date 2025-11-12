import SwiftUI

@main
struct SwipeRightPhotoCleanerApp: App {
    @StateObject private var viewModel = PhotoCleanerViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .onAppear {
                    viewModel.bootstrap()
                }
        }
    }
}
