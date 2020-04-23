# SwiftiumTestingKit

This "Kit" adds many feature to speed up iOS app testing. It allows to write Unit tests for testing view controllers "quicker than UI Tests".

## Example :

```swift
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
```

see more in [STKSoloTests.swift](https://github.com/openium/SwiftiumTestingKit/blob/master/STKTestAppTests/STKSoloTests.swift)

## Installation 

### Swift Package Manager

See [official documentation](https://github.com/apple/swift-package-manager/tree/master/Documentation)

### Setup

Add the following libraries to your test target :
- `OHHTTPStubs`
- `SwiftiumTestingKit`
- `KIF`

# To be done :

Add CONTRIBUTING & CODE_OF_CONDUCT files

## Change log

We follow [keepachangelog.com](http://keepachangelog.com) recommandations for our [CHANGELOG]

[CHANGELOG]: CHANGELOG.md
