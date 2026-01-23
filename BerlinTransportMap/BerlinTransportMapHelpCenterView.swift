import SwiftUI

struct BerlinTransportMapHelpCenterView: View {
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    private let allTopics = BerlinTransportMapHelpTopicsConfiguration.allTopics
    
    var filteredTopics: [String: [HelpTopic]] {
        let filtered = searchText.isEmpty ? allTopics : allTopics.filter { topic in
            topic.title.localizedCaseInsensitiveContains(searchText) ||
            topic.content.localizedCaseInsensitiveContains(searchText) ||
            topic.keywords.contains { keyword in
                keyword.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return Dictionary(grouping: filtered, by: { $0.section })
    }
    
    var sectionOrder: [String] {
        ["Getting Started", "Live Tracking", "Departures", "Navigation", "Features", "Troubleshooting", "Privacy & Data"]
    }
    
    var body: some View {
        NavigationStack {
            List {
                if searchText.isEmpty {
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            Image(systemName: "questionmark.circle.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.blue)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Need Help?")
                                    .font(.headline)
                                Text("Browse topics or search for answers")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                    }
                }
                
                ForEach(sectionOrder, id: \.self) { section in
                    if let sectionTopics = filteredTopics[section], !sectionTopics.isEmpty {
                        Section(header: Text(section)) {
                            ForEach(sectionTopics, id: \.id) { topic in
                                NavigationLink(destination: BerlinTransportMapHelpDetailView(topic: topic)) {
                                    HStack(spacing: 12) {
                                        Image(systemName: topic.icon)
                                            .font(.system(size: 16))
                                            .foregroundStyle(.blue)
                                            .frame(width: 20)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(topic.title)
                                                .font(.subheadline.weight(.medium))
                                            Text(topic.content)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundStyle(.tertiary)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                }
                
                if !searchText.isEmpty && filteredTopics.isEmpty {
                    Section {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 32))
                                .foregroundStyle(.secondary)
                            
                            VStack(spacing: 4) {
                                Text("No results found")
                                    .font(.headline)
                                Text("Try different keywords")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search help topics")
            .navigationTitle("Help & Support")
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

struct BerlinTransportMapHelpDetailView: View {
    let topic: HelpTopic
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(spacing: 12) {
                    Image(systemName: topic.icon)
                        .font(.system(size: 32))
                        .foregroundStyle(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(topic.section)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(topic.title)
                            .font(.title3.weight(.semibold))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top)
                
                Divider()
                    .padding(.horizontal)
                
                // Content
                VStack(alignment: .leading, spacing: 12) {
                    Text(topic.content)
                        .font(.body)
                        .lineSpacing(4)
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Contact Support
                VStack(spacing: 12) {
                    Divider()
                    
                    Text("Still need help?")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Link(destination: "mailto:dautovri@outlook.com".mailto ?? URL(string: "https://dautovri.com")!) {
                        HStack {
                            Image(systemName: "envelope.fill")
                            Text("Contact Support")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(.blue)
                    }
                }
                .padding()
            }
            .padding(.vertical)
        }
        .navigationTitle(topic.title)
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

#Preview("Help Center") {
    BerlinTransportMapHelpCenterView()
}

#Preview("Help Detail") {
    BerlinTransportMapHelpDetailView(topic: BerlinTransportMapHelpTopicsConfiguration.allTopics[0])
}
