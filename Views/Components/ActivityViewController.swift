// ActivityViewController.swift - With proper image preview
import SwiftUI
import UIKit

// Custom UIActivityItemProvider to ensure image displays properly in preview
class ImageActivityItemProvider: UIActivityItemProvider, @unchecked Sendable {
    private let image: UIImage
    
    init(image: UIImage) {
        self.image = image
        super.init(placeholderItem: image)
    }
    
    override var item: Any {
        return image
    }
}

struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    
    // Creates a proper activity view controller with correctly configured item providers
    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityViewController>) -> UIActivityViewController {
        // Process image items to use ImageActivityItemProvider
        let processedItems = activityItems.map { item -> Any in
            if let image = item as? UIImage {
                return ImageActivityItemProvider(image: image)
            }
            return item
        }
        
        let controller = UIActivityViewController(
            activityItems: processedItems,
            applicationActivities: applicationActivities
        )
        
        // Fix for iPad
        if let popover = controller.popoverPresentationController {
            popover.sourceView = UIView()
            popover.permittedArrowDirections = []
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityViewController>) {
        // Nothing to update
    }
}

extension CustomContextMenu {
    // Save image to photo library with haptic feedback
    private func saveToPhotos() {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        // Trigger success haptic
        HapticManager.shared.successFeedback()
        isPresented = false
    }
    
    // Copy image to clipboard with haptic feedback
    private func copyImage() {
        UIPasteboard.general.image = image
        // Trigger success haptic
        HapticManager.shared.successFeedback()
        isPresented = false
    }
}
