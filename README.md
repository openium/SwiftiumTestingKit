# SwiftiumKit

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage) 

This "Kit" adds many feature to speed up iOS app testing. It allows to write Unit tests for testing view controllers "quicker than UI Tests".

## Example :

````
func testWaitForTapableTextAndTapIt_shouldHaveTap() {
    // Given
    let solo = STKSolo()
    let viewController = ViewController()
    solo.showViewControllerInCleanWindow(viewController)

    // When
    let waitForText = solo.waitFor(tappableText:"Hello button", andTapIt:true)
    
    // Expect
    XCTAssertTrue(waitForText)
    XCTAssertTrue(viewController.tapped)
}
````

see more in [STKSoloTests.swift](https://github.com/openium/SwiftiumTestingKit/blob/master/STKTestAppTests/STKSoloTests.swift)

## Setup

Have SwiftiumTestingKit in your cartfile, and add a "Carthage copy frameworks" script in the Unit Test Bundle target with SwiftiumTestingKit.framework, 
KIF.framework, OHHTTPStubs.framework, and SimulatorStatusMagiciOS.framework copied to the xctest bundle
# To be done :

Add CONTRIBUTING & CODE_OF_CONDUCT files

## Change log

We follow [keepachangelog.com](http://keepachangelog.com) recommandations for our [CHANGELOG]

[CHANGELOG]: CHANGELOG.md
