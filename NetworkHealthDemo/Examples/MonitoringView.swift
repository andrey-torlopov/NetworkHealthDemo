import SwiftUI
import NetworkHealth

@MainActor
@Observable
class MonitoringViewModel {
    private(set) var currentState: NetworkHealthState?
    private(set) var isMonitoring = false
    var states: [TimestampedState] = []

    private var monitoringTask: Task<Void, Never>?

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        states.removeAll()

        monitoringTask = Task {
            for await state in NetworkHealth.stream() {
                guard !Task.isCancelled else { break }

                currentState = state
                states.append(TimestampedState(
                    state: state,
                    timestamp: Date()
                ))

                // Keep only last 10 states
                if states.count > 10 {
                    states.removeFirst()
                }
            }
        }
    }

    func stopMonitoring() {
        monitoringTask?.cancel()
        monitoringTask = nil
        isMonitoring = false
    }

    func getManualSnapshot() async {
        currentState = await NetworkHealth.snapshot()
        states.append(TimestampedState(
            state: currentState!,
            timestamp: Date()
        ))

        if states.count > 10 {
            states.removeFirst()
        }
    }
}

struct TimestampedState: Identifiable {
    let id = UUID()
    let state: NetworkHealthState
    let timestamp: Date

    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: timestamp)
    }
}

struct MonitoringView: View {
    @State private var viewModel = MonitoringViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: viewModel.isMonitoring ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash")
                        .font(.system(size: 60))
                        .foregroundStyle(viewModel.isMonitoring ? .green : .gray)
                        .symbolEffect(.pulse, isActive: viewModel.isMonitoring)

                    Text("Мониторинг сети")
                        .font(.title2)
                        .bold()

                    Text(viewModel.isMonitoring ? "Активный мониторинг" : "Мониторинг остановлен")
                        .font(.caption)
                        .foregroundStyle(viewModel.isMonitoring ? .green : .secondary)
                }
                .padding(.top)

                // Control buttons
                VStack(spacing: 12) {
                    if viewModel.isMonitoring {
                        Button {
                            viewModel.stopMonitoring()
                        } label: {
                            Label("Остановить мониторинг", systemImage: "stop.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    } else {
                        Button {
                            viewModel.startMonitoring()
                        } label: {
                            Label("Запустить мониторинг", systemImage: "play.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)

                        Button {
                            Task {
                                await viewModel.getManualSnapshot()
                            }
                        } label: {
                            Label("Получить снапшот", systemImage: "camera.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.horizontal)

                // Current status
                if let state = viewModel.currentState {
                    VStack(spacing: 16) {
                        Text("Текущее состояние")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)

                        InfoCard(title: "Качество") {
                            QualityBadge(quality: state.quality)
                        }
                        .padding(.horizontal)

                        HStack(spacing: 12) {
                            MiniInfoCard(
                                icon: connectionIcon(state.connectionType),
                                title: "Тип",
                                value: state.connectionType.description
                            )

                            if state.isExpensive {
                                MiniInfoCard(
                                    icon: "exclamationmark.triangle.fill",
                                    title: "Статус",
                                    value: "Дорогое",
                                    color: .orange
                                )
                            }
                        }
                        .padding(.horizontal)

                        if state.latency != nil || state.downloadSpeedMbps != nil {
                            HStack(spacing: 12) {
                                if let latency = state.latency {
                                    MiniInfoCard(
                                        icon: "timer",
                                        title: "Задержка",
                                        value: "\(Int(latency)) мс"
                                    )
                                }

                                if let download = state.downloadSpeedMbps {
                                    MiniInfoCard(
                                        icon: "arrow.down.circle.fill",
                                        title: "Загрузка",
                                        value: String(format: "%.1f Mbps", download)
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }

                // History
                if !viewModel.states.isEmpty {
                    VStack(spacing: 12) {
                        HStack {
                            Text("История (\(viewModel.states.count))")
                                .font(.headline)

                            Spacer()

                            Button("Очистить") {
                                viewModel.states.removeAll()
                            }
                            .font(.caption)
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        .padding(.horizontal)

                        ForEach(viewModel.states.reversed()) { item in
                            HistoryRow(item: item)
                        }
                        .padding(.horizontal)
                    }
                }

                // Information
                InfoCard(title: "Информация") {
                    VStack(alignment: .leading, spacing: 12) {
                        InfoPoint(
                            icon: "play.circle.fill",
                            text: "Мониторинг использует NetworkHealth.stream() для непрерывного отслеживания состояния сети"
                        )

                        InfoPoint(
                            icon: "camera.circle.fill",
                            text: "Снапшот получает единовременное состояние через NetworkHealth.snapshot()"
                        )

                        InfoPoint(
                            icon: "clock.fill",
                            text: "История хранит последние 10 событий"
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom)
        }
        .navigationTitle("Мониторинг")
        .navigationBarTitleDisplayMode(.inline)
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

struct MiniInfoCard: View {
    let icon: String
    let title: String
    let value: String
    var color: Color = .blue

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.caption)
                .bold()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct HistoryRow: View {
    let item: TimestampedState

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    QualityIndicator(quality: item.state.quality)
                    Text(item.state.quality.description)
                        .font(.subheadline)
                        .bold()
                }

                Text(item.timeString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: connectionIcon(item.state.connectionType))
                        .font(.caption)
                    Text(item.state.connectionType.description)
                        .font(.caption)
                }

                if item.state.isExpensive {
                    Text("Дорогое")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
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

struct QualityIndicator: View {
    let quality: NetworkQuality

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 12, height: 12)
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

struct InfoPoint: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 20)

            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        MonitoringView()
    }
}
