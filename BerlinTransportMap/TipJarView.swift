import StoreKit
import SwiftUI

// MARK: - Tip Jar UI
struct TipJarView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var store = TipJarStore()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Support Development")
                            .font(.headline)
                        Text("If Berlin Transport helps you navigate the city, you can leave a small tip. Tips are optional and don't unlock features — they simply support ongoing development.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    if case .loading = store.state {
                        ProgressView("Loading…")
                    }
                    ForEach(store.tipOptions) { option in
                        tipButton(for: option)
                    }
                } header: {
                    Text("Tip Jar")
                } footer: {
                    footerText
                }
            }
            .navigationTitle("Support")
            .navigationBarTitleDisplayMode(.inline)
            .accessibilityIdentifier("tipjar_list")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("tipjar_done_button")
                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack {
                    Spacer()

                    Button("Not now") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("tipjar_not_now_button")
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .background {
                    Rectangle().fill(.regularMaterial)
                }
            }
            .task {
                await store.loadProducts()
            }
        }
    }

    private var isPurchasing: Bool {
        if case .purchasing = store.state { return true }
        return false
    }

    // MARK: - Tip Button
    @ViewBuilder
    private func tipButton(for option: TipOption) -> some View {
        let realProduct = store.product(for: option)
        Button {
            Task { await store.purchaseTip(option) }
        } label: {
            HStack(spacing: 12) {
                Text(option.emoji)
                    .font(.title2)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(realProduct?.displayName ?? option.displayName)
                        .foregroundStyle(.primary)
                    Text(realProduct?.description ?? option.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Text(realProduct?.displayPrice ?? option.displayPrice)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
            }
        }
        .disabled(isPurchasing)
        .accessibilityIdentifier("tipjar_product_button_\(option.id)")
    }

    @ViewBuilder
    private var footerText: some View {
        switch store.state {
        case .completed:
            Text("Thank you — your support is appreciated.")
        case .cancelled:
            Text("Purchase cancelled.")
        case .pending:
            Text("Purchase pending. You\'ll be notified by the App Store if further action is required.")
        case .failed(let message):
            Text("Could not complete purchase: \(message)")
        default:
            EmptyView()
        }
    }
}

#Preview {
    TipJarView()
}
