import SwiftUI

struct BerlinTransportMapAboutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    private let appName = AppInfo.current.name
    private let developerName = "Ruslan Dautov"
    private let developerEmail = "dautovri@outlook.com"
    private let websiteURL = URL(string: "https://dautovri.com")
    private let linkedInURL = URL(string: "https://linkedin.com/in/dautovri")
    private let twitterURL = URL(string: "https://x.com/dautovri")
    private let privacyPolicyURL = URL(string: "https://gist.github.com/dautovri/2ca5f7b5b4b3789056c5dadbf1f60966")
    private let appDescription = "Track Berlin trains, trams, and buses live on a fast interactive map with real-time stop departures."
    private let appVersion = AppInfo.current.version
    private let appBuild = AppInfo.current.build
    private let appStoreID: String? = "6757723208"
    private let highlights = [
        "Live vehicle positions on the map",
        "Real-time departures with delays",
        "No account, no tracking"
    ]
    @State private var showingTipJar = false

    private var appStorePageURL: URL? {
        guard let appStoreID else { return nil }
        return URL(string: "https://apps.apple.com/app/id\(appStoreID)")
    }

    private var writeReviewURL: URL? {
        guard let appStoreID else { return nil }
        return URL(string: "https://apps.apple.com/app/id\(appStoreID)?action=write-review")
    }

    private var shareURL: URL? {
        appStorePageURL ?? websiteURL
    }

    private var bugReportURL: URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = developerEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: "\(appName) Bug Report")
        ]
        return components.url
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    mapHero
                    networkLegend
                    routeSupportPanel
                    developerDepot

                    Text("Made with ♥ in Berlin by \(developerName)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 4)
                }
                .padding(.horizontal)
                .padding(.vertical)
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
            .safeAreaInset(edge: .bottom) {
                Button("Support", systemImage: "heart.fill") {
                    showingTipJar = true
                }
                .buttonStyle(.borderedProminent)
                .tint(.pink)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("support_development_button")
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 16)
                .background {
                    if reduceTransparency {
                        #if os(tvOS)
                        Color.black
                        #else
                        Color(.systemBackground)
                        #endif
                    } else {
                        Rectangle().fill(.thinMaterial)
                    }
                }
            }
            .navigationTitle("About")
            #if !os(tvOS)
