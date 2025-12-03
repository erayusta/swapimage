import StoreKit
import SwiftUI

/// Manages app review requests using Apple's StoreKit
/// Follows Apple's guidelines for requesting reviews at appropriate moments
@MainActor
final class ReviewManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = ReviewManager()
    
    // MARK: - Constants
    private enum Constants {
        static let processedCountKey = "reviewProcessedCount"
        static let lastReviewRequestDateKey = "lastReviewRequestDate"
        static let hasRatedAppKey = "hasRatedApp"
        static let appLaunchCountKey = "appLaunchCount"
        static let lastVersionPromptedKey = "lastVersionPromptedForReview"
        
        // Thresholds for review request
        static let minPhotosProcessed = 20
        static let minDaysBetweenRequests = 60
        static let minAppLaunches = 3
    }
    
    // MARK: - Published Properties
    @Published private(set) var canRequestReview = false
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Computed Properties
    private var processedCount: Int {
        get { userDefaults.integer(forKey: Constants.processedCountKey) }
        set { userDefaults.set(newValue, forKey: Constants.processedCountKey) }
    }
    
    private var lastReviewRequestDate: Date? {
        get { userDefaults.object(forKey: Constants.lastReviewRequestDateKey) as? Date }
        set { userDefaults.set(newValue, forKey: Constants.lastReviewRequestDateKey) }
    }
    
    private var hasRatedApp: Bool {
        get { userDefaults.bool(forKey: Constants.hasRatedAppKey) }
        set { userDefaults.set(newValue, forKey: Constants.hasRatedAppKey) }
    }
    
    private var appLaunchCount: Int {
        get { userDefaults.integer(forKey: Constants.appLaunchCountKey) }
        set { userDefaults.set(newValue, forKey: Constants.appLaunchCountKey) }
    }
    
    private var lastVersionPrompted: String? {
        get { userDefaults.string(forKey: Constants.lastVersionPromptedKey) }
        set { userDefaults.set(newValue, forKey: Constants.lastVersionPromptedKey) }
    }
    
    private var currentAppVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    // MARK: - Initialization
    private init() {
        incrementAppLaunchCount()
        updateCanRequestReview()
    }
    
    // MARK: - Public Methods
    
    /// Call this when user completes a meaningful action (keep/delete/skip)
    func recordPhotoProcessed() {
        processedCount += 1
        updateCanRequestReview()
    }
    
    /// Call this when user completes a batch of deletions successfully
    func recordSuccessfulDeletion(count: Int) {
        // Good moment to potentially ask for review after successful deletion
        if count >= 5 {
            checkAndRequestReview(reason: .successfulDeletion)
        }
    }
    
    /// Call this when user finishes cleaning session (empty deck)
    func recordCleaningSessionComplete() {
        checkAndRequestReview(reason: .sessionComplete)
    }
    
    /// Request review if conditions are met
    func requestReviewIfAppropriate() {
        checkAndRequestReview(reason: .manual)
    }
    
    /// Mark that user has rated (call if you detect they went to App Store)
    func markAsRated() {
        hasRatedApp = true
        updateCanRequestReview()
    }
    
    // MARK: - Private Methods
    
    private func incrementAppLaunchCount() {
        appLaunchCount += 1
    }
    
    private func updateCanRequestReview() {
        // Don't show if already rated
        guard !hasRatedApp else {
            canRequestReview = false
            return
        }
        
        // Check minimum launches
        guard appLaunchCount >= Constants.minAppLaunches else {
            canRequestReview = false
            return
        }
        
        // Check minimum photos processed
        guard processedCount >= Constants.minPhotosProcessed else {
            canRequestReview = false
            return
        }
        
        // Check if enough time has passed since last request
        if let lastDate = lastReviewRequestDate {
            let daysSinceLastRequest = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
            guard daysSinceLastRequest >= Constants.minDaysBetweenRequests else {
                canRequestReview = false
                return
            }
        }
        
        // Check if we already prompted for this version
        if lastVersionPrompted == currentAppVersion {
            canRequestReview = false
            return
        }
        
        canRequestReview = true
    }
    
    private enum ReviewReason {
        case successfulDeletion
        case sessionComplete
        case manual
    }
    
    private func checkAndRequestReview(reason: ReviewReason) {
        guard canRequestReview else { return }
        
        // Additional checks based on reason
        switch reason {
        case .successfulDeletion:
            // Good moment - user just successfully cleaned photos
            break
        case .sessionComplete:
            // Great moment - user finished their cleaning session
            break
        case .manual:
            // Explicit request
            break
        }
        
        requestReview()
    }
    
    private func requestReview() {
        // Update tracking
        lastReviewRequestDate = Date()
        lastVersionPrompted = currentAppVersion
        canRequestReview = false
        
        // Request review using StoreKit
        if let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) {
            
            // Small delay for better UX
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                SKStoreReviewController.requestReview(in: windowScene)
            }
        }
    }
    
    // MARK: - Debug Methods (Remove in production)
    #if DEBUG
    func resetForTesting() {
        userDefaults.removeObject(forKey: Constants.processedCountKey)
        userDefaults.removeObject(forKey: Constants.lastReviewRequestDateKey)
        userDefaults.removeObject(forKey: Constants.hasRatedAppKey)
        userDefaults.removeObject(forKey: Constants.appLaunchCountKey)
        userDefaults.removeObject(forKey: Constants.lastVersionPromptedKey)
        updateCanRequestReview()
    }
    
    func forceShowReview() {
        if let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
    #endif
}

// MARK: - SwiftUI Environment Key
private struct ReviewManagerKey: EnvironmentKey {
    static var defaultValue: ReviewManager {
        ReviewManager.shared
    }
}

extension EnvironmentValues {
    var reviewManager: ReviewManager {
        get { self[ReviewManagerKey.self] }
        set { self[ReviewManagerKey.self] = newValue }
    }
}
