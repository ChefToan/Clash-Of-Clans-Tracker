// CustomContextMenu.swift
import SwiftUI

struct CustomContextMenu: View {
    var image: UIImage
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            // Dimming background overlay
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation {
                        isPresented = false
                    }
                }
            
            // Menu container
            VStack(spacing: 0) {
                Spacer()
                
                // Menu with rounded corners
                VStack(spacing: 0) {
                    // Action buttons
                    VStack(spacing: 0) {
                        // Save to Photos
                        ContextMenuItem(icon: "arrow.down.to.line", text: "Save to Photos") {
                            saveToPhotos()
                        }
                        
                        Divider().background(Color.gray.opacity(0.3))
                        
                        // Copy
                        ContextMenuItem(icon: "doc.on.doc", text: "Copy") {
                            copyImage()
                        }
                    }
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(13)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    
                    // Cancel button
                    Button(action: {
                        withAnimation {
                            isPresented = false
                        }
                    }) {
                        Text("Cancel")
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(13)
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
        }
        .transition(.opacity)
    }
    
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

// Individual context menu item
struct ContextMenuItem: View {
    let icon: String
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 30)
                    .foregroundColor(.blue)
                
                Text(text)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
    }
}
