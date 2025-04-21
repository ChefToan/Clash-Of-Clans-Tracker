// TrophyProgressionView.swift
import SwiftUI

struct TrophyProgressionView: View {
    let player: Player
    private let apiService = APIService()
    @State private var chartURL: URL? = nil
    @State private var cachedImage: UIImage? = nil // Add cached image
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @State private var showFullScreenImage = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("TROPHY PROGRESSION")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(Color.black.opacity(0.3))
            
            // Content
            ZStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                        .frame(height: 180) // Reduced minimum height when loading
                } else if let chartImage = cachedImage {
                    // Use cached image directly
                    Image(uiImage: chartImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                showFullScreenImage = true
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                } else if let url = chartURL {
                    // Chart image display with caching
                    ZStack {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.5)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.3)) {
                                            showFullScreenImage = true
                                        }
                                    }
                                    .onAppear {
                                        // Cache the UIImage when it loads successfully
                                        if let uiImage = phase.image?.asUIImage() {
                                            self.cachedImage = uiImage
                                        }
                                    }
                            case .failure:
                                VStack {
                                    Image(systemName: "chart.line.downtrend.xyaxis")
                                        .font(.system(size: 50))
                                        .foregroundColor(.gray)
                                    Text("Failed to load chart")
                                        .foregroundColor(.gray)
                                    
                                    Button(action: {
                                        loadChart()
                                    }) {
                                        Text("Retry")
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 8)
                                            .background(Constants.blue)
                                            .foregroundColor(.white)
                                            .cornerRadius(Constants.buttonCornerRadius)
                                    }
                                    .padding(.top, 10)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 180)
                            @unknown default:
                                Text("Unknown error")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .contentShape(Rectangle())
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                } else if let error = errorMessage {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.yellow)
                        Text(error)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: {
                            loadChart()
                        }) {
                            Text("Retry")
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(Constants.blue)
                                .foregroundColor(.white)
                                .cornerRadius(Constants.buttonCornerRadius)
                        }
                        .padding(.top, 10)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Constants.bgCard)
        }
        .background(Constants.bgDark)
        .cornerRadius(Constants.cornerRadius)
        .onAppear {
            loadChart()
        }
        .fullScreenCover(isPresented: $showFullScreenImage) {
            if let image = cachedImage {
                // Use the cached image directly
                EnhancedImageViewer(cachedImage: image, isPresented: $showFullScreenImage)
                    .edgesIgnoringSafeArea(.all)
            } else if let url = chartURL {
                // Fallback to URL if cached image not available
                EnhancedImageViewer(imageURL: url, isPresented: $showFullScreenImage)
                    .edgesIgnoringSafeArea(.all)
            }
        }
    }
    
    private func loadChart() {
        isLoading = true
        errorMessage = nil
        cachedImage = nil // Reset cached image when loading a new chart
        
        DispatchQueue.main.async {
            if let url = apiService.getPlayerChartImageURL(tag: player.tag) {
                self.chartURL = url
                
                // Prefetch and cache the image
                URLSession.shared.dataTask(with: url) { data, response, error in
                    if let data = data, let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self.cachedImage = image
                            self.isLoading = false
                        }
                    } else {
                        DispatchQueue.main.async {
                            // We'll still try with AsyncImage as fallback
                            self.isLoading = false
                        }
                    }
                }.resume()
            } else {
                self.errorMessage = "Invalid player tag format"
                self.isLoading = false
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        controller.completionWithItemsHandler = { _, _, _, _ in
            isPresented = false
        }
        
        // Prevents "already presenting" errors
        let hostController = UIViewController()
        hostController.view.backgroundColor = .clear
        hostController.modalPresentationStyle = .overFullScreen
        
        return hostController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Present the activity controller from our host controller
        if isPresented, uiViewController.presentedViewController == nil {
            // Find the window scene and root controller properly
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootController = windowScene.windows.first?.rootViewController else {
                return
            }
            
            // Get the topmost presented controller
            var topController = rootController
            while let presented = topController.presentedViewController {
                topController = presented
            }
            
            // Present from our host controller which is presented from the topmost controller
            DispatchQueue.main.async {
                topController.present(uiViewController, animated: true)
                if let activityViewController = self.createActivityViewController() {
                    uiViewController.present(activityViewController, animated: true)
                }
            }
        }
    }
    
    private func createActivityViewController() -> UIActivityViewController? {
        let activityVC = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        activityVC.completionWithItemsHandler = { _, _, _, _ in
            isPresented = false
        }
        
        // On iPad, set the popover presentation
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = UIView()
            popover.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2,
                                      y: UIScreen.main.bounds.height / 2,
                                      width: 0,
                                      height: 0)
            popover.permittedArrowDirections = []
        }
        
        return activityVC
    }
}

struct ImageActionSheet: UIViewControllerRepresentable {
    var image: UIImage
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet
        )
        
        // Save to Photos
        controller.addAction(UIAlertAction(title: "Save to Photos", style: .default) { _ in
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            HapticManager.shared.successFeedback()
            isPresented = false
        })
        
        // Copy
        controller.addAction(UIAlertAction(title: "Copy", style: .default) { _ in
            UIPasteboard.general.image = image
            HapticManager.shared.successFeedback()
            isPresented = false
        })
        
        // Cancel
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            isPresented = false
        })
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Nothing to update
    }
}
