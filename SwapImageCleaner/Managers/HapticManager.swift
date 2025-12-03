import UIKit

/// Centralized haptic feedback manager for consistent tactile experience
final class HapticManager {
    
    // MARK: - Singleton
    static let shared = HapticManager()
    
    // MARK: - Haptic Generators
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let softImpact = UIImpactFeedbackGenerator(style: .soft)
    private let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
    private let selection = UISelectionFeedbackGenerator()
    private let notification = UINotificationFeedbackGenerator()
    
    // MARK: - Initialization
    private init() {
        prepareAll()
    }
    
    // MARK: - Preparation
    
    /// Prepare all haptic generators for immediate use
    func prepareAll() {
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        softImpact.prepare()
        rigidImpact.prepare()
        selection.prepare()
        notification.prepare()
    }
    
    // MARK: - Impact Feedback
    
    /// Light impact - for subtle interactions
    func lightTap() {
        lightImpact.impactOccurred()
    }
    
    /// Medium impact - for standard interactions
    func mediumTap() {
        mediumImpact.impactOccurred()
    }
    
    /// Heavy impact - for significant actions
    func heavyTap() {
        heavyImpact.impactOccurred()
    }
    
    /// Soft impact - for gentle feedback
    func softTap() {
        softImpact.impactOccurred()
    }
    
    /// Rigid impact - for firm feedback
    func rigidTap() {
        rigidImpact.impactOccurred()
    }
    
    /// Custom intensity impact
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle, intensity: CGFloat = 1.0) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred(intensity: intensity)
    }
    
    // MARK: - Selection Feedback
    
    /// Selection changed - for picker/slider changes
    func selectionChanged() {
        selection.selectionChanged()
    }
    
    // MARK: - Notification Feedback
    
    /// Success notification - for completed actions
    func success() {
        notification.notificationOccurred(.success)
    }
    
    /// Warning notification - for caution situations
    func warning() {
        notification.notificationOccurred(.warning)
    }
    
    /// Error notification - for failed actions
    func error() {
        notification.notificationOccurred(.error)
    }
    
    // MARK: - App-Specific Haptics
    
    /// Swipe keep action - positive feedback
    func swipeKeep() {
        success()
    }
    
    /// Swipe delete action - warning feedback
    func swipeDelete() {
        warning()
    }
    
    /// Swipe skip action - light feedback
    func swipeSkip() {
        lightTap()
    }
    
    /// Card appeared - subtle feedback
    func cardAppeared() {
        softTap()
    }
    
    /// Button pressed - standard feedback
    func buttonPressed() {
        mediumTap()
    }
    
    /// Filter changed - selection feedback
    func filterChanged() {
        selectionChanged()
    }
    
    /// Deletion confirmed - heavy feedback
    func deletionConfirmed() {
        heavyTap()
    }
    
    /// Onboarding slide changed
    func onboardingSlideChanged() {
        selectionChanged()
    }
    
    /// Onboarding completed
    func onboardingCompleted() {
        success()
    }
    
    /// Progressive swipe feedback based on progress (0.0 to 1.0)
    func progressiveSwipe(progress: CGFloat) {
        let clampedProgress = min(max(progress, 0), 1)
        
        if clampedProgress < 0.33 {
            lightImpact.impactOccurred(intensity: 0.5)
        } else if clampedProgress < 0.66 {
            mediumImpact.impactOccurred(intensity: 0.7)
        } else {
            heavyImpact.impactOccurred(intensity: 1.0)
        }
    }
    
    /// Threshold crossed during swipe
    func thresholdCrossed(level: Int) {
        switch level {
        case 1:
            lightImpact.impactOccurred(intensity: 0.5)
        case 2:
            mediumImpact.impactOccurred(intensity: 0.7)
        case 3:
            heavyImpact.impactOccurred(intensity: 1.0)
        default:
            break
        }
    }
}

// MARK: - SwiftUI Convenience
import SwiftUI

extension View {
    /// Add haptic feedback to a tap gesture
    func hapticTap(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded { _ in
                HapticManager.shared.impact(style: style)
            }
        )
    }
}
