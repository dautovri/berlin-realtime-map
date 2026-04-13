import SwiftUI

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
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint(favorite.type == .stop ? "Opens this stop on the map" : "Route replay not yet available")
    }
}
