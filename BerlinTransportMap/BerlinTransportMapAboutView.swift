import SwiftUI

struct BerlinTransportMapAboutView: View {
    @Environment(\.dismiss) var dismiss
    private let config = BerlinTransportMapAboutConfiguration()
    
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
                            Text(config.appName)
                                .font(.headline)
                            Text(config.appDescription)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                            Text("by \(config.developerName)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        VStack(spacing: 8) {
                            Text("Version \(config.appVersion) (Build \(config.appBuild))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                } header: {
                    Text("About")
                }
                
                // Developer Section
                Section {
                    VStack(spacing: 12) {
                        if let githubURL = config.githubURL {
                            Link(destination: githubURL) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up.right.fill")
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
                        
                        if let linkedInURL = config.linkedInURL {
                            Link(destination: linkedInURL) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up.right.fill")
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
                        
                        if let twitterURL = config.twitterURL {
                            Link(destination: twitterURL) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up.right.fill")
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
                        
                        if let websiteURL = config.websiteURL {
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
                        
                        if let emailURL = config.developerEmail.mailto {
                            Link(destination: emailURL) {
                                HStack {
                                    Image(systemName: "envelope.fill")
                                        .foregroundStyle(.red)
                                    Text("Email")
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
                    if let privacyURL = config.privacyPolicyURL {
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
                    
                    if let termsURL = config.termsOfUseURL {
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
            .navigationTitle("About Berlin Transport Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
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
