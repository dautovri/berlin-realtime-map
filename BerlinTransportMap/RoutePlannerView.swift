import SwiftUI

struct RoutePlannerView: View {
    @State private var startStop: String = ""
    @State private var endStop: String = ""
    @State private var selectedTransportMode: TransportMode = .train
    
    let onPlanRoute: (String, String, TransportMode) -> Void
    
    enum TransportMode: String, CaseIterable, Identifiable {
        case train = "Train"
        case bus = "Bus"
        case subway = "Subway"
        case tram = "Tram"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Plan Your Route")
                .font(.title)
                .padding()
            
            TextField("Start Stop", text: $startStop)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            TextField("End Stop", text: $endStop)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Picker("Transport Mode", selection: $selectedTransportMode) {
                ForEach(TransportMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            Button(action: {
                onPlanRoute(startStop, endStop, selectedTransportMode)
            }) {
                Text("Plan Route")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    RoutePlannerView { start, end, mode in
        print("Plan route from \(start) to \(end) via \(mode)")
    }
}