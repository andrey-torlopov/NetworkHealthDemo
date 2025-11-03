import SwiftUI
import NetworkHealth

struct QualityCheckView: View {
    @State private var selectedOperation: OperationRequirement = .videoStreaming
    @State private var checkResult: CheckResult?
    @State private var isChecking = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)

                    Text("Проверка качества")
                        .font(.title2)
                        .bold()

                    Text("Проверка достаточности сети для различных операций")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top)

                // Operation selector
                VStack(alignment: .leading, spacing: 12) {
                    Text("Выберите операцию")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    OperationRow(
                        operation: .basicBrowsing,
                        isSelected: isSelected(.basicBrowsing)
                    ) {
                        selectedOperation = .basicBrowsing
                    }

                    OperationRow(
                        operation: .imageLoading,
                        isSelected: isSelected(.imageLoading)
                    ) {
                        selectedOperation = .imageLoading
                    }

                    OperationRow(
                        operation: .videoStreaming,
                        isSelected: isSelected(.videoStreaming)
                    ) {
                        selectedOperation = .videoStreaming
                    }

                    OperationRow(
                        operation: .largeDownload,
                        isSelected: isSelected(.largeDownload)
                    ) {
                        selectedOperation = .largeDownload
                    }

                    OperationRow(
                        operation: .largeUpload,
                        isSelected: isSelected(.largeUpload)
                    ) {
                        selectedOperation = .largeUpload
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)

                // Check button
                Button {
                    Task {
                        await performCheck()
                    }
                } label: {
                    Label(
                        "Проверить сеть",
                        systemImage: "checkmark.circle.fill"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isChecking)
                .padding(.horizontal)

                if isChecking {
                    ProgressView()
                }

                // Results
                if let result = checkResult {
                    VStack(spacing: 16) {
                        // Result badge
                        ResultBadge(result: result.healthResult)

                        // Current quality
                        InfoCard(title: "Текущее качество сети") {
                            QualityBadge(quality: result.state.quality)
                        }

                        // Details
                        InfoCard(title: "Детали подключения") {
                            VStack(alignment: .leading, spacing: 8) {
                                InfoRow(
                                    label: "Тип",
                                    value: result.state.connectionType.description,
                                    icon: connectionIcon(result.state.connectionType)
                                )

                                InfoRow(
                                    label: "Дорогое",
                                    value: result.state.isExpensive ? "Да" : "Нет",
                                    icon: result.state.isExpensive ? "exclamationmark.triangle" : "checkmark.circle"
                                )

                                if let latency = result.state.latency {
                                    InfoRow(
                                        label: "Задержка",
                                        value: "\(Int(latency)) мс",
                                        icon: "timer"
                                    )
                                }
                            }
                        }

                        // Recommendation
                        if let reason = result.healthResult.reason {
                            InfoCard(title: result.healthResult.passed ? "Рекомендация" : "Предупреждение") {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: result.healthResult.passed ? "lightbulb.fill" : "exclamationmark.triangle.fill")
                                        .foregroundStyle(result.healthResult.passed ? .blue : .orange)
                                        .font(.title3)

                                    Text(reason)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Info
                InfoCard(title: "Информация") {
                    VStack(alignment: .leading, spacing: 12) {
                        InfoPoint(
                            icon: "checkmark.shield.fill",
                            text: "Метод isGoodEnoughFor() проверяет, достаточно ли текущее качество сети для выполнения операции"
                        )

                        InfoPoint(
                            icon: "slider.horizontal.3",
                            text: "Каждая операция требует минимальный уровень качества сети"
                        )

                        InfoPoint(
                            icon: "network",
                            text: "Используйте перед выполнением сетевых операций для лучшего UX"
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom)
        }
        .navigationTitle("Проверка качества")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func isSelected(_ operation: OperationRequirement) -> Bool {
        // Compare by description since enum cases might not be directly comparable
        operationName(selectedOperation) == operationName(operation)
    }

    private func operationName(_ operation: OperationRequirement) -> String {
        switch operation {
        case .basicBrowsing: return "basicBrowsing"
        case .imageLoading: return "imageLoading"
        case .videoStreaming: return "videoStreaming"
        case .largeDownload: return "largeDownload"
        case .largeUpload: return "largeUpload"
        case .custom: return "custom"
        }
    }

    private func performCheck() async {
        isChecking = true

        let state = await NetworkHealth.snapshot()
        let healthResult = await NetworkHealth.check(requirement: selectedOperation)

        checkResult = CheckResult(
            operation: selectedOperation,
            state: state,
            healthResult: healthResult
        )

        isChecking = false
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

struct CheckResult {
    let operation: OperationRequirement
    let state: NetworkHealthState
    let healthResult: HealthCheckResult
}

struct OperationRow: View {
    let operation: OperationRequirement
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.subheadline)
                        .bold()
                        .foregroundStyle(.primary)

                    Text(description)
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

    private var icon: String {
        switch operation {
        case .basicBrowsing: return "safari.fill"
        case .imageLoading: return "photo.fill"
        case .videoStreaming: return "play.tv.fill"
        case .largeDownload: return "arrow.down.doc.fill"
        case .largeUpload: return "arrow.up.doc.fill"
        case .custom: return "slider.horizontal.3"
        }
    }

    private var name: String {
        switch operation {
        case .basicBrowsing: return "Веб-серфинг"
        case .imageLoading: return "Загрузка изображений"
        case .videoStreaming: return "Видео стриминг"
        case .largeDownload: return "Загрузка файлов"
        case .largeUpload: return "Отправка файлов"
        case .custom: return "Пользовательская"
        }
    }

    private var description: String {
        switch operation {
        case .basicBrowsing: return "Текстовые сообщения, простые страницы"
        case .imageLoading: return "Соцсети, загрузка картинок"
        case .videoStreaming: return "Видеозвонки, потоковое видео"
        case .largeDownload: return "Скачивание больших файлов"
        case .largeUpload: return "Отправка больших файлов"
        case .custom: return "Кастомная проверка"
        }
    }

    private var color: Color {
        switch operation {
        case .basicBrowsing: return .green
        case .imageLoading: return .blue
        case .videoStreaming: return .purple
        case .largeDownload: return .orange
        case .largeUpload: return .red
        case .custom: return .gray
        }
    }
}

struct ResultBadge: View {
    let result: HealthCheckResult

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: result.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.title)

            VStack(alignment: .leading, spacing: 2) {
                Text(result.passed ? "Сеть подходит" : "Сеть не подходит")
                    .font(.headline)

                Text(result.passed ? "Операция может быть выполнена" : "Требуется лучшее соединение")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .foregroundStyle(result.passed ? .green : .orange)
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background((result.passed ? Color.green : Color.orange).opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        QualityCheckView()
    }
}
