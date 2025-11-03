# Quick Start Guide

Get up and running with NetworkHealth in minutes. This guide covers the most common use cases.

## Table of Contents

- [Installation](#installation)
- [Basic Network Monitoring](#basic-network-monitoring)
- [Continuous Monitoring](#continuous-monitoring)
- [Quality Checks](#quality-checks)
- [Speed Testing](#speed-testing)
- [SwiftUI Integration](#swiftui-integration)
- [Common Patterns](#common-patterns)

## Installation

Add NetworkHealth to your project via Swift Package Manager:

```
https://github.com/andrey-torlopov/NetworkHealth
```

See [Installation Guide](Install.md) for detailed instructions.

## Basic Network Monitoring

### Simple Snapshot

Get instant network state without speed measurements:

```swift
import NetworkHealth

// Get current network state
let snapshot = await NetworkHealth.snapshot()

print("Quality: \(snapshot.quality)")           // .excellent, .good, .moderate, .poor, .offline
print("Connection: \(snapshot.connectionType)")  // .wifi, .cellular, .ethernet, .other, .unknown
print("Expensive: \(snapshot.isExpensive)")      // true/false
print("Constrained: \(snapshot.isConstrained)")  // true/false
```

### Quality Levels

NetworkHealth provides five quality levels:

| Quality | Description | Typical Use |
|---------|-------------|-------------|
| `excellent` | Very fast connection | HD streaming, large downloads |
| `good` | Fast connection | Video calls, streaming |
| `moderate` | Adequate connection | Web browsing, messaging |
| `poor` | Slow connection | Basic text, low-quality media |
| `offline` | No connection | Offline mode |

### Example: Show Network Status

```swift
func updateNetworkStatus() async {
    let snapshot = await NetworkHealth.snapshot()
    
    switch snapshot.quality {
    case .excellent:
        statusLabel.text = "Perfect connection! 🟢"
    case .good:
        statusLabel.text = "Good connection 🔵"
    case .moderate:
        statusLabel.text = "Fair connection 🟡"
    case .poor:
        statusLabel.text = "Slow connection 🟠"
    case .offline:
        statusLabel.text = "No connection 🔴"
    }
}
```

## Continuous Monitoring

Monitor network changes in real-time using AsyncStream:

```swift
import NetworkHealth

Task {
    for await snapshot in NetworkHealth.stream() {
        print("Network changed: \(snapshot.quality)")
        updateUI(with: snapshot)
    }
}
```

### SwiftUI Example

```swift
import SwiftUI
import NetworkHealth

struct NetworkMonitorView: View {
    @State private var currentQuality: NetworkQuality = .offline
    @State private var connectionType: ConnectionType = .unknown
    
    var body: some View {
        VStack {
            Text("Quality: \(currentQuality.rawValue)")
            Text("Type: \(connectionType.rawValue)")
        }
        .task {
            for await snapshot in NetworkHealth.stream() {
                currentQuality = snapshot.quality
                connectionType = snapshot.connectionType
            }
        }
    }
}
```

### ViewModel Pattern

```swift
@Observable
final class NetworkViewModel {
    var currentSnapshot: NetworkSnapshot?
    private var monitoringTask: Task<Void, Never>?
    
    func startMonitoring() {
        monitoringTask = Task {
            for await snapshot in NetworkHealth.stream() {
                currentSnapshot = snapshot
            }
        }
    }
    
    func stopMonitoring() {
        monitoringTask?.cancel()
        monitoringTask = nil
    }
    
    deinit {
        stopMonitoring()
    }
}
```

## Quality Checks

Validate if network is suitable for specific operations:

### Basic Check

```swift
// Check if network is good enough
let canStream = await NetworkHealth.isGoodEnoughFor(.videoStreaming)

if canStream {
    startVideoStream()
} else {
    showWarning("Network too slow for video")
}
```

### Detailed Check

```swift
let result = await NetworkHealth.check(requirement: .videoStreaming)

print("Passed: \(result.passed)")
print("Current: \(result.currentQuality)")
print("Required: \(result.requiredQuality)")
print("Recommendation: \(result.recommendation)")
```

### Built-in Requirements

```swift
enum NetworkRequirement {
    case basicBrowsing      // Requires: .moderate
    case imageLoading       // Requires: .moderate
    case videoStreaming     // Requires: .good
    case largeDownload      // Requires: .excellent
    case largeUpload        // Requires: .excellent
}
```

### Custom Requirements

```swift
// Define custom requirement
let requirement = NetworkRequirement.custom(.good)
let result = await NetworkHealth.check(requirement: requirement)
```

### Example: Conditional Operations

```swift
func uploadLargeFile(_ file: Data) async throws {
    // Check before upload
    let result = await NetworkHealth.check(requirement: .largeUpload)
    
    if !result.passed {
        throw NetworkError.insufficientQuality(
            recommendation: result.recommendation
        )
    }
    
    // Proceed with upload
    try await actualUpload(file)
}
```

## Speed Testing

### Using MockSpeedTester

For testing without actual network requests:

```swift
import NetworkHealth

// Choose a mock profile
let mockTester = MockSpeedTester.excellent5G

// Get detailed snapshot
let snapshot = await NetworkHealth.detailedSnapshot(speedTester: mockTester)

print("Download: \(snapshot.downloadSpeedMbps ?? 0) Mbps")
print("Upload: \(snapshot.uploadSpeedMbps ?? 0) Mbps")
print("Latency: \(snapshot.latency ?? 0) ms")
```

### Available Mock Profiles

```swift
MockSpeedTester.excellent5G    // 100 Mbps, 15ms
MockSpeedTester.goodLTE        // 20 Mbps, 50ms
MockSpeedTester.moderate3G     // 3 Mbps, 150ms
MockSpeedTester.poor2G         // 0.3 Mbps, 500ms
MockSpeedTester.excellentWiFi  // 150 Mbps, 10ms
MockSpeedTester.slowWiFi       // 2 Mbps, 200ms
```

### Using SpeedTestCore

For real-world speed testing:

```swift
import SpeedTestCore
import Nevod

// Configure
let config = SpeedTestConfig(
    serverURL: "http://localhost:8080",
    networking: NevodNetworking()
)

// Run test
do {
    let result = try await SpeedTestCore.runFullTest(config: config)
    
    print("Ping: \(result.ping?.latency ?? 0) ms")
    print("Download: \(result.download?.speedMbps ?? 0) Mbps")
    print("Upload: \(result.upload?.speedMbps ?? 0) Mbps")
    
} catch {
    print("Test failed: \(error)")
}
```

**Note:** Requires [SpeedLabServer](https://github.com/andrey-torlopov/SpeedLabServer) running. See [Installation Guide](Install.md#speedlabserver-setup).

## SwiftUI Integration

### Quality Badge Component

```swift
struct QualityBadge: View {
    let quality: NetworkQuality
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            Text(quality.rawValue.capitalized)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.2))
        .cornerRadius(8)
    }
    
    var color: Color {
        switch quality {
        case .excellent: return .green
        case .good: return .blue
        case .moderate: return .orange
        case .poor: return .red
        case .offline: return .gray
        }
    }
}
```

### Network Status View

```swift
struct NetworkStatusView: View {
    @State private var snapshot: NetworkSnapshot?
    
    var body: some View {
        VStack(spacing: 16) {
            if let snapshot {
                QualityBadge(quality: snapshot.quality)
                
                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(
                        icon: "wifi",
                        label: "Type",
                        value: snapshot.connectionType.rawValue
                    )
                    InfoRow(
                        icon: "dollarsign.circle",
                        label: "Expensive",
                        value: snapshot.isExpensive ? "Yes" : "No"
                    )
                    InfoRow(
                        icon: "speedometer",
                        label: "Constrained",
                        value: snapshot.isConstrained ? "Yes" : "No"
                    )
                }
            } else {
                ProgressView("Loading...")
            }
        }
        .task {
            snapshot = await NetworkHealth.snapshot()
        }
    }
}
```

### Live Monitoring View

```swift
struct LiveNetworkView: View {
    @State private var snapshots: [NetworkSnapshot] = []
    @State private var isMonitoring = false
    private var monitoringTask: Task<Void, Never>?
    
    var body: some View {
        VStack {
            Button(isMonitoring ? "Stop" : "Start") {
                isMonitoring.toggle()
                if isMonitoring {
                    startMonitoring()
                } else {
                    stopMonitoring()
                }
            }
            
            List(snapshots, id: \.timestamp) { snapshot in
                HStack {
                    QualityBadge(quality: snapshot.quality)
                    Spacer()
                    Text(snapshot.timestamp.formatted())
                }
            }
        }
    }
    
    func startMonitoring() {
        Task {
            for await snapshot in NetworkHealth.stream() {
                snapshots.insert(snapshot, at: 0)
                if snapshots.count > 20 {
                    snapshots.removeLast()
                }
            }
        }
    }
    
    func stopMonitoring() {
        monitoringTask?.cancel()
    }
}
```

## Common Patterns

### Check Before Heavy Operation

```swift
func downloadLargeVideo() async throws {
    // Check network first
    guard await NetworkHealth.isGoodEnoughFor(.largeDownload) else {
        throw NetworkError.networkTooSlow
    }
    
    // Proceed with download
    try await performDownload()
}
```

### Adaptive Quality

```swift
func selectVideoQuality() async -> VideoQuality {
    let snapshot = await NetworkHealth.snapshot()
    
    switch snapshot.quality {
    case .excellent:
        return .uhd4K
    case .good:
        return .fullHD
    case .moderate:
        return .hd720
    case .poor:
        return .sd480
    case .offline:
        return .offline
    }
}
```

### Monitor During Operation

```swift
func streamVideo() async {
    Task {
        for await snapshot in NetworkHealth.stream() {
            adjustStreamQuality(for: snapshot.quality)
        }
    }
    
    // Start streaming
    await performStreaming()
}
```

### Warn User About Expensive Connection

```swift
func checkBeforeDownload() async {
    let snapshot = await NetworkHealth.snapshot()
    
    if snapshot.isExpensive && snapshot.connectionType == .cellular {
        let proceed = await showAlert(
            "You're on cellular data. Download may use significant data."
        )
        
        if proceed {
            await startDownload()
        }
    } else {
        await startDownload()
    }
}
```

### Periodic Checks

```swift
func periodicNetworkCheck() {
    Timer.publish(every: 30, on: .main, in: .common)
        .autoconnect()
        .sink { _ in
            Task {
                let snapshot = await NetworkHealth.snapshot()
                updateUIForQuality(snapshot.quality)
            }
        }
}
```

## Error Handling

```swift
func safeNetworkCheck() async {
    do {
        let snapshot = await NetworkHealth.snapshot()
        handleSnapshot(snapshot)
    } catch {
        print("Network check failed: \(error)")
        // Handle error appropriately
    }
}
```

## Testing

### Using Mocks in Tests

```swift
import XCTest
import NetworkHealth

final class NetworkTests: XCTestCase {
    func testPoorNetworkHandling() async throws {
        // Use mock tester
        let mock = MockSpeedTester.poor2G
        let snapshot = await NetworkHealth.detailedSnapshot(speedTester: mock)
        
        XCTAssertEqual(snapshot.quality, .poor)
        XCTAssertLessThan(snapshot.downloadSpeedMbps ?? 0, 1.0)
    }
}
```

## Next Steps

- [API Reference](API.md) - Complete API documentation
- [Installation Guide](Install.md) - Detailed setup instructions
- [Demo Project](../README.md) - Full working examples

## Resources

- [NetworkHealth GitHub](https://github.com/andrey-torlopov/NetworkHealth)
- [SpeedTestCore GitHub](https://github.com/andrey-torlopov/SpeedTestCore)
- [SpeedLabServer GitHub](https://github.com/andrey-torlopov/SpeedLabServer)
