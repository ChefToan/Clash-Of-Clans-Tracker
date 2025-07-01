// APIService.swift
import Foundation
import Combine
import SwiftUI

class APIService {
    // Add this method to the existing APIService.swift file
    func getPlayerAsync(tag: String) async throws -> Player {
        // Ensure tag has # and is properly URL encoded
        let formattedTag = tag.hasPrefix("#") ? tag : "#\(tag)"
        guard let encodedTag = formattedTag.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw NSError(
                domain: "APIService",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Invalid player tag format"]
            )
        }
        
        // Create URL for the ChefToan API with query parameter
        guard let url = URL(string: "https://api.cheftoan.com/player?tag=\(encodedTag)") else {
            throw NSError(
                domain: "APIService",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]
            )
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        // Use async/await to make the request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(
                domain: "APIService",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Invalid response"]
            )
        }
        
        if httpResponse.statusCode == 200 {
            // For debugging purposes
            if let jsonString = String(data: data, encoding: .utf8) {
                print("ChefToan API Response: \(jsonString)")
            }
            
            // Decode the player data
            return try JSONDecoder().decode(Player.self, from: data)
        } else {
            // Try to parse error message from JSON
            if let errorDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = errorDict["message"] as? String {
                throw NSError(
                    domain: "ChefToanAPI",
                    code: httpResponse.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: message]
                )
            } else {
                throw NSError(
                    domain: "ChefToanAPI",
                    code: httpResponse.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: "Unknown API error"]
                )
            }
        }
    }
    
    
    // MARK: - Player Data from My API (ChefToan API)
    
    func getPlayer(tag: String) -> AnyPublisher<Player, Error> {
        // Ensure tag has # and is properly URL encoded
        let formattedTag = tag.hasPrefix("#") ? tag : "#\(tag)"
        guard let encodedTag = formattedTag.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            let error = NSError(
                domain: "APIService",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Invalid player tag format"]
            )
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        // Create URL for the ChefToan API with query parameter
        guard let url = URL(string: "https://api.cheftoan.com/player?tag=\(encodedTag)") else {
            let error = NSError(
                domain: "APIService",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]
            )
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { (data: Data, response: URLResponse) in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NSError(
                        domain: "APIService",
                        code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "Invalid response"]
                    )
                }
                
                if httpResponse.statusCode == 200 {
                    // For debugging purposes
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("ChefToan API Response: \(jsonString)")
                    }
                    return data
                } else {
                    // Try to parse error message from JSON
                    if let errorDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let message = errorDict["message"] as? String {
                        throw NSError(
                            domain: "ChefToanAPI",
                            code: httpResponse.statusCode,
                            userInfo: [NSLocalizedDescriptionKey: message]
                        )
                    } else {
                        throw NSError(
                            domain: "ChefToanAPI",
                            code: httpResponse.statusCode,
                            userInfo: [NSLocalizedDescriptionKey: "Unknown API error"]
                        )
                    }
                }
            }
            .decode(type: Player.self, decoder: JSONDecoder())
            .catch { error -> AnyPublisher<Player, Error> in
                print("Error fetching player data: \(error.localizedDescription)")
                return Fail(error: error).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Player Rankings from ClashKing API
    
    func getPlayerRankings(tag: String) -> AnyPublisher<PlayerRankings, Error> {
        // Remove the # from the tag for ClashKing API
        let tagWithoutHash = tag.replacingOccurrences(of: "#", with: "")
        guard let url = URL(string: "https://api.clashk.ing/player/\(tagWithoutHash)/legends") else {
            let error = NSError(
                domain: "APIService",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Invalid URL for rankings API"]
            )
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { (data: Data, response: URLResponse) in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NSError(
                        domain: "APIService",
                        code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "Invalid response"]
                    )
                }
                
                if httpResponse.statusCode == 200 {
                    // Convert data to string for debugging
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("ClashKing API Response: \(jsonString)")
                    }
                    
                    // Try to parse using JSONSerialization first to understand structure
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("JSON Parsed: \(json)")
                        
                        // Extract the rankings part directly
                        if let rankings = json["rankings"] as? [String: Any] {
                            let localRank = rankings["local_rank"] as? Int
                            let globalRank = rankings["global_rank"] as? Int
                            let countryCode = rankings["country_code"] as? String ?? "US"
                            let countryName = rankings["country_name"] as? String ?? "United States"
                            let streak = json["streak"] as? Int ?? 0
                            
                            // Create PlayerRankings object manually
                            let rankingsObj = PlayerRankings(
                                tag: "#\(tagWithoutHash)",
                                countryCode: countryCode,
                                countryName: countryName,
                                localRank: localRank,
                                builderGlobalRank: rankings["builder_global_rank"] as? Int,
                                builderLocalRank: rankings["builder_local_rank"] as? Int,
                                globalRank: globalRank,
                                streak: streak
                            )
                            
                            return rankingsObj
                        }
                    }
                    
                    // If we couldn't parse manually, try the regular decode
                    return try JSONDecoder().decode(ClashKingResponse.self, from: data).rankings
                } else {
                    throw NSError(
                        domain: "ClashKingAPI",
                        code: httpResponse.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to fetch rankings data"]
                    )
                }
            }
            .catch { error -> AnyPublisher<PlayerRankings, Error> in
                print("Error with ClashKing API: \(error.localizedDescription)")
                
                // Create a fallback value
                return Just(PlayerRankings(
                    tag: "#\(tagWithoutHash)",
                    countryCode: "US",
                    countryName: "United States",
                    localRank: 0,
                    builderGlobalRank: nil,
                    builderLocalRank: nil,
                    globalRank: 0,
                    streak: 0
                ))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Chart Image from external server
    
    func getPlayerChartImageURL(tag: String) -> URL? {
        // Format the tag for the URL - remove # if it exists, then properly encode for query parameter
        let formattedTag = tag.replacingOccurrences(of: "#", with: "").uppercased()
        let tagWithHash = "#\(formattedTag)"
        
        guard let encodedTag = tagWithHash.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        
        return URL(string: "https://api.cheftoan.com/chart?tag=\(encodedTag)")
    }
    
    // MARK: - Loading League and Clan Icons
    
    func loadImage(from urlString: String) -> AnyPublisher<UIImage?, Error> {
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { data, response -> UIImage? in
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return UIImage(data: data)
            }
            .eraseToAnyPublisher()
    }
}

// Simple struct to hold ClashKing API response
struct ClashKingResponse: Codable {
    let rankings: PlayerRankings
    let streak: Int
}

// Model for PlayerRankings
public struct PlayerRankings: Codable {
    public let tag: String
    public let countryCode: String
    public let countryName: String
    public let localRank: Int?
    public let builderGlobalRank: Int?
    public let builderLocalRank: Int?
    public let globalRank: Int?
    public let streak: Int
    
    enum CodingKeys: String, CodingKey {
        case tag
        case countryCode = "country_code"
        case countryName = "country_name"
        case localRank = "local_rank"
        case builderGlobalRank = "builder_global_rank"
        case builderLocalRank = "builder_local_rank"
        case globalRank = "global_rank"
        case streak
    }
    
    // Custom initializer for creating from scratch or fallback
    init(tag: String, countryCode: String, countryName: String,
         localRank: Int?, builderGlobalRank: Int?, builderLocalRank: Int?,
         globalRank: Int?, streak: Int = 0) {
        self.tag = tag
        self.countryCode = countryCode
        self.countryName = countryName
        self.localRank = localRank
        self.builderGlobalRank = builderGlobalRank
        self.builderLocalRank = builderLocalRank
        self.globalRank = globalRank
        self.streak = streak
    }
}
