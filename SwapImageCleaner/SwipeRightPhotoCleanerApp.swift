import SwiftUI

@main
struct SwipeRightPhotoCleanerApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        // Prepare haptics on app launch
        HapticManager.shared.prepareAll()
    }
    
    var body: some Scene {
        WindowGroup {
            SplashView()
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
                // App became active - prepare haptics
                HapticManager.shared.prepareAll()
            case .inactive:
                // App is transitioning
                break
            case .background:
                // App went to background
                break
            @unknown default:
                break
            }
        }
    }
}
