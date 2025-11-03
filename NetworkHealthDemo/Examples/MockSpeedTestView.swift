import SwiftUI
import NetworkHealth

struct MockSpeedTestView: View {
    @State private var selectedMock: MockType = .excellent5G
    @State private var snapshot: NetworkQualitySnapshot?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "speedometer")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)

                    Text("MockSpeedTester")
                        .font(.title2)
                        .bold()

                    Text("Имитация измерения скорости сети с различными профилями")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top)

                // Mock selector
                VStack(alignment: .leading, spacing: 12) {
                    Text("Выберите профиль")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    ForEach(MockType.allCases) { mock in
                        MockRow(
                            mock: mock,
                            isSelected: selectedMock == mock
                        ) {
                            selectedMock = mock
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)

                // Action button
                Button {
                    Task {
                        await performMockTest()
                    }
                } label: {
                    Label(
                        "Запустить тест",
                        systemImage: "play.circle.fill"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading)
                .padding(.horizontal)

                if isLoading {
                    ProgressView()
                        .padding()
                }

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }

                // Results
                if let snapshot = snapshot {
                    VStack(spacing: 16) {
                        InfoCard(title: "Качество сети") {
                            QualityBadge(quality: snapshot.quality)
                        }

                        if let latency = snapshot.latency {
                            InfoCard(title: "Задержка (Latency)") {
                                HStack {
                                    Image(systemName: "timer")
                                        .foregroundStyle(.blue)
                                    Text("\(Int(latency)) мс")
                                        .font(.title3)
                                        .bold()
                                }
                            }
                        }

                        if let download = snapshot.downloadSpeedMbps {
                            InfoCard(title: "Скорость загрузки") {
                                HStack {
                                    Image(systemName: "arrow.down.circle.fill")
                                        .foregroundStyle(.green)
                                    Text(String(format: "%.1f Mbps", download))
                                        .font(.title3)
                                        .bold()
                                }
                            }
                        }

                        if let upload = snapshot.uploadSpeedMbps {
                            InfoCard(title: "Скорость отдачи") {
                                HStack {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .foregroundStyle(.orange)
                                    Text(String(format: "%.1f Mbps", upload))
                                        .font(.title3)
                                        .bold()
                                }
                            }
                        }

                        InfoCard(title: "Информация") {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("MockSpeedTester имитирует измерение скорости без реальных сетевых запросов.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Text("Используется метод NetworkHealth.detailedSnapshot(speedTester:) с различными mock-профилями.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom)
        }
        .navigationTitle("MockSpeedTester")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func performMockTest() async {
        isLoading = true
        errorMessage = nil

        do {
            let mockTester = selectedMock.createTester()
            snapshot = try await NetworkHealth.detailedSnapshot(speedTester: mockTester)
        } catch {
            errorMessage = "Ошибка: \(error.localizedDescription)"
        }

        isLoading = false
    }
}

enum MockType: String, CaseIterable, Identifiable {
    case excellent5G = "5G Excellent"
    case goodLTE = "LTE Good"
    case moderate3G = "3G Moderate"
    case poor2G = "2G Poor"
    case excellentWiFi = "WiFi Excellent"
    case slowWiFi = "WiFi Slow"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .excellent5G: return "5.circle.fill"
        case .goodLTE: return "l.circle.fill"
        case .moderate3G: return "3.circle.fill"
        case .poor2G: return "2.circle.fill"
        case .excellentWiFi: return "wifi.circle.fill"
        case .slowWiFi: return "wifi.exclamationmark.circle.fill"
        }
    }

    var description: String {
        switch self {
        case .excellent5G: return "100 Mbps, 15ms"
        case .goodLTE: return "20 Mbps, 50ms"
        case .moderate3G: return "3 Mbps, 150ms"
        case .poor2G: return "0.3 Mbps, 500ms"
        case .excellentWiFi: return "150 Mbps, 10ms"
        case .slowWiFi: return "2 Mbps, 200ms"
        }
    }

    var color: Color {
        switch self {
        case .excellent5G, .excellentWiFi: return .green
        case .goodLTE: return .blue
        case .moderate3G: return .orange
        case .poor2G, .slowWiFi: return .red
        }
    }

    func createTester() -> MockSpeedTester {
        switch self {
        case .excellent5G: return .excellent5G
        case .goodLTE: return .goodLTE
        case .moderate3G: return .moderate3G
        case .poor2G: return .poor2G
        case .excellentWiFi: return .excellentWiFi
        case .slowWiFi: return .slowWiFi
        }
    }
}

struct MockRow: View {
    let mock: MockType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: mock.icon)
                    .font(.title3)
                    .foregroundStyle(mock.color)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(mock.rawValue)
                        .font(.subheadline)
                        .bold()
                        .foregroundStyle(.primary)

                    Text(mock.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
    }
}

#Preview {
    NavigationStack {
        MockSpeedTestView()
    }
}
