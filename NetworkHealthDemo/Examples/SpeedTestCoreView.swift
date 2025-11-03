import SwiftUI
import NetworkHealth
import SpeedTestCore
import Nevod
import Foundation

struct SpeedTestCoreView: View {
    @State private var viewModel = SpeedTestCoreViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                backendInfo
                actionButton

                if viewModel.isRunning {
                    ProgressView()
                        .padding(.vertical)
                }

                if let state = viewModel.networkState {
                    networkSnapshotSection(for: state)
                }

                if let result = viewModel.fullResult {
                    testResultSection(for: result)
                } else if !viewModel.isRunning {
                    InfoCard(title: "Состояние") {
                        Text("Нажмите «Запустить тест», чтобы выполнить реальные измерения через SpeedTestCore.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                }

                if let lastUpdate = viewModel.lastUpdate {
                    InfoCard(title: "Последнее обновление") {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(lastUpdate.formatted(date: .abbreviated, time: .standard))
                                .font(.headline)
                            Text(lastUpdate, style: .relative)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom)
        }
        .navigationTitle("SpeedTestCore")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "gauge.with.dots.needle.67percent")
                .font(.system(size: 60))
                .foregroundStyle(.purple)

            Text("SpeedTestCore")
                .font(.title2)
                .bold()

            Text("Измерение реальной скорости и качество сети")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top)
    }

