import SwiftUI

struct HistoryView: View {
    @State private var journeyService = JourneyService()
    @State private var journeys: [Journey] = []
    @State private var frequentRoutes: [RouteSuggestion] = []
    
    var body: some View {
        NavigationStack {
            List {
                if !frequentRoutes.isEmpty {
                    Section("Frequent Routes") {
                        ForEach(frequentRoutes) { route in
                            RouteSuggestionRow(suggestion: route)
                        }
                    }
                }
                
                Section("Journey History") {
                    if journeys.isEmpty {
                        ContentUnavailableView(
                            "No Journeys",
                            systemImage: "clock",
                            description: Text("Your journey history will appear here")
                        )
                    } else {
                        ForEach(journeys) { journey in
                            JourneyRow(journey: journey)
                        }
                    }
                }
            }
            .navigationTitle("History")
            .task {
                loadData()
            }
        }
    }
    
    private func loadData() {
        journeys = journeyService.getHistory()
        frequentRoutes = journeyService.getFrequentRoutes()
    }
}

struct JourneyRow: View {
    let journey: Journey
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("From: Stop \(journey.startStopId)")
                Spacer()
                Text("To: Stop \(journey.endStopId)")
            }
            .font(.subheadline)
            
            HStack {
                Text(journey.transportMode)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if let duration = journey.duration {
                    Text(String(format: "%.0f min", duration / 60))
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }
            
            Text(journey.startTime, style: .date)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct RouteSuggestionRow: View {
    let suggestion: RouteSuggestion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Stop \(suggestion.startStop.id)")
                Image(systemName: "arrow.right")
                Text("Stop \(suggestion.endStop.id)")
            }
            .font(.subheadline)
            
            HStack {
                Text(suggestion.transportMode.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("Used \(suggestion.frequency) times")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}