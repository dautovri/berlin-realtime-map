import SwiftUI
import MapKit

struct StopAnnotationView: View {
    let stop: TransportStop
    let departures: [RESTDeparture]?
    let showLabel: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#FFD800"))
                    .frame(width: 16, height: 16)
                Circle()
                    .stroke(Color(hex: "#006F3C"), lineWidth: 1.5)
                    .frame(width: 16, height: 16)
                Text("H")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#006F3C"))
            }
            .accessibilityHidden(true)
            
            if showLabel {
                Text(stop.name)
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .padding(.horizontal, 4)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                if let departures = departures, let next = departures.first {
                    if let displayTime = next.displayTime {
                        Text(displayTime, style: .time)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)
                            .background(.ultraThinMaterial.opacity(0.8))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    } else {
                        Text("Soon")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)
                            .background(.ultraThinMaterial.opacity(0.8))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
            }
        }
        .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
        .accessibilityElement(children: .ignore)
    }
}

#Preview {
    StopAnnotationView(
        stop: TransportStop(
            id: "900100003",
            name: "Alexanderplatz",
            latitude: 52.5219,
            longitude: 13.4132
        ),
        departures: [
            RESTDeparture(
                tripId: "preview",
                stop: nil,
                when: nil,
                plannedWhen: nil,
                delay: nil,
                platform: "1",
                direction: "Hermannstraße",
                line: nil,
                cancelled: nil
            )
        ],
        showLabel: true
    )
    .frame(width: 200, height: 100)
    .background(Color.gray.opacity(0.1))
}