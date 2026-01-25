import SwiftUI

class RecommendationService {
    static let shared = RecommendationService()
    
    private let journeyService = JourneyService.shared
    private let favoritesService = FavoritesService.shared
    
    func generateRecommendations() -> [Recommendation] {
        var recommendations: [Recommendation] = []
        
        // Analyze journey history for frequent routes
        let journeys = journeyService.getHistory()
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        
        // Group journeys by time of day
        let timeBasedJourneys = journeys.filter { journey in
            let journeyHour = calendar.component(.hour, from: journey.timestamp)
            return abs(journeyHour - currentHour) <= 2 // Within 2 hours
        }
        
        if !timeBasedJourneys.isEmpty {
            // Find most frequent origin-destination pairs
            var routeCounts: [String: Int] = [:]
            for journey in timeBasedJourneys {
                let key = "\(journey.origin)-\(journey.destination)"
                routeCounts[key, default: 0] += 1
            }
            
            if let topRoute = routeCounts.max(by: { $0.value < $1.value }) {
                let parts = topRoute.key.split(separator: "-")
                if parts.count == 2 {
                    recommendations.append(Recommendation(
                        type: .frequentRoute,
                        title: "Frequent Route",
                        description: "You often travel from \(parts[0]) to \(parts[1]) around this time",
                        origin: String(parts[0]),
                        destination: String(parts[1])
                    ))
                }
            }
        }
        
        // Analyze favorites for suggestions
        let favorites = favoritesService.loadFavorites()
        if !favorites.isEmpty {
            // Suggest routes based on favorite stops
            let favoriteStops = favorites.compactMap { $0.stop }
            if favoriteStops.count >= 2 {
                recommendations.append(Recommendation(
                    type: .basedOnFavorites,
                    title: "Based on Favorites",
                    description: "Consider routes connecting your favorite stops: \(favoriteStops.joined(separator: ", "))",
                    origin: favoriteStops.first!,
                    destination: favoriteStops.last!
                ))
            }
        }
        
        return recommendations
    }
}

struct Recommendation {
    enum RecommendationType {
        case frequentRoute
        case basedOnFavorites
    }
    
    let type: RecommendationType
    let title: String
    let description: String
    let origin: String
    let destination: String
}