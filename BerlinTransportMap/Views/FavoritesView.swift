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

    init(
        onSelectStop: @escaping (TransportStop) -> Void = { _ in },
        onSelectRoute: @escaping (Route) -> Void = { _ in },
        onClose: @escaping () -> Void = {}
    ) {
        self.onSelectStop = onSelectStop
        self.onSelectRoute = onSelectRoute
        self.onClose = onClose
    }
    
    var body: some View {
        NavigationStack {
            List {
                if isLoading {
                    ProgressView("Loading favorites...")
                } else if let error = errorMessage {
                    ContentUnavailableView {
                        Label("Error", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Retry") {
                            Task {
                                isLoading = true
                                errorMessage = nil
                                await loadFavorites()
                            }
                        }
                    }
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
        print("FavoritesView: Loading favorites...")
        let favoritesService = FavoritesService(modelContext: modelContext)
        self.favoritesService = favoritesService
        
        do {
            let loadedFavorites = try favoritesService.loadFavorites()
            print("FavoritesView: Loaded \(loadedFavorites.count) favorites")
            favorites = loadedFavorites
            isLoading = false
        } catch {
            print("FavoritesView: Error loading favorites: \(error)")
            errorMessage = "Failed to load favorites: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    private func handleSelectFavorite(_ favorite: Favorite) {
        switch favorite.type {
        case .stop:
            if let stopId = favorite.stopId {
                let stop = TransportStop(
                    id: stopId,
                    name: favorite.name,
                    latitude: favorite.latitude ?? 52.52, // Default to Berlin center if no coordinates
                    longitude: favorite.longitude ?? 13.405
                )
                onSelectStop(stop)
            }
        case .route:
            if favorite.routeName != nil {
                let dummyRoute = Route(
                    id: favorite.id.uuidString,
                    legs: [],
                    totalDuration: 0,
                    departureTime: Date(),
                    arrivalTime: Date()
                )
                onSelectRoute(dummyRoute)
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
                .accessibilityElement(children: .combine)
                Spacer()
                Image(systemName: favorite.type == .stop ? "mappin.circle" : "route")
                    .foregroundStyle(.blue)
                    .accessibilityHidden(true)
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint(favorite.type == .stop ? "Opens this stop on the map" : "Opens this route on the map")
    }
}