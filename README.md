# Clash of Clans Tracker  
**CSE 335 Class Project - Phase 0**  
**Team Members**: Dat Nguyen & Khanh Toan Pham  

## Project Overview  
The Clash of Clans Tracker is a mobile app that helps players analyze opponents/clans by tracking:  
- Player/clan stats (trophies, war participation)  
- Activity patterns (peak play times, time zones)  
- League history and trophy progression  

**Goal**: Give players a competitive edge through behavioral insights.  

## Technical Implementation  
### Requirements  
1. **Persistent Data (SwiftData)**  
   - Stores saved player tags, favorites, and historical stats.  

2. **MVVM Architecture (SwiftUI)**  
   - Model: Data from Clash of Clans API  
   - View: SwiftUI screens (player profiles, stats)  
   - ViewModel: Processes API data for display  

3. **Web API Integration**  
   - Fetches data from:  
     - Official [Clash of Clans API](https://developer.clashofclans.com/) 

4. **MapKit**  
   - Shows player time zones/locations (if shared)  

5. **TableView**  
   - Displays stats/lists using SwiftUI `List`  

## Setup  
1. Clone the repository:  
   ```bash
   git clone https://github.com/yourusername/clash-tracker.git
   
2. Repplace the Asset file with this one
    https://drive.google.com/file/d/1ZiW6_FiU8lCmrEOmyVebJ38kvfF2-77u/view?usp=drive_link


