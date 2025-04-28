// TrophyProgressionView.swift
import SwiftUI
import Photos

struct TrophyProgressionView: View {
    let player: Player
    private let apiService = APIService()
    @State private var chartURL: URL? = nil
    @State private var cachedImage: UIImage? = nil
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @State private var showFullScreenImage = false
    @State private var showSaveSuccess = false
    @State private var showContextMenu = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("TROPHY PROGRESSION")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Constants.headerTextColor)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(Constants.headerBackground)
            
            // Content
            ZStack {
                // Fixed height container to maintain consistent size
                Rectangle()
                    .fill(Constants.bgCard)
                    .frame(height: 220)
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                } else if let chartImage = cachedImage {
                    // Use cached image directly
                    Image(uiImage: chartImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                showFullScreenImage = true
                            }
                        }
                        .onLongPressGesture {
                            // Trigger haptic feedback
                            HapticManager.shared.mediumImpactFeedback()
                            showContextMenu = true
                        }
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
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 220)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.3)) {
                                            showFullScreenImage = true
                                        }
                                    }
                                    .onLongPressGesture {
                                        // Trigger haptic feedback
                                        HapticManager.shared.mediumImpactFeedback()
                                        
                                        // Cache the image if not already done
                                        if let uiImage = phase.image?.asUIImage() {
                                            self.cachedImage = uiImage
                                        }
                                        
                                        showContextMenu = true
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
                                        HapticManager.shared.lightImpactFeedback()
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
                                .frame(height: 180) // Ensure consistent height
                            @unknown default:
                                Text("Unknown error")
                                    .foregroundColor(.gray)
                                    .frame(height: 180) // Ensure consistent height
                            }
                        }
                    }
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
                            HapticManager.shared.lightImpactFeedback()
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
                    .frame(height: 180) // Ensure consistent height
                }
                
                // Show context menu when long press is detected
                if showContextMenu, let image = cachedImage {
                    CustomContextMenu(image: image, isPresented: $showContextMenu)
                        .zIndex(100)
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
                EnhancedImageViewer(
                    cachedImage: image,
                    isPresented: $showFullScreenImage
                )
                .edgesIgnoringSafeArea(.all)
            } else if let url = chartURL {
                // Fallback to URL if cached image not available
                EnhancedImageViewer(
                    imageURL: url,
                    isPresented: $showFullScreenImage
                )
                .edgesIgnoringSafeArea(.all)
            }
        }
        .alert("Image Saved", isPresented: $showSaveSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("The chart image has been saved to your photo library.")
        }
    }
    
    private func loadChart() {
        isLoading = true
        errorMessage = nil
        
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
    
    private func saveImageToPhotoLibrary(_ image: UIImage) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                print("Photo library access denied")
                return
            }
            
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            
            // Show success alert on the main thread
            DispatchQueue.main.async {
                HapticManager.shared.successFeedback()
                showSaveSuccess = true
            }
        }
    }
}

// Extension to convert SwiftUI Image to UIImage
extension Image {
    func asUIImage() -> UIImage? {
        let controller = UIHostingController(rootView: self)
        if let view = controller.view {
            let contentSize = view.intrinsicContentSize
            view.bounds = CGRect(origin: .zero, size: contentSize)
            view.backgroundColor = .clear
            
            let renderer = UIGraphicsImageRenderer(size: contentSize)
            return renderer.image { _ in
                view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
            }
        }
        return nil
    }
}
