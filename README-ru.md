<h1 align="center">NetworkHealth Demo</h1>
<p align="center">
  <img src="Docs/banner.png" alt="Nevod banner" width="600"/>
</p>

<p align="center">
Демонстрационное iOS приложение для фреймворка <a href="https://github.com/andrey-torlopov/NetworkHealth">NetworkHealth</a>, предназначенного для мониторинга качества сети.
</p>

<p align="center">
  <a href="https://swift.org">
    <img src="https://img.shields.io/badge/Swift-6.1+-orange.svg?logo=swift" alt="Swift 6.1+" />
  </a>
  <a href="https://swift.org/package-manager/">
    <img src="https://img.shields.io/badge/SPM-compatible-green.svg?logo=swift" alt="SPM" />
  </a>
  <img src="https://img.shields.io/badge/platforms-iOS%2017%2B-orange.svg" alt="Platforms" />
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/license-MIT-lightgrey.svg" alt="License" />
  </a>
  <img src="https://img.shields.io/badge/concurrency-async%2Fawait-purple.svg" alt="Concurrency" />
</p>

<p align="center">
  <a href="README.md">English version</a>
</p>

## Описание

NetworkHealth Demo предоставляет набор примеров, демонстрирующих различные возможности мониторинга сети:

- Простые снапшоты состояния сети
- Тестирование с имитацией различных профилей скорости
- Непрерывный мониторинг с использованием AsyncStream
- Визуализация в реальном времени через Swift Charts
- Проверка качества сети для конкретных операций
- Реальные тесты скорости с помощью SpeedTestCore

## Возможности

### 1. Простой снапшот
Мгновенная информация о состоянии сети без измерения скорости:

```swift
let snapshot = await NetworkHealth.snapshot()
print("Качество: \(snapshot.quality)")
print("Подключение: \(snapshot.connectionType)")
```

### 2. Имитация тестов скорости
Тестирование с симулированными профилями (5G, LTE, 3G, 2G, WiFi):

```swift
let mockTester = MockSpeedTester.excellent5G
let snapshot = await NetworkHealth.detailedSnapshot(speedTester: mockTester)
```

### 3. Мониторинг сети
Непрерывный мониторинг через AsyncStream:

```swift
for await snapshot in NetworkHealth.stream() {
    print("Качество: \(snapshot.quality)")
}
```

### 4. Проверка качества
Проверка, подходит ли сеть для конкретных операций:

```swift
let result = await NetworkHealth.check(requirement: .videoStreaming)
if result.passed {
    // Начать стриминг
}
```

