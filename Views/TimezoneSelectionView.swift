// TimezoneSelectionView.swift
import SwiftUI
import MapKit
import CoreLocation

// MARK: - Location Manager

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    @Published var lastLocation: CLLocation?
    @Published var locationStatus: CLAuthorizationStatus?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        locationStatus = manager.authorizationStatus
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.lastLocation = location
        }
    }
}

// MARK: - Timezone Selection View

struct TimezoneSelectionView: View {
    @State private var selectedTimezone = TimeZone.current.identifier
    @State private var cameraPosition: MapCameraPosition
    @StateObject private var locationManager = LocationManager()
    
    let playerName: String
    let onContinue: () -> Void
    let onCancel: () -> Void
    
    // Common timezones for easier selection
    private let commonTimezones = [
        "UTC",
        "America/New_York",
        "America/Chicago",
        "America/Denver",
        "America/Los_Angeles",
        "Europe/London",
        "Europe/Paris",
        "Europe/Berlin",
        "Asia/Tokyo",
        "Asia/Shanghai",
        "Australia/Sydney",
        "Pacific/Auckland"
    ]
    
    init(playerName: String, onContinue: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.playerName = playerName
        self.onContinue = onContinue
        self.onCancel = onCancel
        
        // Initialize with a default camera position (fallback)
        self._cameraPosition = State(initialValue: .region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                span: MKCoordinateSpan(latitudeDelta: 60, longitudeDelta: 60)
            )
        ))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("Select Your Timezone")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
            
            VStack(spacing: 12) {
                Text("Setting up profile for \(playerName)")
                    .font(.headline)
                    .foregroundColor(Constants.blue)
                
                // Timezone selection container
                VStack(alignment: .leading, spacing: 15) {
                    Text("Timezone")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Picker("Select Timezone", selection: $selectedTimezone) {
                        ForEach(commonTimezones, id: \.self) { timezone in
                            Text(formatTimezone(timezone))
                                .tag(timezone)
                        }
                        Divider()
                        ForEach(TimeZone.knownTimeZoneIdentifiers.filter { !commonTimezones.contains($0) }.sorted(), id: \.self) { timezone in
                            Text(formatTimezone(timezone))
                                .tag(timezone)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.horizontal)
                    .frame(height: 44)
                    
                    Text("This will be used for attack timing and league season changes.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                        .lineLimit(2)
                }
                .padding(.vertical, 10)
                .background(Constants.bgCard)
                .cornerRadius(10)
                .padding(.horizontal)
                .frame(height: 150)
                
                // Map container
                VStack(alignment: .leading, spacing: 10) {
                    Text("Your Location")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ZStack {
                        Map(position: $cameraPosition) {
                            if let coordinate = locationManager.lastLocation?.coordinate {
                                Marker("Your Location", coordinate: coordinate)
                                    .tint(.red)
                            } else {
                                Marker("Timezone Location", coordinate: getTimezoneCoordinate())
                                    .tint(.red)
                            }
                        }
                    }
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)
                }
                .padding(.vertical, 10)
                .background(Constants.bgCard)
                .cornerRadius(10)
                .padding(.horizontal)
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 15) {
                    Button(action: onCancel) {
                        Text("Cancel")
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.3))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    Button(action: {
                        UserDefaults.standard.set(selectedTimezone, forKey: "selectedTimezone")
                        onContinue()
                    }) {
                        Text("Continue")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Constants.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
            .padding(.top, 8)
        }
        .background(Constants.bgDark)
        .onAppear {
            checkLocationAndUpdateMap()
        }
        .onChange(of: locationManager.lastLocation) { _, newLocation in
            if let location = newLocation {
                updateLocation(location)
            }
        }
        .onChange(of: selectedTimezone) { _, _ in
            updateMapRegion()
        }
    }
    
    // MARK: - Helper Functions
    
    private func formatTimezone(_ timezone: String) -> String {
        guard let tz = TimeZone(identifier: timezone) else { return timezone }
        let offsetSeconds = tz.secondsFromGMT()
        let hours = offsetSeconds / 3600
        let minutes = abs(offsetSeconds / 60) % 60
        
        let sign = hours >= 0 ? "+" : ""
        let minuteString = minutes > 0 ? ":\(String(format: "%02d", minutes))" : ""
        
        return "\(timezone.replacingOccurrences(of: "_", with: " ")) (GMT\(sign)\(hours)\(minuteString))"
    }
    
    private func checkLocationAndUpdateMap() {
        if let status = locationManager.locationStatus,
           (status == .authorizedWhenInUse || status == .authorizedAlways),
           let location = locationManager.lastLocation {
            updateLocation(location)
        } else {
            updateMapRegion()
        }
    }
    
    private func updateLocation(_ location: CLLocation) {
        // Center the map on the user’s actual location
        cameraPosition = .region(MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 30, longitudeDelta: 30)
        ))
        
        // Try to update the timezone based on reverse geocoding
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            guard error == nil,
                  let placemark = placemarks?.first,
                  let timezone = placemark.timeZone else {
                print("Geocoding error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            DispatchQueue.main.async {
                self.selectedTimezone = timezone.identifier
                self.updateMapRegion()
            }
        }
    }
    
    private func updateMapRegion() {
        // Always use the user’s actual location if available
        if let location = locationManager.lastLocation {
            cameraPosition = .region(MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 30, longitudeDelta: 30)
            ))
        } else {
            cameraPosition = .region(MKCoordinateRegion(
                center: getTimezoneCoordinate(),
                span: MKCoordinateSpan(latitudeDelta: 30, longitudeDelta: 30)
            ))
        }
    }
    
    private func getTimezoneCoordinate() -> CLLocationCoordinate2D {
        // Fallback coordinate: if no user location, try to approximate using the selected timezone
        if let location = locationManager.lastLocation {
            return location.coordinate
        }
        
        if let timezone = TimeZone(identifier: selectedTimezone) {
            let secondsFromGMT = Double(timezone.secondsFromGMT())
            let hoursFromGMT = secondsFromGMT / 3600
            let longitude = hoursFromGMT * 15.0
            
            var latitude: Double = 0
            let lowercasedTimezone = selectedTimezone.lowercased()
            
            if lowercasedTimezone.contains("north") || lowercasedTimezone.contains("america") || lowercasedTimezone.contains("europe") {
                latitude = 40.0
            } else if lowercasedTimezone.contains("south") {
                latitude = -30.0
            } else if lowercasedTimezone.contains("australia") || lowercasedTimezone.contains("pacific") {
                latitude = -25.0
            } else if lowercasedTimezone.contains("asia") {
                latitude = 35.0
            } else if lowercasedTimezone.contains("africa") {
                latitude = 0.0
            }
            
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        
        return CLLocationCoordinate2D(latitude: 0, longitude: 0)
    }
}
