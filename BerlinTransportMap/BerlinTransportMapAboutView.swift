import SwiftUI

struct BerlinTransportMapAboutView: View {
    @Environment(\.dismiss) var dismiss
    private let appName = AppInfo.current.name
    private let developerName = "Ruslan Dautov"
    private let developerEmail = "dautovri@outlook.com"
    private let websiteURL = URL(string: "https://dautovri.com")
    private let githubURL = URL(string: "https://github.com/dautovri/berlin-realtime-map")
    private let linkedInURL = URL(string: "https://linkedin.com/in/dautovri")
    private let twitterURL = URL(string: "https://x.com/dautovri")
    private let privacyPolicyURL = URL(string: "https://dautovri.com/privacy")
    private let termsOfUseURL = URL(string: "https://dautovri.com/terms")
    private let appDescription = "Real-time Berlin public transport map showing live vehicle positions and departures."
    private let appVersion = AppInfo.current.version
    private let appBuild = AppInfo.current.build
    private let appStoreID: String? = "6757723208"
    private let highlights = [
        "Real-time BVG/VBB departures",
        "Map-first view of nearby stops",
        "Lightweight, fast, and focused"
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
        appStorePageURL ?? websiteURL ?? githubURL
    }

    private var issuesURL: URL? {
        githubURL?.appendingPathComponent("issues")
    }
    
    var body: some View {
        NavigationStack {
            List {
                // App Header Section
                Section {
                    VStack(alignment: .center, spacing: 12) {
                        Image(systemName: "map.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(.blue)
                        
                        VStack(alignment: .center, spacing: 4) {
                            Text(appName)
                                .font(.headline)
                            Text(appDescription)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                            Text("by \(developerName)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        VStack(spacing: 8) {
                            Text("Version \(appVersion) (Build \(appBuild))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                } header: {
                    Text("About")
                }

                // Highlights Section
                Section {
                    ForEach(highlights, id: \.self) { item in
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text(item)
                            Spacer()
                        }
                    }
                } header: {
                    Text("Highlights")
                }

                // Support Section
                Section {
                    Button {
                        showingTipJar = true
                    } label: {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(.pink)
                            Text("Support Development")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                    .accessibilityIdentifier("support_development_button")

                    if let shareURL {
                        ShareLink(item: shareURL) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundStyle(.blue)
                                Text("Share App")
                                Spacer()
                            }
                        }
                        .foregroundStyle(.primary)
                    }

                    if let writeReviewURL {
                        Link(destination: writeReviewURL) {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                                Text("Rate on the App Store")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                } header: {
                    Text("Support")
                }

                // Feedback Section
                Section {
                    if let issuesURL {
                        Link(destination: issuesURL) {
                            HStack {
                                Image(systemName: "ladybug.fill")
                                    .foregroundStyle(.red)
                                Text("Report a Bug")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .foregroundStyle(.primary)
                    }

                    if let emailURL = developerEmail.mailto {
                        Link(destination: emailURL) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundStyle(.blue)
                                Text("Contact Support")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                } header: {
                    Text("Feedback")
                }
                
                // Developer Section
                Section {
                    VStack(spacing: 12) {
                        if let githubURL {
                            Link(destination: githubURL) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                        .foregroundStyle(.gray)
                                    Text("GitHub")
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .foregroundStyle(.primary)
                        }
                        
                        if let linkedInURL {
                            Link(destination: linkedInURL) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                        .foregroundStyle(.blue)
                                    Text("LinkedIn")
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .foregroundStyle(.primary)
                        }
                        
                        if let twitterURL {
                            Link(destination: twitterURL) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                        .foregroundStyle(.black)
                                    Text("Twitter/X")
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .foregroundStyle(.primary)
                        }
                        
                        if let websiteURL {
                            Link(destination: websiteURL) {
                                HStack {
                                    Image(systemName: "globe")
                                        .foregroundStyle(.blue)
                                    Text("Website")
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                } header: {
                    Text("Developer")
                }
                
                // Links Section
                Section {
                    if let privacyURL = privacyPolicyURL {
                        Link(destination: privacyURL) {
                            HStack {
                                Text("Privacy Policy")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    if let termsURL = termsOfUseURL {
                        Link(destination: termsURL) {
                            HStack {
                                Text("Terms of Use")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Legal")
                }
                
                // Acknowledgements Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("This app is built with:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• SwiftUI - Apple's modern UI framework")
                                .font(.caption2)
                            Text("• MapKit - Apple Maps integration")
                                .font(.caption2)
                            Text("• BVG/VBB APIs - Real-time transit data")
                                .font(.caption2)
                        }
                        .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Acknowledgements")
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingTipJar) {
                TipJarView()
            }
        }
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
