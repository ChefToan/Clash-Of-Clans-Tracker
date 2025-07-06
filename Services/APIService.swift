// APIService.swift
import Foundation

class APIService {
    static let shared = APIService()
    
    private let baseURL = "https://api.cheftoan.com"
    private let cacheTimeout: TimeInterval = 300 // 5 minutes in seconds
    
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
    
    // Get player essentials with 5-minute caching
    func getPlayerEssentials(tag: String) async throws -> PlayerEssentials {
        let formattedTag = formatTag(tag)
        guard let url = URL(string: "\(baseURL)/player/essentials?tag=\(formattedTag)") else {
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
                let player = try JSONDecoder().decode(PlayerEssentials.self, from: cachedResponse.data)
                return player
            } catch {
                // If decoding fails, fetch fresh data
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
            
            do {
                let player = try JSONDecoder().decode(PlayerEssentials.self, from: data)
                return player
            } catch {
                print("Decoding error: \(error)")
                throw APIError.decodingError
            }
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
        let urlString = "\(baseURL)/chart?tag=\(formattedTag)&t=\(timestamp)"
        return URL(string: urlString)
    }
    
    // Force refresh by bypassing cache
    func refreshPlayerEssentials(tag: String) async throws -> PlayerEssentials {
        let formattedTag = formatTag(tag)
        guard let url = URL(string: "\(baseURL)/player/essentials?tag=\(formattedTag)") else {
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
            
            do {
                let player = try JSONDecoder().decode(PlayerEssentials.self, from: data)
                return player
            } catch {
                print("Decoding error: \(error)")
                throw APIError.decodingError
            }
        } catch {
            if error is APIError {
                throw error
            }
            throw APIError.networkError(error.localizedDescription)
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
            return "Failed to decode response"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}
