// APIService.swift
import Foundation

class APIService {
    static let shared = APIService()
    
    private let baseURL = "https://api.cheftoan.com"
    private let cacheTimeout: TimeInterval = 300 // 5 minutes in seconds
    
    // API version configuration
    // Using new API structure with /clash-of-clans/ prefix
    // Endpoints: /clash-of-clans/player/essentials and /clash-of-clans/chart
    private let useNewAPIStructure = true
    
    private lazy var cache: URLCache = {
        // Create a custom cache with 5-minute expiration
        return URLCache(
            memoryCapacity: 10 * 1024 * 1024,  // 10 MB
            diskCapacity: 50 * 1024 * 1024,     // 50 MB
            diskPath: "clash_api_cache"
        )
    }()
    
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.urlCache = cache
        config.requestCachePolicy = .useProtocolCachePolicy
        config.timeoutIntervalForRequest = 30
        return URLSession(configuration: config)
    }()
    
    private init() {}
    
    // Helper methods to build correct API URLs
    private func playerEssentialsURL(tag: String) -> String {
        let formattedTag = formatTag(tag)
        if useNewAPIStructure {
            return "\(baseURL)/clash-of-clans/player/essentials?tag=\(formattedTag)"
        } else {
            return "\(baseURL)/player/essentials?tag=\(formattedTag)"
        }
    }
    
    private func chartURL(tag: String) -> String {
        let formattedTag = formatTag(tag)
        if useNewAPIStructure {
            return "\(baseURL)/clash-of-clans/chart?tag=\(formattedTag)"
        } else {
            return "\(baseURL)/chart?tag=\(formattedTag)"
        }
    }
    
    // Get player essentials with 5-minute caching
    func getPlayerEssentials(tag: String) async throws -> PlayerEssentials {
        guard let url = URL(string: playerEssentialsURL(tag: tag)) else {
            throw APIError.invalidURL
        }
        
        // Check if we have a cached response that's still valid
        var request = URLRequest(url: url)
        request.cachePolicy = .returnCacheDataElseLoad
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Check cache validity
        if let cachedResponse = cache.cachedResponse(for: request),
           let userInfo = cachedResponse.userInfo,
           let cacheDate = userInfo["cacheDate"] as? Date,
           Date().timeIntervalSince(cacheDate) < cacheTimeout {
            // Cache is still valid, try to use it
            do {
                let player = try decodePlayerEssentials(from: cachedResponse.data)
                return player
            } catch {
                // If decoding fails, fetch fresh data
                print("Failed to decode cached data: \(error)")
            }
        }
        
        // Fetch fresh data
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                if httpResponse.statusCode == 404 {
                    throw APIError.playerNotFound
                }
                throw APIError.serverError(httpResponse.statusCode)
            }
            
            // Store the response with cache date
            let cachedResponse = CachedURLResponse(
                response: response,
                data: data,
                userInfo: ["cacheDate": Date()],
                storagePolicy: .allowed
            )
            cache.storeCachedResponse(cachedResponse, for: request)
            
            let player = try decodePlayerEssentials(from: data)
            return player
        } catch {
            if error is APIError {
                throw error
            }
            throw APIError.networkError(error.localizedDescription)
        }
    }
    
    // Get chart URL with cache busting
    func getChartURL(tag: String) -> URL? {
        let formattedTag = formatTag(tag)
        // Add timestamp to URL to bust cache every 5 minutes
        let timestamp = Int(Date().timeIntervalSince1970 / cacheTimeout) * Int(cacheTimeout)
        let urlString = "\(chartURL(tag: tag))&t=\(timestamp)"
        return URL(string: urlString)
    }
    
    // Fetch chart image
    func getChartImage(tag: String) async throws -> Data {
        guard let url = URL(string: chartURL(tag: tag)) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("image/png", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                if httpResponse.statusCode == 404 {
                    throw APIError.playerNotFound
                }
                throw APIError.serverError(httpResponse.statusCode)
            }
            
            return data
        } catch {
            if error is APIError {
                throw error
            }
            throw APIError.networkError(error.localizedDescription)
        }
    }
    
    // Force refresh by bypassing cache
    func refreshPlayerEssentials(tag: String) async throws -> PlayerEssentials {
        guard let url = URL(string: playerEssentialsURL(tag: tag)) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                if httpResponse.statusCode == 404 {
                    throw APIError.playerNotFound
                }
                throw APIError.serverError(httpResponse.statusCode)
            }
            
            // Store the fresh response with cache date
            let cachedResponse = CachedURLResponse(
                response: response,
                data: data,
                userInfo: ["cacheDate": Date()],
                storagePolicy: .allowed
            )
            cache.storeCachedResponse(cachedResponse, for: request)
            
            let player = try decodePlayerEssentials(from: data)
            return player
        } catch {
            if error is APIError {
                throw error
            }
            throw APIError.networkError(error.localizedDescription)
        }
    }
    
    // Enhanced decoding with better error handling
    private func decodePlayerEssentials(from data: Data) throws -> PlayerEssentials {
        let decoder = JSONDecoder()
        
        do {
            return try decoder.decode(PlayerEssentials.self, from: data)
        } catch let DecodingError.keyNotFound(key, context) {
            print("Decoding error - Key not found: \(key)")
            print("Context: \(context)")
            print("Coding path: \(context.codingPath)")
            
            // Print the raw JSON for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON response:")
                print(jsonString)
            }
            
            throw APIError.decodingError
        } catch let DecodingError.valueNotFound(value, context) {
            print("Decoding error - Value not found: \(value)")
            print("Context: \(context)")
            print("Coding path: \(context.codingPath)")
            
            // Print the raw JSON for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON response:")
                print(jsonString)
            }
            
            throw APIError.decodingError
        } catch let DecodingError.typeMismatch(type, context) {
            print("Decoding error - Type mismatch: \(type)")
            print("Context: \(context)")
            print("Coding path: \(context.codingPath)")
            
            // Print the raw JSON for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON response:")
                print(jsonString)
            }
            
            throw APIError.decodingError
        } catch {
            print("General decoding error: \(error)")
            
            // Print the raw JSON for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON response:")
                print(jsonString)
            }
            
            throw APIError.decodingError
        }
    }
    
    // Clear expired cache entries
    func clearExpiredCache() {
        cache.removeAllCachedResponses()
    }
    
    private func formatTag(_ tag: String) -> String {
        var formatted = tag.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        // Remove any # symbols first
        formatted = formatted.replacingOccurrences(of: "#", with: "")
        // Then add back a single # at the beginning
        formatted = "#\(formatted)"
        return formatted.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? formatted
    }
}

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case playerNotFound
    case serverError(Int)
    case decodingError
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .playerNotFound:
            return "Player not found. Please check the tag and try again."
        case .serverError(let code):
            return "Server error: \(code)"
        case .decodingError:
            return "Failed to decode response. This might be due to incomplete data from the server."
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}
