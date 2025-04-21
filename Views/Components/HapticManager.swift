// HapticManager.swift
import SwiftUI
import UIKit

class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    // For selection feedback (menu appearance)
    func selectionFeedback() {
        let selectionFeedbackGenerator = UISelectionFeedbackGenerator()
        selectionFeedbackGenerator.prepare()
        selectionFeedbackGenerator.selectionChanged()
    }
    
    // For success feedback (when copying or saving)
    func successFeedback() {
        let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
        notificationFeedbackGenerator.prepare()
        notificationFeedbackGenerator.notificationOccurred(.success)
    }
    
    // For error feedback
    func errorFeedback() {
        let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
        notificationFeedbackGenerator.prepare()
        notificationFeedbackGenerator.notificationOccurred(.error)
    }
    
    // For light impact feedback
    func lightImpactFeedback() {
        let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        impactFeedbackGenerator.prepare()
        impactFeedbackGenerator.impactOccurred()
    }
    
    // For medium impact feedback
    func mediumImpactFeedback() {
        let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        impactFeedbackGenerator.prepare()
        impactFeedbackGenerator.impactOccurred()
    }
    
    // For heavy impact feedback
    func heavyImpactFeedback() {
        let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedbackGenerator.prepare()
        impactFeedbackGenerator.impactOccurred()
    }
}
