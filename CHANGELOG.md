# Change Log
All notable changes to this project will be documented in this file.

This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased](https://github.com/openium/SwiftiumTestingKit/compare/v0.6.0...HEAD)
### Added
- Swift Package Manager support
- Add request and response time to PilotableServer

### Changed

### Removed
- Carthage support
- SimulatorStatusBarMagic (run `xcrun simctl status_bar` to see what Xcode provide instead)

## [0.6.2](https://github.com/openium/SwiftiumTestingKit/compare/v0.6.2...v0.6.1)
### Added

### Changed

### Removed
Debug logs

## [0.6.1](https://github.com/openium/SwiftiumTestingKit/compare/v0.6.1...v0.6.0)
### Added

### Changed
Fixed search for text containing \n\n

### Removed

## [0.6.0](https://github.com/openium/SwiftiumTestingKit/compare/v0.6.0...v0.5.0)
### Added
Add ability for solo to waitForAnimationsToFinish

### Changed
attachScreenshot now prefixes the attachment name with Locale identifier and device name

### Removed
latest tag "update" and force push making clones not able to fetch smoothly 

## [0.5.0](https://github.com/openium/SwiftiumTestingKit/compare/v0.5.0...v0.4.0)
### Added
Add default carrier name

### Changed

### Removed


## [0.4.0](https://github.com/openium/SwiftiumTestingKit/compare/v0.4.0...v0.3.0)
### Added
Attach screenshot using XCUIScreen.main.screenshot() and a name

### Changed
Update SimulatorStatusMagic to ios13 branch

### Removed


## [0.3.0](https://github.com/openium/SwiftiumTestingKit/compare/v0.3.0...v0.4.0)
### Added
Support for Swift 5.1

### Changed
Added a test to validate searching of test with UITextView 

### Removed

## [0.2.0](https://github.com/openium/SwiftiumTestingKit/compare/v0.2.0...v0.3.0)
### Added

### Changed
Swift 5 support (dependency updates)

### Removed


## [0.1.8](https://github.com/openium/SwiftiumTestingKit/compare/v0.1.8...v0.2.0)
### Added

### Changed
Fix issue when tapping accessibility element's view not available yet

### Removed

## [0.1.7](https://github.com/openium/SwiftiumTestingKit/compare/v0.1.7...v0.1.8)
### Added
Allow pilotable server to specify responses headers for all requests and responses headers for each request

### Changed

### Removed

## [0.1.6](https://github.com/openium/SwiftiumTestingKit/compare/v0.1.6...v0.1.7)
### Added

### Changed
Fixed search for text containing \n 

### Removed

## [0.1.5](https://github.com/openium/SwiftiumTestingKit/compare/v0.1.5...v0.1.6)
### Added

### Changed
Allow pilotable server to have an empty data as input to manage properly the 204 HTTP code


## [0.1.4](https://github.com/openium/SwiftiumTestingKit/compare/v0.1.4...v0.1.5)
### Added

### Changed
Replace NSPredicate with == / hasSuffix / hasPrefix
Expose solo.window

### Removed

## [0.1.3](https://github.com/openium/SwiftiumTestingKit/compare/v0.1.3...v0.1.4)
### Added

### Changed
Fix accessibility enabled too late
Fix network call cleaned when server released

### Removed

## [0.1.2](https://github.com/openium/SwiftiumTestingKit/compare/v0.1.2...v0.1.3)
### Added

### Changed
Fix mutliple queued responses not removed from queue

### Removed

## [0.1.1](https://github.com/openium/SwiftiumTestingKit/compare/v0.1.1...v0.1.2)
### Added

### Changed
Fix resource path validation when queueing network request
Fix incorrect default http code for redirections

### Removed

## Initial Release (0.1) - 2018-09-20

