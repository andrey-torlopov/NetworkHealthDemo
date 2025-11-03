# API Reference

Complete API documentation for NetworkHealth framework.

## Table of Contents

- [NetworkHealth](#networkhealth)
- [NetworkSnapshot](#networksnapshot)
- [NetworkQuality](#networkquality)
- [ConnectionType](#connectiontype)
- [NetworkRequirement](#networkrequirement)
- [HealthCheckResult](#healthcheckresult)
- [SpeedTester Protocol](#speedtester-protocol)
- [MockSpeedTester](#mockspeedtester)
- [SpeedTestCore Integration](#speedtestcore-integration)

---

## NetworkHealth

The main entry point for network monitoring.

### Methods

#### `snapshot()`

Get a single snapshot of current network state without speed measurements.

```swift
static func snapshot() async -> NetworkSnapshot
```

**Returns:** `NetworkSnapshot` with current network information

**Example:**
```swift
let snapshot = await NetworkHealth.snapshot()
print("Quality: \(snapshot.quality)")
```

**Use cases:**
- Quick network status check
- Lightweight monitoring without speed tests
- Initial network state query

---

#### `detailedSnapshot(speedTester:)`

Get detailed snapshot with speed measurements using a custom speed tester.

```swift
static func detailedSnapshot(
    speedTester: SpeedTester
) async -> NetworkSnapshot
```

**Parameters:**
- `speedTester`: Implementation of `SpeedTester` protocol for measuring speeds

**Returns:** `NetworkSnapshot` with speed measurements included

**Example:**
```swift
let mock = MockSpeedTester.excellent5G
let snapshot = await NetworkHealth.detailedSnapshot(speedTester: mock)
print("Download: \(snapshot.downloadSpeedMbps ?? 0) Mbps")
```

**Use cases:**
- Testing with mock data
- Custom speed testing implementation
- Integration with SpeedTestCore

---

#### `stream()`

Continuous monitoring of network state changes via AsyncStream.

```swift
static func stream() -> AsyncStream<NetworkSnapshot>
```

**Returns:** `AsyncStream<NetworkSnapshot>` that emits on network changes

**Example:**
```swift
Task {
    for await snapshot in NetworkHealth.stream() {
        print("Network changed: \(snapshot.quality)")
    }
}
```

**Behavior:**
- Emits on network path changes
- Automatically monitors connection status
- Continues until Task is cancelled
- Updates on WiFi/Cellular transitions

**Use cases:**
- Real-time network monitoring
- Adaptive streaming quality
- UI state synchronization

---

#### `isGoodEnoughFor(_:)`

Quick boolean check if network meets requirement.

```swift
static func isGoodEnoughFor(
    _ requirement: NetworkRequirement
) async -> Bool
```

**Parameters:**
- `requirement`: The `NetworkRequirement` to check against

**Returns:** `Bool` indicating if current quality meets requirement

**Example:**
```swift
let canStream = await NetworkHealth.isGoodEnoughFor(.videoStreaming)
if canStream {
    startVideo()
}
```

**Use cases:**
- Gate-keeping heavy operations
- Simple yes/no decisions
- Pre-flight checks

---

#### `check(requirement:)`

Detailed check with recommendations.

```swift
static func check(
    requirement: NetworkRequirement
) async -> HealthCheckResult
```

**Parameters:**
- `requirement`: The `NetworkRequirement` to validate

**Returns:** `HealthCheckResult` with detailed information

**Example:**
```swift
let result = await NetworkHealth.check(requirement: .videoStreaming)
if !result.passed {
    showWarning(result.recommendation)
}
```

**Use cases:**
- Providing user feedback
- Logging and analytics
- Detailed operation validation

---

## NetworkSnapshot

Represents a point-in-time network state.

### Properties

```swift
struct NetworkSnapshot: Sendable {
    let quality: NetworkQuality
    let connectionType: ConnectionType
    let isExpensive: Bool
    let isConstrained: Bool
    let interfaceName: String?
    let timestamp: Date
    let downloadSpeedMbps: Double?
    let uploadSpeedMbps: Double?
    let latency: TimeInterval?
}
```

#### `quality`
**Type:** `NetworkQuality`

The overall quality classification of the network.

**Values:**
- `.excellent` - Very fast, suitable for any operation
- `.good` - Fast, suitable for most operations
- `.moderate` - Adequate for browsing
- `.poor` - Slow, limited operations
- `.offline` - No connection

---

#### `connectionType`
**Type:** `ConnectionType`

The type of network connection.

**Values:**
- `.wifi` - WiFi connection
- `.cellular` - Mobile data (4G, 5G, etc.)
- `.ethernet` - Wired connection
- `.other` - Other connection types
- `.unknown` - Cannot determine

---

#### `isExpensive`
**Type:** `Bool`

Indicates if the connection is expensive (typically cellular data).

**Use cases:**
- Warning before large downloads
- Adjusting sync behavior
- Respecting user's data plan

---

#### `isConstrained`
**Type:** `Bool`

Indicates if the connection is constrained by system (Low Data Mode).

**Use cases:**
- Reducing data usage
- Disabling auto-play
- Deferring non-essential updates

---

#### `interfaceName`
**Type:** `String?`

Name of the network interface (e.g., "en0", "pdp_ip0").

**Example:**
```swift
let name = snapshot.interfaceName ?? "unknown"
print("Interface: \(name)")
```

---

#### `timestamp`
**Type:** `Date`

When this snapshot was captured.

---

#### `downloadSpeedMbps`
**Type:** `Double?`

Download speed in megabits per second (if measured).

**Note:** Only available when using `detailedSnapshot(speedTester:)`

---

#### `uploadSpeedMbps`
**Type:** `Double?`

Upload speed in megabits per second (if measured).

**Note:** Only available when using `detailedSnapshot(speedTester:)`

---

#### `latency`
**Type:** `TimeInterval?`

Network latency/ping in seconds (if measured).

**Example:**
```swift
if let latency = snapshot.latency {
    let ms = latency * 1000
    print("Ping: \(ms) ms")
}
```

---

## NetworkQuality

Enum representing network quality levels.

```swift
enum NetworkQuality: String, Sendable, Codable {
    case excellent
    case good
    case moderate
    case poor
    case offline
}
```

### Quality Thresholds

Based on download speed:

| Quality | Download Speed | Typical Use |
|---------|----------------|-------------|
| `excellent` | ≥ 50 Mbps | 4K streaming, large files |
| `good` | 10-50 Mbps | HD video, video calls |
| `moderate` | 1-10 Mbps | SD video, browsing |
| `poor` | < 1 Mbps | Text, basic browsing |
| `offline` | No connection | Offline mode |

### Methods

#### `isAtLeast(_:)`

Check if quality meets minimum threshold.

```swift
func isAtLeast(_ minimum: NetworkQuality) -> Bool
```

**Example:**
```swift
let quality = NetworkQuality.good
if quality.isAtLeast(.moderate) {
    print("Good enough for browsing")
}
```

---

## ConnectionType

Enum representing connection types.

```swift
enum ConnectionType: String, Sendable, Codable {
    case wifi
    case cellular
    case ethernet
    case other
    case unknown
}
```

### Properties

Each case provides:
- Raw string value for logging
- Codable conformance for persistence

**Example:**
```swift
switch snapshot.connectionType {
case .wifi:
    icon = "wifi"
case .cellular:
    icon = "antenna.radiowaves.left.and.right"
case .ethernet:
    icon = "cable.connector"
case .other, .unknown:
    icon = "network"
}
```

---

## NetworkRequirement

Represents requirements for specific operations.

```swift
enum NetworkRequirement: Sendable {
    case basicBrowsing
    case imageLoading
    case videoStreaming
    case largeDownload
    case largeUpload
    case custom(NetworkQuality)
}
```

### Built-in Requirements

#### `.basicBrowsing`
**Required Quality:** `.moderate`

Web browsing, text content, messaging.

---

#### `.imageLoading`
**Required Quality:** `.moderate`

Loading images, thumbnails, photo galleries.

---

#### `.videoStreaming`
**Required Quality:** `.good`

Video streaming, video calls, live streaming.

---

#### `.largeDownload`
**Required Quality:** `.excellent`

Large file downloads, software updates, backups.

---

#### `.largeUpload`
**Required Quality:** `.excellent`

Large file uploads, cloud backups, video uploads.

---

#### `.custom(NetworkQuality)`
**Required Quality:** Specified quality

Custom requirement for specific use cases.

**Example:**
```swift
let requirement = NetworkRequirement.custom(.good)
let result = await NetworkHealth.check(requirement: requirement)
```

---

## HealthCheckResult

Result of network quality validation.

```swift
struct HealthCheckResult: Sendable {
    let passed: Bool
    let currentQuality: NetworkQuality
    let requiredQuality: NetworkQuality
    let recommendation: String
}
```

### Properties

#### `passed`
**Type:** `Bool`

Whether the current quality meets the requirement.

---

#### `currentQuality`
**Type:** `NetworkQuality`

Current network quality level.

---

#### `requiredQuality`
**Type:** `NetworkQuality`

Required quality level for the operation.

---

#### `recommendation`
**Type:** `String`

Human-readable recommendation for user.

**Examples:**
- "Network quality is sufficient for this operation"
- "Network is too slow. Try connecting to WiFi"
- "No network connection. Please check your internet"

**Example:**
```swift
let result = await NetworkHealth.check(requirement: .videoStreaming)

if !result.passed {
    showAlert(
        title: "Slow Network",
        message: result.recommendation
    )
}
```

---

## SpeedTester Protocol

Protocol for implementing custom speed testers.

```swift
protocol SpeedTester: Sendable {
    func measureSpeed() async throws -> SpeedTestResult
}

struct SpeedTestResult: Sendable {
    let downloadSpeedMbps: Double
    let uploadSpeedMbps: Double
    let latency: TimeInterval
}
```

### Implementation Example

```swift
struct CustomSpeedTester: SpeedTester {
    func measureSpeed() async throws -> SpeedTestResult {
        // Perform actual speed test
        let downloadSpeed = try await measureDownload()
        let uploadSpeed = try await measureUpload()
        let ping = try await measurePing()
        
        return SpeedTestResult(
            downloadSpeedMbps: downloadSpeed,
            uploadSpeedMbps: uploadSpeed,
            latency: ping
        )
    }
}
```

---

## MockSpeedTester

Built-in mock implementation for testing.

```swift
struct MockSpeedTester: SpeedTester {
    let downloadSpeedMbps: Double
    let uploadSpeedMbps: Double
    let latencyMs: Double
}
```

### Static Profiles

#### `.excellent5G`
```swift
downloadSpeedMbps: 100
uploadSpeedMbps: 50
latencyMs: 15
```

#### `.goodLTE`
```swift
downloadSpeedMbps: 20
uploadSpeedMbps: 10
latencyMs: 50
```

#### `.moderate3G`
```swift
downloadSpeedMbps: 3
uploadSpeedMbps: 1
latencyMs: 150
```

#### `.poor2G`
```swift
downloadSpeedMbps: 0.3
uploadSpeedMbps: 0.1
latencyMs: 500
```

#### `.excellentWiFi`
```swift
downloadSpeedMbps: 150
uploadSpeedMbps: 75
latencyMs: 10
```

#### `.slowWiFi`
```swift
downloadSpeedMbps: 2
uploadSpeedMbps: 1
latencyMs: 200
```

### Custom Mock

```swift
let customMock = MockSpeedTester(
    downloadSpeedMbps: 25,
    uploadSpeedMbps: 12,
    latencyMs: 40
)

let snapshot = await NetworkHealth.detailedSnapshot(
    speedTester: customMock
)
```

---

## SpeedTestCore Integration

For real-world speed testing, integrate with SpeedTestCore.

### Setup

```swift
import SpeedTestCore
import Nevod

let config = SpeedTestConfig(
    serverURL: "http://localhost:8080",
    networking: NevodNetworking()
)
```

### Running Tests

#### Full Test

```swift
let result = try await SpeedTestCore.runFullTest(config: config)

print("Ping: \(result.ping?.latency ?? 0) ms")
print("Download: \(result.download?.speedMbps ?? 0) Mbps")
print("Upload: \(result.upload?.speedMbps ?? 0) Mbps")
```

#### Individual Tests

```swift
// Ping only
let pingResult = try await SpeedTestCore.runPingTest(config: config)

// Download only
let downloadResult = try await SpeedTestCore.runDownloadTest(config: config)

// Upload only
let uploadResult = try await SpeedTestCore.runUploadTest(config: config)
```

### SpeedTestResult

```swift
struct SpeedTestResult {
    let ping: PingResult?
    let download: TransferResult?
    let upload: TransferResult?
}

struct PingResult {
    let latency: TimeInterval
    let jitter: TimeInterval
}

struct TransferResult {
    let speedMbps: Double
    let bytesTransferred: Int
    let duration: TimeInterval
}
```

### Error Handling

```swift
do {
    let result = try await SpeedTestCore.runFullTest(config: config)
    handleResult(result)
} catch let error as NetworkError {
    switch error {
    case .serverUnreachable:
        print("Cannot reach server")
    case .timeout:
        print("Test timed out")
    case .invalidResponse:
        print("Invalid server response")
    default:
        print("Unknown error: \(error)")
    }
}
```

### Custom SpeedTester Implementation

```swift
struct RealSpeedTester: SpeedTester {
    let config: SpeedTestConfig
    
    func measureSpeed() async throws -> SpeedTestResult {
        let result = try await SpeedTestCore.runFullTest(config: config)
        
        return SpeedTestResult(
            downloadSpeedMbps: result.download?.speedMbps ?? 0,
            uploadSpeedMbps: result.upload?.speedMbps ?? 0,
            latency: result.ping?.latency ?? 0
        )
    }
}

// Use with NetworkHealth
let tester = RealSpeedTester(config: config)
let snapshot = await NetworkHealth.detailedSnapshot(speedTester: tester)
```

---

## Thread Safety

All NetworkHealth APIs are:
- **Sendable** - Safe to use across concurrency contexts
- **Async** - Non-blocking operations
- **Task-safe** - Can be called from any Task

```swift
// Safe to call from multiple tasks
Task {
    let snapshot1 = await NetworkHealth.snapshot()
}

Task {
    let snapshot2 = await NetworkHealth.snapshot()
}
```

---

## Performance Considerations

### Snapshot Performance

- `snapshot()` - Very fast (~10-50ms)
- `detailedSnapshot()` - Depends on SpeedTester implementation
- `stream()` - Low overhead, event-driven

### Best Practices

1. **Use `snapshot()` for quick checks:**
```swift
let quality = await NetworkHealth.snapshot().quality
```

2. **Use `stream()` for continuous monitoring:**
```swift
for await snapshot in NetworkHealth.stream() {
    // Handle updates
}
```

3. **Cache results when appropriate:**
```swift
var cachedSnapshot: NetworkSnapshot?
var cacheTime = Date()

func getSnapshot() async -> NetworkSnapshot {
    if let cached = cachedSnapshot,
       Date().timeIntervalSince(cacheTime) < 5 {
        return cached
    }
    
    let snapshot = await NetworkHealth.snapshot()
    cachedSnapshot = snapshot
    cacheTime = Date()
    return snapshot
}
```

4. **Cancel tasks properly:**
```swift
var monitoringTask: Task<Void, Never>?

func startMonitoring() {
    monitoringTask = Task {
        for await snapshot in NetworkHealth.stream() {
            handle(snapshot)
        }
    }
}

func stopMonitoring() {
    monitoringTask?.cancel()
    monitoringTask = nil
}
```

---

## Migration Guide

### From Other Libraries

If migrating from other network monitoring solutions:

**Reachability:**
```swift
// Old
let reachable = Reachability.isReachable()

// New
let snapshot = await NetworkHealth.snapshot()
let isOnline = snapshot.quality != .offline
```

**Network.framework directly:**
```swift
// Old
let monitor = NWPathMonitor()
monitor.pathUpdateHandler = { path in
    print("Status: \(path.status)")
}

// New
Task {
    for await snapshot in NetworkHealth.stream() {
        print("Quality: \(snapshot.quality)")
    }
}
```

---

## Resources

- [Quick Start Guide](QuickStart.md)
- [Installation Guide](Install.md)
- [GitHub Repository](https://github.com/andrey-torlopov/NetworkHealth)
- [Demo Project](../README.md)
