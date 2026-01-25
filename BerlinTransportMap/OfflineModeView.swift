import SwiftUI

struct OfflineModeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 120, height: 120)

                Image(systemName: "wifi.slash")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                    .opacity(isAnimating ? 0.3 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(), value: isAnimating)
                    .onAppear {
                        isAnimating = true
                    }
            }

            VStack(spacing: 12) {
                Text("Offline Mode")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text("You're currently offline. Showing cached transport information.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(spacing: 16) {
                Button {
                    dismiss()
                } label: {
                    Text("Continue with Cached Data")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Text("Some features may be limited without internet connection.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.95))
    }
}

#Preview {
    OfflineModeView()
}