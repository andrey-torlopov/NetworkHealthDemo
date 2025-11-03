# Installation Guide

This guide covers installation and setup for NetworkHealth framework and related components.

## Table of Contents

- [NetworkHealth Framework](#networkhealth-framework)
- [SpeedTestCore Integration](#speedtestcore-integration)
- [SpeedLabServer Setup](#speedlabserver-setup)
- [Demo Project](#demo-project)
- [Troubleshooting](#troubleshooting)

## NetworkHealth Framework

### Swift Package Manager (Recommended)

1. In Xcode, open your project
2. Go to **File → Add Package Dependencies**
3. Enter the repository URL:
```
https://github.com/andrey-torlopov/NetworkHealth
```
4. Choose version rule (recommended: Up to Next Major)
5. Click **Add Package**

### Package.swift

Add to your `Package.swift`:

```swift
dependencies: [
    .package(
        url: "https://github.com/andrey-torlopov/NetworkHealth",
        from: "1.0.0"
    )
]

targets: [
    .target(
        name: "YourTarget",
        dependencies: ["NetworkHealth"]
    )
]
```

### Import

```swift
import NetworkHealth
```

## SpeedTestCore Integration

### Prerequisites

- iOS 17.0+ / macOS 14.0+
- Swift 6.1+
- Xcode 16.0+

### Installation

#### Via Swift Package Manager

In Xcode:
1. **File → Add Package Dependencies**
2. Enter URL:
```
https://github.com/andrey-torlopov/SpeedTestCore
```
3. Select version and add

#### Package.swift

```swift
dependencies: [
    .package(
        url: "https://github.com/andrey-torlopov/SpeedTestCore",
        from: "1.0.0"
    )
]

targets: [
    .target(
        name: "YourTarget",
        dependencies: ["SpeedTestCore"]
    )
]
```

### Networking Layer

SpeedTestCore requires a networking implementation. We recommend Nevod:

```swift
dependencies: [
    .package(
        url: "https://github.com/andrey-torlopov/Nevod",
        from: "1.0.0"
    )
]
```

### Basic Setup

```swift
import SpeedTestCore
import Nevod

let config = SpeedTestConfig(
    serverURL: "http://your-server:8080",
    networking: NevodNetworking()
)

let result = try await SpeedTestCore.runFullTest(config: config)
```

## SpeedLabServer Setup

SpeedLabServer is the backend for SpeedTestCore. You need to run it locally or on a server.

### Local Development Setup

1. **Clone the repository:**
```bash
git clone https://github.com/andrey-torlopov/SpeedLabServer.git
cd SpeedLabServer
```

2. **Build and run:**
```bash
swift build
swift run
```

3. **Verify server is running:**
```bash
curl http://localhost:8080/health
```

Expected response:
```json
{
  "status": "ok"
}
```

### Server Configuration

Default configuration:
- **Host:** `0.0.0.0`
- **Port:** `8080`
- **Ping endpoint:** `/ping`
- **Download endpoint:** `/download`
- **Upload endpoint:** `/upload`
- **Health check:** `/health`

### Custom Port

```bash
swift run SpeedLabServer --port 9000
```

### Production Deployment

For production use:

1. **Build release version:**
```bash
swift build -c release
```

2. **Run as service:**
```bash
.build/release/SpeedLabServer --host 0.0.0.0 --port 8080
```

3. **Using Docker (if available):**
```dockerfile
FROM swift:latest
WORKDIR /app
COPY . .
RUN swift build -c release
EXPOSE 8080
CMD [".build/release/SpeedLabServer"]
```

## Demo Project

### Clone and Run

1. **Clone the demo:**
```bash
git clone https://github.com/andrey-torlopov/NetworkHealthDemo.git
cd NetworkHealthDemo
```

2. **Open in Xcode:**
```bash
open NetworkHealthDemo.xcodeproj
```

3. **Select target and run**

### Configure for Real Testing

To use real speed tests:

1. Start SpeedLabServer (see above)
2. Open `SpeedTestCoreView.swift`
3. Verify server URL:
```swift
serverURL: "http://localhost:8080"
```

4. For iOS device testing, use your Mac's IP:
```swift
serverURL: "http://192.168.1.x:8080"
```

### Info.plist Configuration

For local testing with `http://` (not `https://`), ensure `Info.plist` contains:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

**Note:** For production, use HTTPS and proper security settings.

## Troubleshooting

### NetworkHealth Not Found

**Problem:** Xcode cannot find NetworkHealth module

**Solution:**
1. Check package is added in **Project → Package Dependencies**
2. Clean build folder: **Product → Clean Build Folder**
3. Reset package cache: **File → Packages → Reset Package Caches**
4. Restart Xcode

### SpeedTestCore Connection Failed

**Problem:** Cannot connect to SpeedLabServer

**Solution:**
1. Verify server is running: `curl http://localhost:8080/health`
2. Check firewall settings
3. For iOS device, use Mac's local IP address
4. Ensure `NSAppTransportSecurity` is configured for HTTP

### Build Errors with Swift 6

**Problem:** Concurrency warnings or errors

**Solution:**
NetworkHealth and SpeedTestCore are Swift 6 compatible. Ensure:
1. Xcode 16.0+
2. Swift Language Version is 6.0
3. Project settings: **Build Settings → Swift Language Version → Swift 6**

### Server Port Already in Use

**Problem:** SpeedLabServer fails to start

**Solution:**
```bash
# Find process using port 8080
lsof -i :8080

# Kill the process
kill -9 <PID>

# Or use different port
swift run SpeedLabServer --port 9000
```

### Simulator vs Device

**NetworkHealth:**
- Works on both simulator and device
- Real network conditions best tested on device

**SpeedTestCore:**
- Simulator: Use `localhost` or `127.0.0.1`
- Device: Use your Mac's IP address (e.g., `192.168.1.5`)

### Permission Issues

If you get network permission errors:

1. Check `Info.plist` for network usage descriptions
2. For macOS apps, enable network entitlements:
```xml
<key>com.apple.security.network.client</key>
<true/>
```

## Minimum Requirements

| Component | iOS | macOS | Swift | Xcode |
|-----------|-----|-------|-------|-------|
| NetworkHealth | 17.0+ | 14.0+ | 6.1+ | 16.0+ |
| SpeedTestCore | 17.0+ | 14.0+ | 6.1+ | 16.0+ |
| SpeedLabServer | - | 14.0+ | 6.1+ | 16.0+ |
| Demo App | 17.0+ | - | 6.1+ | 16.0+ |

## Next Steps

- [Quick Start Guide](QuickStart.md) - Get started with basic examples
- [API Reference](API.md) - Detailed API documentation
- [GitHub Issues](https://github.com/andrey-torlopov/NetworkHealth/issues) - Report problems
