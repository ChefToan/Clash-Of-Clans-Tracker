// ImageLoaderView.swift
import SwiftUI
import Combine

class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    private var cancellable: AnyCancellable?
    private let apiService = APIService()
    
    func loadImage(from urlString: String?, placeholder: String) {
        // Reset the image
        self.image = nil
        
        // Cancel any previous request
        cancellable?.cancel()
        
        // Check if URL string is valid
        guard let urlString = urlString, !urlString.isEmpty else {
            return
        }
        
        // Load the image
        cancellable = apiService.loadImage(from: urlString)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Failed to load image: \(error.localizedDescription)")
                }
            }, receiveValue: { [weak self] image in
                self?.image = image
            })
    }
    
    deinit {
        cancellable?.cancel()
    }
}

struct RemoteImageView: View {
    @StateObject private var imageLoader = ImageLoader()
    let urlString: String?
    let placeholder: String
    let width: CGFloat
    let height: CGFloat
    
    init(urlString: String?, placeholder: String, width: CGFloat = 80, height: CGFloat = 80) {
        self.urlString = urlString
        self.placeholder = placeholder
        self.width = width
        self.height = height
    }
    
    var body: some View {
        ZStack {
            if let image = imageLoader.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: width, height: height)
            } else {
                // Placeholder
                ZStack {
                    Rectangle()
                        .fill(Color.purple.opacity(0.5))
                        .frame(width: width, height: height)
                        .cornerRadius(10)
                        
                    VStack {
                        Text(placeholder)
                            .font(.caption)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
        .onAppear {
            imageLoader.loadImage(from: urlString, placeholder: placeholder)
        }
    }
}

// League Icon View
struct LeagueIconView: View {
    let league: League?
    let size: CGFloat
    
    init(league: League?, size: CGFloat = 80) {
        self.league = league
        self.size = size
    }
    
    var body: some View {
        if let league = league {
            RemoteImageView(
                urlString: league.iconUrls?.small,
                placeholder: "League Icon",
                width: size,
                height: size
            )
        } else {
            // Placeholder if league is nil
            ZStack {
                Rectangle()
                    .fill(Color.purple.opacity(0.5))
                    .frame(width: size, height: size)
                    .cornerRadius(10)
                    
                VStack {
                    Text("League")
                        .font(.caption)
                    Text("Icon")
                        .font(.caption)
                }
                .foregroundColor(.white)
            }
        }
    }
}

// Clan Badge View
struct ClanBadgeView: View {
    let clan: PlayerClan?
    let size: CGFloat
    
    init(clan: PlayerClan?, size: CGFloat = 80) {
        self.clan = clan
        self.size = size
    }
    
    var body: some View {
        if let clan = clan {
            RemoteImageView(
                urlString: clan.badgeUrls?.small,
                placeholder: "Clan Badge",
                width: size,
                height: size
            )
        } else {
            // Placeholder if clan is nil
            ZStack {
                Rectangle()
                    .fill(Color.purple.opacity(0.5))
                    .frame(width: size, height: size)
                    .cornerRadius(10)
                    
                VStack {
                    Text("Clan")
                        .font(.caption)
                    Text("Badge")
                        .font(.caption)
                }
                .foregroundColor(.white)
            }
        }
    }
}

// Town Hall Icon View (Placeholder for now)
struct TownHallIconView: View {
    let level: Int
    let size: CGFloat
    
    init(level: Int, size: CGFloat = 100) {
        self.level = level
        self.size = size
    }
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color(hex: "#765234"))
                .frame(width: size, height: size * 0.6)
                .cornerRadius(5)
            
            Text("TH \(level)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
    }
}
