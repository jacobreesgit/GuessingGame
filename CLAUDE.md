# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an iOS SwiftUI application called "GuessingGame" that integrates with Firebase for backend services. The app is configured with Firebase Authentication and Firebase Database.

## Build Commands

### Build for Simulator
```bash
# Build for iPhone 16 simulator
mcp__XcodeBuildMCP__build_sim_name_proj({
  projectPath: "/Users/jacobrees/Documents/GuessingGame/GuessingGame.xcodeproj",
  scheme: "GuessingGame",
  simulatorName: "iPhone 16"
})

# Build and run on iPhone 16 simulator
mcp__XcodeBuildMCP__build_run_sim_name_proj({
  projectPath: "/Users/jacobrees/Documents/GuessingGame/GuessingGame.xcodeproj", 
  scheme: "GuessingGame",
  simulatorName: "iPhone 16"
})
```

### Build for Device
```bash
# Build for physical device
mcp__XcodeBuildMCP__build_dev_proj({
  projectPath: "/Users/jacobrees/Documents/GuessingGame/GuessingGame.xcodeproj",
  scheme: "GuessingGame"
})
```

### Run Tests
```bash
# Run tests on iPhone 16 simulator
mcp__XcodeBuildMCP__test_sim_name_proj({
  projectPath: "/Users/jacobrees/Documents/GuessingGame/GuessingGame.xcodeproj",
  scheme: "GuessingGame", 
  simulatorName: "iPhone 16"
})
```

### Clean Build
```bash
mcp__XcodeBuildMCP__clean_proj({
  projectPath: "/Users/jacobrees/Documents/GuessingGame/GuessingGame.xcodeproj",
  scheme: "GuessingGame"
})
```

## Architecture

### Project Structure
- **GuessingGame.xcodeproj**: Xcode project file with single scheme "GuessingGame"
- **GuessingGame/**: Main app source directory containing SwiftUI views and app configuration
- **GuessingGameApp.swift**: Main app entry point with Firebase configuration
- **ContentView.swift**: Primary SwiftUI view (currently basic Hello World template)
- **GoogleService-Info.plist**: Firebase configuration file
- **GuessingGame.entitlements**: App entitlements file

### Dependencies
The project uses Swift Package Manager with Firebase SDK integration:
- **FirebaseAuth**: User authentication
- **FirebaseDatabase**: Real-time database
- Additional Firebase dependencies automatically resolved

### Deployment Target
- iOS 26.0 minimum deployment target
- Supports iPhone and iPad (device families 1,2)
- Bundle identifier: `jaba.GuessingGame`

### Key Configuration
- Development team: 5RP4WRQ9V2
- Automatic code signing enabled
- SwiftUI with iOS 26.0 target
- Firebase integration configured in app initialization