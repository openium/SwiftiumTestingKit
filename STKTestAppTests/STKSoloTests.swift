//
//  STKSoloTests.swift
//  STKTestAppTests
//
//  Created by Richard Bergoin on 19/09/2018.
//  Copyright © 2018 Openium. All rights reserved.
//

import XCTest
import SwiftiumTestingKit

@testable import STKTestApp

class STKSoloTests: XCTestCase {
    
    var sut: STKSolo!
    var viewController: ViewController!
    
    override func setUp() {
        sut = STKSolo()
        viewController = ViewController(nibName: "ViewController", bundle: nil)
    }

    override func tearDown() {
        sut.cleanupWindow()
        viewController = nil
        sut = nil
    }

    func testWaitForText_shouldFindLabelTest() {
        // Given
        sut.showViewControllerInCleanWindow(viewController)
        
        // When
        let foundTestText = sut.waitFor(text: "Test")
        
        // Expect
        XCTAssertTrue(foundTestText)
    }

    func testWaitForText_shouldFindWhitespacedLabelTest() {
        // Given
        let texts = [
            "Some \n text",
            "Some \n\n text",
            "Some \n\n text \n and another",
            "Some \t text"
        ]
        var foundTestTexts = [String: Bool]()
        sut.showViewControllerInCleanWindow(viewController)
        
        // When
        for text in texts {
            viewController.topLabel.text = text
            
            foundTestTexts[text] = sut.waitFor(text: text)
        }
        
        // Expect
        XCTAssertTrue(foundTestTexts[texts[0]] ?? false)
        XCTAssertTrue(foundTestTexts[texts[1]] ?? false)
    }

    func testWaitForText_shouldFindLabelTestUsingPrefix() {
        // Given
        sut.showViewControllerInCleanWindow(viewController)
        
        // When
        let foundTestText = sut.waitFor(textWithPrefix: "Tes")
        
        // Expect
        XCTAssertTrue(foundTestText)
    }
    
    func testWaitForText_shouldFindLabelTestUsingSuffix() {
        // Given
        class CustomNavigationController: UINavigationController { var attribute = "attribute" }
        sut.navigationControllerClass = CustomNavigationController.self
        sut.showViewControllerInCleanWindow(viewController, inNavigationController: true)
        
        // When
        let foundTestText = sut.waitFor(textWithSuffix: "st")
        
        // Expect
        XCTAssertTrue(foundTestText)
    }
    
    func testWaitForText_shouldNotFindLabelWithinFiveSeconds() {
        // Given
        sut.timeoutForWaitForMethods = 0.5
        sut.showViewControllerInCleanWindow(viewController)

        // When
        let start = Date.timeIntervalSinceReferenceDate
        let notFoundText = sut.waitFor(text: "text that should not be found in window hierarchy")
        let end = Date.timeIntervalSinceReferenceDate

        // Expect
        XCTAssertFalse(notFoundText)
        XCTAssertEqual(end - start, sut.timeoutForWaitForMethods, accuracy: 0.1)
    }
    
    func testWaitForTapableTextAndTapIt_shouldHaveTap() {
        // Given
        sut.showViewControllerInCleanWindow(viewController)

        // When
        let waitForText = sut.waitFor(tappableText:"Hello button", andTapIt:true)
        
        // Expect
        XCTAssertTrue(waitForText)
        XCTAssertTrue(viewController.tapped)
    }
    
    func testWaitForTapableTextAndTapIt_WithButtonInScrollView_ShouldHaveTap() {
        // Given
        sut.showViewControllerInCleanWindow(viewController)
        
        // When
        let waitForText = sut.waitFor(tappableText:"Inscrollview button", andTapIt:true)
        
        // Expect
        XCTAssertTrue(waitForText)
        XCTAssertTrue(viewController.tapped)
    }
    
    func testWaitForTextToBecomeInvalid_shouldReturnOKForAButton() {
        // Given
        sut.showViewControllerInCleanWindow(viewController)
        
        // When
        let found = sut.waitFor(text: "Hello button")
        DispatchQueue.main.async {
            self.viewController.helloButton?.isHidden = true
        }
        let waitForTextToBecomeInvalid = sut.waitFor(textToBecomeInvalid: "Hello button")
    
        // Expect
        XCTAssertTrue(found)
        XCTAssertTrue(waitForTextToBecomeInvalid)
    }
    
    func testWaitForTextToBecomeInvalid_shouldReturnOKForAnActivityIndicator() {
        // Given
        sut.showViewControllerInCleanWindow(viewController)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
            self.viewController.activityIndicator?.isHidden = true
        }

        // When
        let waitForTextToBecomeInvalid = sut.waitFor(textToBecomeInvalid: UIActivityIndicatorView.accessibilityLabelForAnimatedInstance())
        
        // Expect
        XCTAssertTrue(waitForTextToBecomeInvalid)
    }
    
    func testWaitForever_shouldLetUserInteraction() {
        // Given
        sut.showViewControllerInCleanWindow(viewController)
        
        // When
        sut.waitForever()
        
        // Expect
        // Manually try to tap "hello button" when runing this single test
    }
    
    func testSwipeLeftOnTableViewCell_shouldShowDeleteButton() {
        // Given
        let cellText = "0 - 1"
        sut.showViewControllerInCleanWindow(viewController)
        
        // When
        let waitForCell = sut.waitFor(tappableText: cellText, andTapIt: false)
        sut.swipeLeftView(with: cellText)
        let waitForDeleteConfirmationButton = sut.waitFor(tappableText: "suppr", andTapIt: false)
        
        // Expect
        XCTAssertTrue(waitForCell)
        XCTAssertTrue(waitForDeleteConfirmationButton)
    }
    
    func testWaitForText_onAlertViewController_shouldFindOKButton() {
        // Given
        sut.showViewControllerInCleanWindow(viewController)
        let alertVC = UIAlertController(title: "title", message: "message", preferredStyle: .alert)
        let alertOKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertVC.addAction(alertOKAction)
        viewController.present(alertVC, animated: false, completion: nil)
        attachScreenshot(name: "test")
        // When
        let waitForOK = sut.waitFor(tappableText: "OK", andTapIt: true)
        
        // Expect
        XCTAssertTrue(waitForOK)
    }
    
    func testWaitForText_inTextView_shouldBeFound() {
        // Given
        let text = "Lorem ipsum textview"
        sut.showViewControllerInCleanWindow(viewController)
        
        // When
        self.viewController.textView.accessibilityLabel = text
        let waitForText = sut.waitFor(text: text)
        sut.window?.printHierarchy()
        //sut.waitForever()
        
        // Expect
        XCTAssertTrue(waitForText)
    }

}
