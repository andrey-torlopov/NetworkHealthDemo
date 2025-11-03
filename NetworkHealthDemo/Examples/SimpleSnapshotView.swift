import SwiftUI
import NetworkHealth

struct SimpleSnapshotView: View {
    @State private var state: NetworkHealthState?
    @State private var isLoading = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "network")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)

                    Text("Простой снапшот")
                        .font(.title2)
                        .bold()

                    Text("Получение информации о сети без измерения скорости")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top)

                // Action button
                Button {
                    Task {
                        await loadSnapshot()
                    }
                } label: {
                    Label(
                        "Получить снапшот",
                        systemImage: "arrow.clockwise"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading)
                .padding(.horizontal)

                if isLoading {
                    ProgressView()
                }

                // Snapshot info
                if let state = state {
                    VStack(spacing: 16) {
                        InfoCard(title: "Качество сети") {
                            QualityBadge(quality: state.quality)
                        }

                        InfoCard(title: "Тип подключения") {
                            HStack {
                                Image(systemName: connectionIcon(state.connectionType))
                                    .foregroundStyle(.blue)
                                Text(state.connectionType.description)
                                    .font(.headline)
                            }
                        }

                        InfoCard(title: "Дополнительно") {
                            VStack(alignment: .leading, spacing: 8) {
                                InfoRow(
                                    label: "Дорогое подключение",
                                    value: state.isExpensive ? "Да" : "Нет",
                                    icon: state.isExpensive ? "exclamationmark.triangle" : "checkmark.circle"
                                )

                                InfoRow(
                                    label: "Онлайн",
                                    value: state.isOnline ? "Да" : "Нет",
                                    icon: state.isOnline ? "checkmark.circle" : "xmark.circle"
                                )

                                InfoRow(
                                    label: "Хорошее качество",
                                    value: state.isGoodQuality ? "Да" : "Нет",
                                    icon: state.isGoodQuality ? "checkmark.circle" : "xmark.circle"
                                )
                            }
                        }

                        // Explanation
                        InfoCard(title: "Информация") {
                            Text("Этот снапшот получен без измерения скорости. NetworkHealth определяет качество сети на основе типа подключения и системных метрик.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom)
        }
        .navigationTitle("Простой снапшот")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func loadSnapshot() async {
        isLoading = true
        state = await NetworkHealth.snapshot()
        isLoading = false
    }

    private func connectionIcon(_ type: ConnectionRawData) -> String {
        switch type {
        case .wifi: return "wifi"
        case .cellular: return "antenna.radiowaves.left.and.right"
        case .wiredEthernet: return "cable.connector"
        case .loopback: return "arrow.triangle.2.circlepath"
        case .none: return "network.slash"
        case .other: return "network"
        }
    }
}

struct QualityBadge: View {
    let quality: NetworkQuality

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(quality.description)
                .font(.headline)
                .foregroundStyle(color)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }

    private var icon: String {
        switch quality {
        case .offline: return "wifi.slash"
        case .poor: return "wifi.exclamationmark"
        case .moderate: return "wifi"
        case .good: return "wifi"
        case .excellent: return "wifi"
        }
    }

    private var color: Color {
        switch quality {
        case .offline: return .gray
        case .poor: return .red
        case .moderate: return .orange
        case .good: return .blue
        case .excellent: return .green
        }
    }
}

struct InfoCard<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 20)

            Text(label)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .bold()
        }
        .font(.subheadline)
    }
}

#Preview {
    NavigationStack {
        SimpleSnapshotView()
    }
}
