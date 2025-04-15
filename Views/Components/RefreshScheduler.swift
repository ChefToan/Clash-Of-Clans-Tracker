// RefreshScheduler.swift
import Foundation

class RefreshScheduler {
    static let shared = RefreshScheduler()
    
    // The profile resets at 5 AM UTC
    private let resetHourUTC = 5
    
    // Get the next reset time in UTC
    func getNextResetTimeUTC() -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        
        let now = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = resetHourUTC
        components.minute = 0
        components.second = 0
        
        guard var resetDate = calendar.date(from: components) else {
            return now // Fallback
        }
        
        // If we're past today's reset time, get tomorrow's
        if now > resetDate {
            resetDate = calendar.date(byAdding: .day, value: 1, to: resetDate)!
        }
        
        return resetDate
    }
    
    // Format the reset time for display
    func formatNextResetTime() -> String {
        let nextReset = getNextResetTimeUTC()
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        
        // Use the user's timezone for formatting
        let userTimezoneID = UserDefaults.standard.string(forKey: "selectedTimezone") ?? TimeZone.current.identifier
        if let userTimezone = TimeZone(identifier: userTimezoneID) {
            formatter.timeZone = userTimezone
        }
        
        return formatter.string(from: nextReset)
    }
    
    // Get formatted 5 AM UTC in user's timezone
    func get5AMUTCInUserTimezone() -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        
        // Use today's date with 5 AM
        let today = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: today)
        components.hour = resetHourUTC
        components.minute = 0
        
        guard let utcTime = calendar.date(from: components) else {
            return "5:00 AM UTC"
        }
        
        // Format in user's timezone
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        
        let userTimezoneID = UserDefaults.standard.string(forKey: "selectedTimezone") ?? TimeZone.current.identifier
        if let userTimezone = TimeZone(identifier: userTimezoneID) {
            formatter.timeZone = userTimezone
        }
        
        return formatter.string(from: utcTime)
    }
    
    // Schedule the next refresh
    func scheduleNextRefresh(completion: @escaping () -> Void) {
        // Calculate time until next reset
        let nextResetUTC = getNextResetTimeUTC()
        let timeUntilReset = nextResetUTC.timeIntervalSinceNow
        
        // Schedule the refresh
        DispatchQueue.main.asyncAfter(deadline: .now() + timeUntilReset) {
            // Execute the refresh
            completion()
            
            // Schedule the next refresh
            self.scheduleNextRefresh(completion: completion)
        }
    }
    
    // Check if it's time to refresh based on last refresh time
    func shouldRefresh() -> Bool {
        // Get the last refresh time
        guard let lastRefreshTime = UserDefaults.standard.object(forKey: "lastProfileRefreshTime") as? Date else {
            // If never refreshed, should refresh
            return true
        }
        
        // Create UTC calendar
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        
        // Get today's reset time in UTC
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = resetHourUTC
        components.minute = 0
        components.second = 0
        
        guard let todayResetTime = calendar.date(from: components) else {
            return true
        }
        
        // Should refresh if the last refresh was before today's reset
        return lastRefreshTime < todayResetTime
    }
    
    // Update the last refresh time
    func updateLastRefreshTime() {
        UserDefaults.standard.set(Date(), forKey: "lastProfileRefreshTime")
    }
}
