import SwiftUI
import NetworkHealth
import Charts

@MainActor
@Observable
class StreamViewModel {
    private(set) var measurements: [QualityMeasurement] = []
    private(set) var isStreaming = false
    private(set) var currentQuality: NetworkQuality = .offline

    private var streamTask: Task<Void, Never>?

    func startStreaming() {
        guard !isStreaming else { return }
        isStreaming = true
        measurements.removeAll()

        streamTask = Task {
            for await state in NetworkHealth.stream() {
                guard !Task.isCancelled else { break }

                currentQuality = state.quality
                measurements.append(QualityMeasurement(
                    quality: state.quality,
                    timestamp: Date()
                ))

                // Keep only last 20 measurements
                if measurements.count > 20 {
                    measurements.removeFirst()
                }
            }
        }
    }

    func stopStreaming() {
        streamTask?.cancel()
        streamTask = nil
        isStreaming = false
    }
}

struct QualityMeasurement: Identifiable {
    let id = UUID()
    let quality: NetworkQuality
    let timestamp: Date

    var numericValue: Double {
        switch quality {
        case .offline: return 0
        case .poor: return 1
        case .moderate: return 2
        case .good: return 3
        case .excellent: return 4
        }
    }
}

struct StreamMonitoringView: View {
    @State private var viewModel = StreamViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)
                        .symbolEffect(.pulse, isActive: viewModel.isStreaming)

                    Text("Stream мониторинг")
                        .font(.title2)
                        .bold()

                    Text("Непрерывный мониторинг через AsyncStream")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top)

                // Current quality
                if viewModel.isStreaming {
                    VStack(spacing: 12) {
                        Text("Текущее качество")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)

                        QualityBadge(quality: viewModel.currentQuality)
                            .font(.title3)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }

                // Controls
                HStack(spacing: 12) {
                    if viewModel.isStreaming {
                        Button {
                            viewModel.stopStreaming()
                        } label: {
                            Label("Стоп", systemImage: "stop.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    } else {
                        Button {
                            viewModel.startStreaming()
                        } label: {
                            Label("Старт", systemImage: "play.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding(.horizontal)

                // Chart
                if !viewModel.measurements.isEmpty {
                    VStack(spacing: 12) {
                        Text("График качества сети")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Chart {
                            ForEach(viewModel.measurements) { measurement in
                                LineMark(
                                    x: .value("Время", measurement.timestamp),
                                    y: .value("Качество", measurement.numericValue)
                                )
                                .foregroundStyle(.blue)

                                AreaMark(
                                    x: .value("Время", measurement.timestamp),
                                    y: .value("Качество", measurement.numericValue)
                                )
                                .foregroundStyle(.blue.opacity(0.2))
                            }
                        }
                        .chartYScale(domain: 0...4)
                        .chartYAxis {
                            AxisMarks(values: [0, 1, 2, 3, 4]) { value in
                                AxisValueLabel {
                                    if let intValue = value.as(Int.self) {
                                        Text(qualityLabel(for: intValue))
                                            .font(.caption2)
                                    }
                                }
                                AxisGridLine()
                            }
                        }
                        .frame(height: 200)

                        // Legend
                        HStack(spacing: 16) {
                            LegendItem(color: .gray, label: "Offline")
                            LegendItem(color: .red, label: "Poor")
                            LegendItem(color: .orange, label: "Moderate")
                            LegendItem(color: .blue, label: "Good")
                            LegendItem(color: .green, label: "Excellent")
                        }
                        .font(.caption2)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }

                // Statistics
                if !viewModel.measurements.isEmpty {
                    VStack(spacing: 12) {
                        Text("Статистика")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(spacing: 12) {
                            StatCard(
                                title: "Измерений",
                                value: "\(viewModel.measurements.count)",
                                icon: "chart.bar.fill"
                            )

                            StatCard(
                                title: "Среднее",
                                value: averageQuality,
                                icon: "chart.line.uptrend.xyaxis"
                            )
                        }
                    }
                    .padding(.horizontal)
                }

                // Info
                InfoCard(title: "Информация") {
                    VStack(alignment: .leading, spacing: 12) {
                        InfoPoint(
                            icon: "waveform.path",
                            text: "AsyncStream обеспечивает непрерывный поток обновлений состояния сети"
                        )

                        InfoPoint(
                            icon: "chart.xyaxis.line",
                            text: "График отображает изменения качества в реальном времени"
                        )

                        InfoPoint(
                            icon: "memories",
                            text: "Хранится последние 20 измерений для визуализации"
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom)
        }
        .navigationTitle("Stream мониторинг")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func qualityLabel(for value: Int) -> String {
        switch value {
        case 0: return "Off"
        case 1: return "Poor"
        case 2: return "Mod"
        case 3: return "Good"
        case 4: return "Exc"
        default: return ""
        }
    }

    private var averageQuality: String {
        guard !viewModel.measurements.isEmpty else { return "-" }
        let sum = viewModel.measurements.reduce(0.0) { $0 + $1.numericValue }
        let avg = sum / Double(viewModel.measurements.count)
        return String(format: "%.1f", avg)
    }
}

struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)

            Text(value)
                .font(.title3)
                .bold()

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        StreamMonitoringView()
    }
}
