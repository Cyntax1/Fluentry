//
//  HapticFeedback.swift
//  Fluentry
//
//  Haptic feedback utilities following Apple HIG
//

import UIKit
import SwiftUI

enum HapticFeedback {
    
    /// Success haptic (e.g., correct answer, task completed)
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    /// Error haptic (e.g., wrong answer, validation failed)
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    /// Warning haptic (e.g., low battery, unsaved changes)
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    /// Light impact (e.g., button tap, selection change)
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    /// Medium impact (e.g., card swipe, modal dismiss)
    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    /// Heavy impact (e.g., important action, deletion)
    static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    /// Selection feedback (e.g., scrolling through picker, tab change)
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// SwiftUI View extension for easy haptic integration
extension View {
    func hapticFeedback(_ type: HapticType, onTap: Bool = true) -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded {
                switch type {
                case .success:
                    HapticFeedback.success()
                case .error:
                    HapticFeedback.error()
                case .warning:
                    HapticFeedback.warning()
                case .light:
                    HapticFeedback.light()
                case .medium:
                    HapticFeedback.medium()
                case .heavy:
                    HapticFeedback.heavy()
                case .selection:
                    HapticFeedback.selection()
                }
            }
        )
    }
}

enum HapticType {
    case success, error, warning, light, medium, heavy, selection
}
