import SwiftUI
import SwiftData

struct FavoritesView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var favoritesService: FavoritesService?
    @State private var favorites: [Favorite] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    let onSelectStop: (TransportStop) -> Void
    let onSelectRoute: (Route) -> Void
    let onClose: () -> Void
    
    var body: some View {
        NavigationStack {
            List {
                if isLoading {
                    ProgressView("Loading favorites...")
                } else if favorites.isEmpty {
                    ContentUnavailableView(
                        "No Favorites",
                        systemImage: "star",
                        description: Text("Save stops and routes for quick access")
                    )
                } else {
                    ForEach(favorites) { favorite in
                        FavoriteRow(favorite: favorite) {
                            handleSelectFavorite(favorite)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                deleteFavorite(favorite)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        onClose()
                    }
                }
            }
            .task {
                await loadFavorites()
            }
        }
    }
    
    private func loadFavorites() async {
        guard let modelContext = modelContext else { return }
        favoritesService = FavoritesService(modelContext: modelContext)
        
        do {
            favorites = try favoritesService!.loadFavorites()
            isLoading = false
        } catch {
            errorMessage = "Failed to load favorites: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    private func handleSelectFavorite(_ favorite: Favorite) {
        switch favorite.type {
        case .stop:
            if let stopId = favorite.stopId {
                // For simplicity, create a dummy stop or fetch it
                // In real implementation, you'd fetch the stop details
                let dummyStop = TransportStop(
                    id: stopId,
                    name: favorite.name,
                    latitude: 0, // Would need to fetch actual coordinates
                    longitude: 0
                )
                onSelectStop(dummyStop)
            }
        case .route:
            if let route = favorite.getRoute() {
                onSelectRoute(route)
            }
        }
        onClose()
    }
    
    private func deleteFavorite(_ favorite: Favorite) {
        guard let favoritesService = favoritesService else { return }
        do {
            try favoritesService.deleteFavorite(favorite)
            favorites.removeAll { $0.id == favorite.id }
        } catch {
            errorMessage = "Failed to delete favorite: \(error.localizedDescription)"
        }
    }
}

struct FavoriteRow: View {
    let favorite: Favorite
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading) {
                    Text(favorite.name)
                        .font(.headline)
                    Text(favorite.type.rawValue.capitalized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: favorite.type == .stop ? "mappin.circle" : "route")
                    .foregroundStyle(.blue)
            }
        }
        .buttonStyle(.plain)
    }
}