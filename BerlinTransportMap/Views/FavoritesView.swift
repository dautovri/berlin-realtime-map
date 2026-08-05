import SwiftUI
import SwiftData

struct FavoritesView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var favorites: [Favorite] = []
    @State private var showingRouteUnavailableAlert = false

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

    var stopFavorites: [Favorite] {
        favorites.filter { $0.type == .stop }
    }

    var body: some View {
        NavigationStack {
            Group {
                if favorites.isEmpty {
                    // The old empty state was a dead end: it described an action
                    // the user could not take from here. Give it a way out.
                    ContentUnavailableView {
                        Label("No Saved Stops", systemImage: "tram.fill")
                    } description: {
                        Text("Save the stops you use every day and their next departures show up here instantly.")
                    } actions: {
                        Button("Browse the Map", action: onClose)
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                    }
                } else {
                    List {
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
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("My Stops")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done", action: onClose)
                }
            }
            .task {
                loadFavorites()
            }
            .alert("Route Replay Unavailable", isPresented: $showingRouteUnavailableAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Saved routes can't be replayed yet. Tap a stop to see live departures.")
            }
        }
    }

    private func loadFavorites() {
        let service = FavoritesService(modelContext: modelContext, cityManager: ServiceContainer.shared.cityManager)
        favorites = (try? service.loadFavorites()) ?? []
    }

    private func handleSelectFavorite(_ favorite: Favorite) {
        switch favorite.type {
        case .stop:
            guard let stopId = favorite.stopId else { return }
            let stop = TransportStop(
                id: stopId,
                name: favorite.name,
                latitude: favorite.latitude ?? 52.52,
                longitude: favorite.longitude ?? 13.405
            )
            onSelectStop(stop)
            onClose()
        case .route:
            showingRouteUnavailableAlert = true
        }
    }

    private func deleteFavorite(_ favorite: Favorite) {
        let service = FavoritesService(modelContext: modelContext, cityManager: ServiceContainer.shared.cityManager)
        try? service.deleteFavorite(favorite)
        favorites.removeAll { $0.id == favorite.id }
    }
}