### 5. Реальные тесты скорости
Интеграция с [SpeedTestCore](https://github.com/andrey-torlopov/SpeedTestCore) и [SpeedLabServer](https://github.com/andrey-torlopov/SpeedLabServer):

```swift
let config = SpeedTestConfig(
    serverURL: "http://localhost:8080",
    networking: NevodNetworking()
)
let result = try await SpeedTestCore.runFullTest(config: config)
```

## Требования

- iOS 17.0+
- Swift 6.1+
- Xcode 16.0+

## Установка

1. Клонируйте репозиторий:
```bash
git clone https://github.com/andrey-torlopov/NetworkHealthDemo.git
cd NetworkHealthDemo
```

2. Откройте проект:
```bash
open NetworkHealthDemo.xcodeproj
```

3. Запустите на симуляторе или устройстве

## Структура проекта

```
NetworkHealthDemo/
├── NetworkHealthDemoApp.swift         # Точка входа
├── ContentView.swift                  # Главная навигация
└── Examples/
    ├── SimpleSnapshotView.swift       # Пример простого снапшота
    ├── MockSpeedTestView.swift        # Пример имитации тестов
    ├── MonitoringView.swift           # Непрерывный мониторинг
    ├── StreamMonitoringView.swift     # Стриминг с графиками
    ├── QualityCheckView.swift         # Проверка качества
    └── SpeedTestCoreView.swift        # Реальные тесты скорости
```

## Примеры использования

### Базовое состояние сети

```swift
import NetworkHealth

let snapshot = await NetworkHealth.snapshot()

switch snapshot.quality {
case .excellent:
    print("Отличное соединение")
case .good:
    print("Подходит для большинства операций")
case .moderate:
    print("Подходит для браузинга")
case .poor:
    print("Ограниченное подключение")
case .offline:
    print("Нет соединения")
}
```

### Непрерывный мониторинг

```swift
Task {
    for await snapshot in NetworkHealth.stream() {
        updateUI(with: snapshot)
    }
}
```

### Проверка для операций

```swift
let canStream = await NetworkHealth.isGoodEnoughFor(.videoStreaming)
if !canStream {
    showWarning("Сеть слишком медленная для видео")
}
```

## Реальные тесты скорости

### ⚠️ Важное замечание

Демо-приложение включает возможность реальных тестов скорости сети с использованием библиотеки [SpeedTestCore](https://github.com/andrey-torlopov/SpeedTestCore).

**Для работы этой функции требуется развернуть микросервер [SpeedLabServer](https://github.com/andrey-torlopov/SpeedLabServer).**

> **Без запущенного сервера функция реальных тестов скорости не будет работать и будет выдавать ошибки подключения.**

### Что такое SpeedLabServer?

[SpeedLabServer](https://github.com/andrey-torlopov/SpeedLabServer) — это легковесный Swift микросервер, предоставляющий эндпоинты для тестирования скорости сети. Он обрабатывает:
- Измерение ping/задержки
- Тесты скорости загрузки
- Тесты скорости выгрузки

### Инструкция по настройке

1. **Клонируйте и запустите SpeedLabServer:**

```bash
git clone https://github.com/andrey-torlopov/SpeedLabServer.git
cd SpeedLabServer
swift run Run
```

Сервер запустится по адресу `http://localhost:8080` по умолчанию.

2. **Настройте демо-приложение:**

Демо-приложение предварительно настроено на подключение к `http://localhost:8080`.

Для тестирования на реальном iOS устройстве обновите URL сервера в `SpeedTestCoreView.swift` на локальный IP-адрес вашего Mac:

```swift
serverURL: "http://192.168.1.x:8080"
```

### Как это работает

Демо использует [SpeedTestCore](https://github.com/andrey-torlopov/SpeedTestCore) для выполнения:
- **Ping Test** — измерение задержки сети в миллисекундах
- **Download Test** — измерение скорости загрузки в Мбит/с
- **Upload Test** — измерение скорости выгрузки в Мбит/с

Все тесты взаимодействуют с эндпоинтами SpeedLabServer для выполнения точных измерений.

### Решение проблем

Если вы видите ошибки подключения в разделе реальных тестов скорости:
1. Убедитесь, что SpeedLabServer запущен (`swift run Run` в директории сервера)
2. Проверьте, что URL сервера соответствует вашей конфигурации
3. Для тестирования на iOS устройстве убедитесь, что устройство и Mac находятся в одной сети
4. Проверьте, что `Info.plist` разрешает HTTP соединения (уже настроено в этом демо)

## UI компоненты

Демо включает переиспользуемые SwiftUI компоненты:

- `QualityBadge` - Визуальный индикатор качества
- `InfoCard` - Контейнер для информации
- `InfoRow` - Отображение пары ключ-значение
- `ResultBadge` - Индикатор статуса прохождения/провала

## Зависимости

- [NetworkHealth](https://github.com/andrey-torlopov/NetworkHealth) - Мониторинг качества сети
- [SpeedTestCore](https://github.com/andrey-torlopov/SpeedTestCore) - Фреймворк для тестов скорости
- Nevod - Сетевой слой

## Документация

Подробная информация о фреймворке NetworkHealth:

- [Руководство по установке](Docs/Install.md)
- [Быстрый старт](Docs/QuickStart.md)
- [Справочник API](Docs/API.md)

## Лицензия

MIT

## Автор

Андрей Торлопов

## Связанные проекты

- [NetworkHealth](https://github.com/andrey-torlopov/NetworkHealth) - Фреймворк для мониторинга сети
- [SpeedTestCore](https://github.com/andrey-torlopov/SpeedTestCore) - Движок для тестов скорости
- [SpeedLabServer](https://github.com/andrey-torlopov/SpeedLabServer) - Сервер для тестов скорости
