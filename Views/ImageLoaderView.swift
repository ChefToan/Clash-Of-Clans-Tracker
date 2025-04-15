// ImageLoaderView.swift
import SwiftUI
import Combine

class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false
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
        
        // Set loading state to true
        isLoading = true
        
        // Load the image
        cancellable = apiService.loadImage(from: urlString)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    print("Failed to load image: \(error.localizedDescription)")
                }
                self?.isLoading = false
            }, receiveValue: { [weak self] image in
                self?.image = image
                self?.isLoading = false
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
            } else if imageLoader.isLoading {
                // Loading indicator while fetching image
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.9)
                    .frame(width: width, height: height)
            } else {
                // Image placeholder from assets
                if let placeholderImage = UIImage(named: placeholder) {
                    Image(uiImage: placeholderImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: width, height: height)
                } else {
                    // Fallback placeholder if image not found
                    ZStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: width, height: height)
                            .cornerRadius(10)
                        
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
                placeholder: "league_\(league.name.lowercased().replacingOccurrences(of: " ", with: "_"))",
                width: size,
                height: size
            )
        } else {
            if let leagueImage = UIImage(named: "league_unranked") {
                Image(uiImage: leagueImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
            } else {
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
                placeholder: "clan_badge",
                width: size,
                height: size
            )
        } else {
            if let clanImage = UIImage(named: "clan_default") {
                Image(uiImage: clanImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
            } else {
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
}

// Town Hall Icon View
struct TownHallIconView: View {
    let level: Int
    let size: CGFloat
    
    init(level: Int, size: CGFloat = 100) {
        self.level = level
        self.size = size
    }
    
    var body: some View {
        if let thImage = UIImage(named: "th\(level)") {
            Image(uiImage: thImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
        } else {
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
}

// Unit Icon View - For use in ItemView
struct UnitIconView: View {
    let item: PlayerItem
    let size: CGFloat
    
    init(item: PlayerItem, size: CGFloat = 40) {
        self.item = item
        self.size = size
    }
    
    var body: some View {
        if let unitImage = UIImage(named: getUnitImageName(item)) {
            Image(uiImage: unitImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
        } else {
            // Fallback placeholder with unit name initial
            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: size, height: size)
                    .cornerRadius(Constants.innerCornerRadius/2)
                
                Text(item.name.prefix(1))
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
    }
    
    private func getUnitImageName(_ item: PlayerItem) -> String {
        let name = item.name.lowercased().replacingOccurrences(of: " ", with: "_")
        
        // Determine unit type
        if item.name.contains("Super") {
            return "super_\(name.replacingOccurrences(of: "super_", with: ""))"
        } else if isDarkElixirTroop(item) {
            return "dark_\(name)"
        } else if isSiegeMachine(item) {
            return "siege_\(name)"
        } else if isHero(item) {
            // Special case for Minion Prince
            if item.name.lowercased() == "minion prince" {
                return "hero_minion_prince"
            }
            return "hero_\(name)"
        } else if isHeroEquipment(item) {
            return "equip_\(name)"
        } else if isSpell(item) {
            return getSpellImageName(item)
        } else if isPet(item) {
            return "pet_\(name)"
        } else {
            // Regular troop
            return "troop_\(name)"
        }
    }
    
    private func isPet(_ item: PlayerItem) -> Bool {
        let petNames = [
            "L.A.S.S.I", "Electro Owl", "Mighty Yak", "Unicorn",
            "Phoenix", "Poison Lizard", "Diggy", "Frosty",
            "Spirit Fox", "Angry Jelly", "Sneezy"
        ]
        
        return petNames.contains(item.name)
    }
    
    private func getSpellImageName(_ item: PlayerItem) -> String {
        let baseSpellName = item.name.lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "_spell", with: "")
        
        // Check if it's a dark spell
        if isDarkSpell(item) {
            return "spell_\(baseSpellName)_spell"
        }
        
        // Return standard spell name format
        return "spell_\(baseSpellName)"
    }
    
    // Helper functions
    private func isDarkElixirTroop(_ item: PlayerItem) -> Bool {
        let darkTroopNames = [
            "minion", "hog", "valkyrie", "golem", "witch",
            "lava", "bowler", "ice golem", "headhunter"
        ]
        
        return darkTroopNames.contains { item.name.lowercased().contains($0) }
    }
    
    private func isSiegeMachine(_ item: PlayerItem) -> Bool {
        return item.name.contains("Wall Wrecker") ||
               item.name.contains("Battle Blimp") ||
               item.name.contains("Stone Slammer") ||
               item.name.contains("Siege Barracks") ||
               item.name.contains("Log Launcher") ||
               item.name.contains("Flame Flinger") ||
               item.name.contains("Battle Drill")
    }
    
    private func isHero(_ item: PlayerItem) -> Bool {
        return item.name.contains("King") ||
               item.name.contains("Queen") ||
               item.name.contains("Warden") ||
               item.name.contains("Champion") ||
               item.name.contains("Minion Prince")
    }
    
    private func isHeroEquipment(_ item: PlayerItem) -> Bool {
        return item.village == "heroEquipment"
    }
    
    private func isSpell(_ item: PlayerItem) -> Bool {
        return item.village == "spells" ||
               item.name.contains("Spell")
    }
    
    private func isDarkSpell(_ item: PlayerItem) -> Bool {
        let darkSpellNames = [
            "poison", "earthquake", "haste", "skeleton", "bat"
        ]
        
        return darkSpellNames.contains { item.name.lowercased().contains($0) }
    }
}
