import SwiftUI
import NetworkHealth

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Основные примеры") {
                    NavigationLink(destination: SimpleSnapshotView()) {
                        DemoRow(
                            icon: "network",
                            title: "Простой снапшот",
                            description: "Показать интерфейсы без сети"
                        )
                    }

                    NavigationLink(destination: MockSpeedTestView()) {
                        DemoRow(
                            icon: "speedometer",
                            title: "MockSpeedTester",
                            description: "Измерение скорости с mock данными"
                        )
                    }

                    NavigationLink(destination: MonitoringView()) {
                        DemoRow(
                            icon: "antenna.radiowaves.left.and.right",
                            title: "Мониторинг сети",
                            description: "Старт/стоп мониторинга и снапшоты"
                        )
                    }
                }

                Section("Дополнительные примеры") {
                    NavigationLink(destination: StreamMonitoringView()) {
                        DemoRow(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Stream мониторинг",
                            description: "Использование AsyncStream для мониторинга"
                        )
                    }

                    NavigationLink(destination: QualityCheckView()) {
                        DemoRow(
                            icon: "checkmark.circle",
                            title: "Проверка качества",
                            description: "Проверка достаточности сети для операций"
                        )
                    }
                }

                Section("Реальные тесты скорости") {
                    NavigationLink(destination: SpeedTestCoreView()) {
                        DemoRow(
                            icon: "gauge.with.dots.needle.67percent",
                            title: "SpeedTestCore",
                            description: "Реальное измерение скорости сети"
                        )
                    }
                }
            }
            .navigationTitle("NetworkHealth Demo")
        }
    }
}

struct DemoRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
}
