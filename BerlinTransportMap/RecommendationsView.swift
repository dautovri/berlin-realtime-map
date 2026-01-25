import SwiftUI

struct RecommendationsView: View {
    @StateObject private var recommendationService = RecommendationService.shared
    
    var body: some View {
        NavigationView {
            List {
                let recommendations = recommendationService.generateRecommendations()
                
                if recommendations.isEmpty {
                    Text("No recommendations yet. Use the app to build history and favorites.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(recommendations, id: \.title) { recommendation in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(recommendation.title)
                                .font(.headline)
                            Text(recommendation.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            HStack {
                                Text("From: \(recommendation.origin)")
                                Spacer()
                                Text("To: \(recommendation.destination)")
                            }
                            .font(.caption)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Recommendations")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct RecommendationsView_Previews: PreviewProvider {
    static var previews: some View {
        RecommendationsView()
    }
}