.navigationBarTitleDisplayMode(.large)
#endif
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close", systemImage: "xmark", action: { dismiss() })
                        .labelStyle(.iconOnly)
                        .frame(minWidth: 44, minHeight: 44)
                        .accessibilityLabel("Close")
                        .accessibilityInputLabels(["Close"])
                        .accessibilityShowsLargeContentViewer {
                            Label("Close", systemImage: "xmark")
                        }
                }
            }
            .sheet(isPresented: $showingTipJar) {
                TipJarView()
            }
        }
    }

    private var mapHero: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 16) {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.cyan.opacity(0.14))
                    .frame(width: 84, height: 84)
                    .overlay {
                        Image(systemName: "map.fill")
                            .font(.title.bold())
                            .foregroundStyle(.cyan)
                    }

                VStack(alignment: .leading, spacing: 6) {
                    Text(appName)
                        .font(.title2.bold())

                    Text(appDescription)
                        .font(.body)
                        .foregroundStyle(.secondary)

                    Text("Made by \(developerName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: 12) {
                Label("Version \(appVersion) • Build \(appBuild)", systemImage: "app.badge")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    routeBadge("U", tint: .blue)
                    routeBadge("S", tint: .green)
                    routeBadge("Bus", tint: .orange)
                    routeBadge("Tram", tint: .red)
                }
            }

            HStack(spacing: 12) {
                #if !os(tvOS)
                if let shareURL {
                    ShareLink(item: shareURL) {
                        Label("Share map", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)
                }
#endif

                if let writeReviewURL {
                    Link(destination: writeReviewURL) {
                        Label("Rate app", systemImage: "star.fill")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 30))
        .overlay {
            RoundedRectangle(cornerRadius: 30)
                .strokeBorder(.quaternary, lineWidth: 1)
        }
    }

    private var networkLegend: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("What the map is best at", systemImage: "map.circle.fill")
                .font(.headline)
                .foregroundStyle(.blue)

            VStack(spacing: 12) {
                legendRow(symbol: "location.fill", tint: .blue, title: highlights[0], subtitle: "Watch the network update in real time without losing the wider map context.")
                legendRow(symbol: "figure.walk", tint: .green, title: highlights[1], subtitle: "Scan nearby stops quickly when you’re already on the move.")
                legendRow(symbol: "bolt.horizontal.fill", tint: .orange, title: highlights[2], subtitle: "Open fast, stay lightweight, and focus on the next useful answer.")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.cyan.opacity(0.08), in: RoundedRectangle(cornerRadius: 26))
    }

    private var routeSupportPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Route issues or map quirks?", systemImage: "bubble.left.and.exclamationmark.bubble.right.fill")
                .font(.headline)
                .foregroundStyle(.teal)

            if let emailURL = developerEmail.mailto {
                Button {
                    openURL(emailURL)
                } label: {
                    routeAction(title: "Contact support", subtitle: "Questions, feedback, and route issues.", systemImage: "envelope.fill", tint: .blue)
                }
                .buttonStyle(.plain)
            }

            if let bugReportURL {
                Button {
                    openURL(bugReportURL)
                } label: {
                    routeAction(title: "Report a bug", subtitle: "Send the steps and I'll investigate.", systemImage: "ladybug.fill", tint: .red)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.background, in: RoundedRectangle(cornerRadius: 26))
        .overlay {
            RoundedRectangle(cornerRadius: 26)
                .strokeBorder(.quaternary, lineWidth: 1)
        }
    }

    private var developerDepot: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Developer and policy links", systemImage: "building.columns.fill")
                .font(.headline)
                .foregroundStyle(.indigo)

            VStack(alignment: .leading, spacing: 12) {
                if let websiteURL {
                    Button { openURL(websiteURL) } label: {
                        infoRow(title: "Portfolio", subtitle: "More tools and transit experiments", systemImage: "globe", tint: .blue)
                    }
                    .buttonStyle(.plain)
                }

                if let linkedInURL {
                    Button { openURL(linkedInURL) } label: {
                        infoRow(title: "LinkedIn", subtitle: "Professional profile", systemImage: "person.2.fill", tint: .blue)
                    }
                    .buttonStyle(.plain)
                }

                if let twitterURL {
                    Button { openURL(twitterURL) } label: {
                        infoRow(title: "X", subtitle: "Short updates and release notes", systemImage: "bubble.left.and.text.bubble.right.fill", tint: .primary)
                    }
                    .buttonStyle(.plain)
                }

                if let privacyURL = privacyPolicyURL {
                    Button { openURL(privacyURL) } label: {
                        infoRow(title: "Privacy Policy", subtitle: "How location and transport data are handled", systemImage: "hand.raised.fill", tint: .green)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 26))
    }

    private var supportButton: some View {
        Button("Support", systemImage: "heart.fill") {
            showingTipJar = true
        }
        .buttonStyle(.borderedProminent)
        .tint(.pink)
        .accessibilityIdentifier("support_development_button")
    }

    private func routeBadge(_ title: String, tint: Color) -> some View {
        Text(title)
            .font(.headline)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(tint, in: Capsule())
            .foregroundStyle(.white)
    }

    private func legendRow(symbol: String, tint: Color, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(tint)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
    }

    private func routeAction(title: String, subtitle: String, systemImage: String, tint: Color) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(tint)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "arrow.up.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
    }

    private func infoRow(title: String, subtitle: String, systemImage: String, tint: Color) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "arrow.up.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

extension String {
    var mailto: URL? {
        URL(string: "mailto:\(self)")
    }
}

#Preview {
    BerlinTransportMapAboutView()
}
