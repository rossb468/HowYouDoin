//
//  HapticHelper.swift
//  HowYouDoing?
//

import UIKit

/// Triggers a simple haptic feedback tap.
func triggerHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
    let generator = UIImpactFeedbackGenerator(style: style)
    generator.prepare()
    generator.impactOccurred()
}