    private var backendInfo: some View {
        InfoCard(title: "Конфигурация") {
            VStack(alignment: .leading, spacing: 8) {
                Label {
                    Text(viewModel.backendURLString)
                        .font(.headline)
                } icon: {
                    Image(systemName: "server.rack")
                        .foregroundStyle(.purple)
                }

                Text("SpeedTestCore использует Nevod и обращается к реальному backend. Измерения выполняются по кнопке с базовым URL указанным выше.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
    }

    private var actionButton: some View {
        Button {
            Task {
                await viewModel.runTest()
            }
        } label: {
            Label(
                viewModel.isRunning ? "Идет тест..." : "Запустить тест",
                systemImage: "play.circle.fill"
            )
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(viewModel.isRunning)
        .padding(.horizontal)
    }

    @ViewBuilder
    private func networkSnapshotSection(for state: NetworkHealthState) -> some View {
        VStack(spacing: 16) {
            InfoCard(title: "Качество сети") {
                QualityBadge(quality: state.quality)
            }

            InfoCard(title: "Тип подключения") {
                HStack {
                    Image(systemName: connectionIcon(for: state.connectionType))
                        .foregroundStyle(.blue)
                    Text(state.connectionType.description)
                        .font(.headline)
                }
            }

            InfoCard(title: "Дополнительно") {
                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(
                        label: "Онлайн",
                        value: state.isOnline ? "Да" : "Нет",
                        icon: state.isOnline ? "checkmark.circle.fill" : "xmark.circle.fill"
                    )

                    InfoRow(
                        label: "Хорошее качество",
                        value: state.isGoodQuality ? "Да" : "Нет",
                        icon: state.isGoodQuality ? "checkmark.circle.fill" : "xmark.circle.fill"
                    )

                    InfoRow(
                        label: "Дорогое подключение",
                        value: state.isExpensive ? "Да" : "Нет",
                        icon: state.isExpensive ? "exclamationmark.triangle.fill" : "checkmark.circle.fill"
                    )
                }
            }

            InfoCard(title: "Объяснение") {
                Text("Снапшот предоставлен NetworkHealth и обновляется перед запуском измерений для понимания текущих условий сети.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func testResultSection(for result: FullTestResult) -> some View {
        VStack(spacing: 16) {
            InfoCard(title: "Статус теста") {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: result.isSuccessful ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(result.isSuccessful ? .green : .orange)
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(result.isSuccessful ? "Все измерения выполнены" : "Не удалось получить все метрики")
                            .font(.headline)

                        Text("Общая длительность: \(formatDuration(result.totalDuration))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            InfoCard(title: "Ping") {
                metricContent(
                    icon: "timer",
                    color: .purple,
                    value: pingString(for: result.ping),
                    details: durationString(fromPing: result.ping),
                    error: pingError(for: result.ping)
                )
            }

            InfoCard(title: "Скорость загрузки") {
                metricContent(
                    icon: "arrow.down.circle.fill",
                    color: .green,
                    value: speedString(for: result.download),
                    details: transferDetails(for: result.download),
                    error: speedError(for: result.download)
                )
            }

            InfoCard(title: "Скорость отдачи") {
                metricContent(
                    icon: "arrow.up.circle.fill",
                    color: .orange,
                    value: speedString(for: result.upload),
                    details: transferDetails(for: result.upload),
                    error: speedError(for: result.upload)
                )
            }
        }
        .padding(.horizontal)
    }

    private func connectionIcon(for type: ConnectionRawData) -> String {
        switch type {
        case .wifi: return "wifi"
        case .cellular: return "antenna.radiowaves.left.and.right"
        case .wiredEthernet: return "cable.connector"
        case .loopback: return "arrow.triangle.2.circlepath"
        case .none: return "network.slash"
        case .other: return "network"
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        String(format: "%.2f сек", duration)
    }

    private func formatSpeed(_ speedMbps: Double) -> String {
        String(format: "%.2f Mbps", speedMbps)
    }

    private func formatBytes(_ bytes: Int) -> String {
        Self.byteFormatter.string(fromByteCount: Int64(bytes))
    }

    @ViewBuilder
    private func metricContent(
        icon: String,
        color: Color,
        value: String?,
        details: String?,
        error: String?
    ) -> some View {
        if let error {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                Text(error)
                    .font(.subheadline)
                    .foregroundStyle(.red)
            }
        } else if let value {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .foregroundStyle(color)
                    Text(value)
                        .font(.title3)
                        .bold()
                }

                if let details {
                    Text(details)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } else {
            Text("Нет данных")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func pingString(for result: Result<PingResult, NetworkError>) -> String? {
        guard case .success(let ping) = result else {
            return nil
        }
        return String(format: "%.0f мс", ping.rtt)
    }

    private func durationString(fromPing result: Result<PingResult, NetworkError>) -> String? {
        guard case .success(let ping) = result else {
            return nil
        }
        return "Длительность: \(formatDuration(ping.duration))"
    }

    private func transferDetails(for result: Result<SpeedTestCore.SpeedTestResult, NetworkError>) -> String? {
        guard case .success(let metric) = result else {
            return nil
        }
        let bytesString = formatBytes(metric.bytesTransferred)
        let duration = formatDuration(metric.duration)
        return "\(bytesString) • \(duration)"
    }

    private func speedString(for result: Result<SpeedTestCore.SpeedTestResult, NetworkError>) -> String? {
        guard case .success(let metric) = result else {
            return nil
        }
        return formatSpeed(metric.speedMbps)
    }

    private func pingError(for result: Result<PingResult, NetworkError>) -> String? {
        guard case .failure(let error) = result else {
            return nil
        }
        return errorMessage(from: error)
    }

    private func speedError(for result: Result<SpeedTestCore.SpeedTestResult, NetworkError>) -> String? {
        guard case .failure(let error) = result else {
            return nil
        }
        return errorMessage(from: error)
    }

    private func errorMessage(from error: NetworkError) -> String {
        switch error {
        case .invalidURL:
            return "Указан некорректный адрес сервера."
        case .parsingError:
            return "Не удалось обработать ответ сервера."
        case .timeout:
            return "Превышено время ожидания запроса."
        case .noConnection:
            return "Похоже, нет подключения к сети."
        case .unauthorized:
            return "Сервер запросил авторизацию (401)."
        case .clientError(let code):
            return "HTTP ошибка клиента: \(code)."
        case .serverError(let code):
            return "HTTP ошибка сервера: \(code)."
        case .bodyEncodingFailed:
            return "Не удалось сформировать тело запроса."
        case .unknown(let underlying):
            let description = underlying.localizedDescription
            return description.isEmpty ? "Неизвестная ошибка." : "Неизвестная ошибка: \(description)"
        }
    }

    private static let byteFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .decimal
        return formatter
    }()
}

@MainActor
@Observable
final class SpeedTestCoreViewModel {
    private(set) var isRunning = false
    private(set) var networkState: NetworkHealthState?
    private(set) var fullResult: FullTestResult?
    private(set) var lastUpdate: Date?

    let backendURLString: String

    private let manager: SpeedTestManager

    init() {
        let baseURL = SpeedTestCoreViewModel.baseURL
        backendURLString = baseURL.absoluteString

        let environments: [AnyHashable: any NetworkEnvironmentProviding] = [
            AnyHashable(PingDomain()): SimpleEnvironment(baseURL: baseURL),
            AnyHashable(DownloadDomain()): SimpleEnvironment(baseURL: baseURL),
            AnyHashable(UploadDomain()): SimpleEnvironment(baseURL: baseURL)
        ]

        let config = NetworkConfig(environmentConfigurations: [environments])
        let provider = NetworkProvider(config: config)

        manager = SpeedTestManager(configuration: SpeedTestManager.Configuration(baseURL: URL(string:"http://localhost:8080")!))
    }

    func runTest() async {
        guard !isRunning else { return }

        isRunning = true
        defer { isRunning = false }

        networkState = await NetworkHealth.snapshot()
        fullResult = await manager.performFullTest()
        lastUpdate = Date()
    }

    private static let baseURL = URL(string: "http://localhost:8080")!
}

#Preview {
    NavigationStack {
        SpeedTestCoreView()
    }
}
