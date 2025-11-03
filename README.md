<h1 align="center">NetworkHealth Demo</h1>
<p align="center">
  <img src="Docs/banner.png" alt="Nevod banner" width="600"/>
</p>

<p align="center">
A demonstration iOS application showcasing the <a href="https://github.com/andrey-torlopov/NetworkHealth">NetworkHealth</a> framework capabilities for network quality monitoring.
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
  <a href="README-ru.md">Русская версия</a>
</p>

## Overview

NetworkHealth Demo provides a comprehensive set of examples demonstrating various network monitoring capabilities:

- Simple network state snapshots
- Mock speed testing with different profiles
- Continuous network monitoring with AsyncStream
- Real-time visualization with Swift Charts
- Network quality validation for specific operations
- Real-world speed testing with SpeedTestCore

## Features

### 1. Simple Snapshot
Get instant network state information without speed measurements:

```swift
let snapshot = await NetworkHealth.snapshot()
print("Quality: \(snapshot.quality)")
print("Connection: \(snapshot.connectionType)")
```

### 2. Mock Speed Testing
Test with simulated network profiles (5G, LTE, 3G, 2G, WiFi):

```swift
let mockTester = MockSpeedTester.excellent5G
let snapshot = await NetworkHealth.detailedSnapshot(speedTester: mockTester)
```

### 3. Network Monitoring
Continuous monitoring with AsyncStream:

```swift
for await snapshot in NetworkHealth.stream() {
    print("Quality: \(snapshot.quality)")
}
```

### 4. Quality Validation
Check if network is suitable for specific operations:

```swift
let result = await NetworkHealth.check(requirement: .videoStreaming)
if result.passed {
    // Start streaming
}
```

### 5. Real Speed Testing
Integration with [SpeedTestCore](https://github.com/andrey-torlopov/SpeedTestCore) and [SpeedLabServer](https://github.com/andrey-torlopov/SpeedLabServer):

```swift
let config = SpeedTestConfig(
    serverURL: "http://localhost:8080",
    networking: NevodNetworking()
)
let result = try await SpeedTestCore.runFullTest(config: config)
```

## Requirements

- iOS 17.0+
- Swift 6.1+
- Xcode 16.0+

## Installation

1. Clone the repository:
```bash
git clone https://github.com/andrey-torlopov/NetworkHealthDemo.git
cd NetworkHealthDemo
```

2. Open the project:
```bash
open NetworkHealthDemo.xcodeproj
```

3. Build and run on simulator or device

## Project Structure

```
NetworkHealthDemo/
├── NetworkHealthDemoApp.swift         # App entry point
├── ContentView.swift                  # Main navigation
└── Examples/
    ├── SimpleSnapshotView.swift       # Basic snapshot example
    ├── MockSpeedTestView.swift        # Mock testing example
    ├── MonitoringView.swift           # Continuous monitoring
    ├── StreamMonitoringView.swift     # Streaming with charts
    ├── QualityCheckView.swift         # Quality validation
    └── SpeedTestCoreView.swift        # Real speed testing
```

## Usage Examples

### Basic Network State

```swift
import NetworkHealth

let snapshot = await NetworkHealth.snapshot()

switch snapshot.quality {
case .excellent:
    print("Perfect connection")
case .good:
    print("Good for most operations")
case .moderate:
    print("Suitable for browsing")
case .poor:
    print("Limited connectivity")
case .offline:
    print("No connection")
}
```

### Continuous Monitoring

```swift
Task {
    for await snapshot in NetworkHealth.stream() {
        updateUI(with: snapshot)
    }
}
```

### Operation Validation

```swift
let canStream = await NetworkHealth.isGoodEnoughFor(.videoStreaming)
if !canStream {
    showWarning("Network too slow for video")
}
```

## Real-World Speed Testing

### ⚠️ Important Notice

The demo application includes real network speed testing capabilities using the [SpeedTestCore](https://github.com/andrey-torlopov/SpeedTestCore) library.

**This feature requires deploying the [SpeedLabServer](https://github.com/andrey-torlopov/SpeedLabServer) microserver.**

> **Without the running server, the Real Speed Testing feature will not work and will display connection errors.**

### What is SpeedLabServer?

[SpeedLabServer](https://github.com/andrey-torlopov/SpeedLabServer) is a lightweight Swift microserver that provides endpoints for network speed testing. It handles:
- Ping/latency measurements
- Download speed tests
- Upload speed tests

### Setup Instructions

1. **Clone and run SpeedLabServer:**

```bash
git clone https://github.com/andrey-torlopov/SpeedLabServer.git
cd SpeedLabServer
swift run Run
```

The server will start on `http://localhost:8080` by default.

2. **Configure the demo app:**

The demo app is pre-configured to connect to `http://localhost:8080`.

For testing on a real iOS device, update the server URL in `SpeedTestCoreView.swift` to your Mac's local IP address:

```swift
serverURL: "http://192.168.1.x:8080"
```

### How It Works

The demo uses [SpeedTestCore](https://github.com/andrey-torlopov/SpeedTestCore) to perform:
- **Ping Test** - Measures network latency in milliseconds
- **Download Test** - Measures download speed in Mbps
- **Upload Test** - Measures upload speed in Mbps

All tests communicate with SpeedLabServer endpoints to perform accurate measurements.

### Troubleshooting

If you see connection errors in the Real Speed Testing section:
1. Verify SpeedLabServer is running (`swift run Run` in the server directory)
2. Check the server URL matches your configuration
3. For iOS device testing, ensure your device and Mac are on the same network
4. Verify `Info.plist` allows HTTP connections (already configured in this demo)

## UI Components

The demo includes reusable SwiftUI components:

- `QualityBadge` - Visual quality indicator
- `InfoCard` - Information container
- `InfoRow` - Key-value row display
- `ResultBadge` - Pass/fail status indicator

## Dependencies

- [NetworkHealth](https://github.com/andrey-torlopov/NetworkHealth) - Network quality monitoring
- [SpeedTestCore](https://github.com/andrey-torlopov/SpeedTestCore) - Speed testing framework
- Nevod - Networking layer

## Documentation

For detailed information about NetworkHealth framework:

- [Installation Guide](Docs/Install.md)
- [Quick Start](Docs/QuickStart.md)
- [API Reference](Docs/API.md)

## License

MIT

## Author

Andrey Torlopov

## Related Projects

- [NetworkHealth](https://github.com/andrey-torlopov/NetworkHealth) - Network monitoring framework
- [SpeedTestCore](https://github.com/andrey-torlopov/SpeedTestCore) - Speed testing engine
- [SpeedLabServer](https://github.com/andrey-torlopov/SpeedLabServer) - Speed test server
