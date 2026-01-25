import SwiftUI
import MapKit

struct StopAnnotationView: View {
    let stop: TransportStop
    let departures: [RESTDeparture]?
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#FFD800"))
                    .frame(width: 24, height: 24)
                Circle()
                    .stroke(Color(hex: "#006F3C"), lineWidth: 2)
                    .frame(width: 24, height: 24)
                Text("H")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#006F3C"))
            }
            
            Text(stop.name)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(1)
                .padding(.horizontal, 4)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            
            if let departures = departures, let next = departures.first {
                Text(next.displayTime ?? "Soon")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
                    .background(.ultraThinMaterial.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
        .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
    }
}

#Preview {
    StopAnnotationView(
        stop: TransportStop(
            vbbStopId: "123",
            name: "Alexanderplatz",
            latitude: 52.5219,
            longitude: 13.4132
        ),
        departures: [
            RESTDeparture(
                line: Line(displayName: "U8", color: "#0066CC"),
                direction: "Hermannstraße",
                platform: "1",
                displayTime: "2 min"
            )
        ]
    )
    .frame(width: 200, height: 100)
    .background(Color.gray.opacity(0.1))
}