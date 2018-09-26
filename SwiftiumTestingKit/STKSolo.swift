//
//  STKSolo.swift
//  SwiftiumTestingKit
//
//  Created by Richard Bergoin on 19/09/2018.
//  Copyright © 2018 Openium. All rights reserved.
//

import UIKit
import XCTest
import KIF
import SimulatorStatusMagiciOS

public class STKSolo: NSObject {
    public var animationSpeed: Float = 1.0
    public var timeToWaitForever: Double = 20
    var internalTimeToWaitForever: Double {
        var time = timeToWaitForever
        if isUserJenkinsOrHudson() {
            time = 0
        }
        if isMultipleTestsRun() && !isSingleTestRun() {
            time = 0
        }
        return time
    }
    /// Timeout after looking for an accessibility element will end
    public var timeoutForWaitForMethods: Double = 5.0
    var timeBetweenChecks: Double = 0.005
    
    public var navigationControllerClass = UINavigationController.self
    public var windowClass = UIWindow.self
    
    var window: UIWindow?
    
    lazy var testActor: KIFUITestActor = {
        guard let testActor = KIFUITestActor(inFile: "STKSolo.swift", atLine: 12, delegate: self) else {
            fatalError("Can't instanciate a KIFUITestActor")
        }
        testActor.executionBlockTimeout = timeoutForWaitForMethods

        SDStatusBarManager.sharedInstance()?.carrierName = "OPENIUM"
        SDStatusBarManager.sharedInstance()?.bluetoothState = SDStatusBarManagerBluetoothState.visibleConnected
        SDStatusBarManager.sharedInstance()?.enableOverrides()

        return testActor
    }()
    var lastExceptions = [Any]()
    
    public override init() {
        if KIFAccessibilityEnabled() == false {
            KIFEnableAccessibility()
        }
    }
    
    @discardableResult
    public func showViewControllerInCleanWindow(_ viewController: UIViewController, inNavigationController: Bool = false) -> UINavigationController? {
        var navController: UINavigationController? = nil
        
        let rect = UIScreen.main.bounds
        window = windowClass.init(frame: rect)
        
        if inNavigationController {
            navController = navigationControllerClass.init(rootViewController: viewController)
            self.window?.rootViewController = navController
        } else {
            self.window?.rootViewController = viewController
        }
        
        // if areMultipleTestsRun() && ! isSingleTestRun()
        //    self.window?.layer.speed = animationSpeed
        
        self.window?.makeKeyAndVisible()
        waitClosureToReturnTrue({ () -> Bool in
            viewController.isViewLoaded && viewController.view.superview != nil
        }, withinTimeout: timeoutForWaitForMethods, timeBetweenChecks: timeBetweenChecks)
        return navController
    }
    
    public func cleanupWindow() {
        self.window?.rootViewController = nil
        self.window?.resignKey()
        self.window = nil
    }
    
    func waitClosureToReturnTrue(_ closure: () -> Bool,
        withinTimeout timeout: TimeInterval,
        timeBetweenChecks: TimeInterval) {
        let start = Date.timeIntervalSinceReferenceDate
        var now = start
        repeat {
            if closure() {
                break
            }
            RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: timeBetweenChecks))
            now = Date.timeIntervalSinceReferenceDate
        } while (now - start) < timeout
    }
    
    private func waitForAccessibilityElement(matching predicate: NSPredicate) -> UIAccessibilityElement? {
        var element: UIAccessibilityElement? = nil
        // IMPROVEMENT: don't reevaluate until having received a UIAccessibilityLayoutChangedNotification
        waitClosureToReturnTrue({ () -> Bool in
            element = UIApplication.shared.accessibilityElement { (element) -> Bool in
                return predicate.evaluate(with: element)
            }
            return element != nil
        }, withinTimeout: timeoutForWaitForMethods, timeBetweenChecks: timeBetweenChecks)
        return element
    }
    
    public func waitFor(text: String) -> Bool {
        //let element = testActor.waitForView(withAccessibilityLabel: text)
        let predicate = NSPredicate(format: "%K == %@", "accessibilityLabel", text)
        let element = waitForAccessibilityElement(matching: predicate)
        return element != nil
    }
    
    public func waitFor(textWithPrefix prefix: String) -> Bool {
        let predicate = NSPredicate(format: "%K BEGINSWITH %@", "accessibilityLabel", prefix)
        let element = waitForAccessibilityElement(matching: predicate)
        return element != nil
    }

    public func waitFor(textWithSuffix suffix: String) -> Bool {
        let predicate = NSPredicate(format: "%K ENDSWITH %@", "accessibilityLabel", suffix)
        let element = waitForAccessibilityElement(matching: predicate)
        return element != nil
    }

    public func waitFor(tappableText: String, andTapIt: Bool) -> Bool {
        let predicate = NSPredicate(format: "%K == %@", "accessibilityLabel", tappableText)
        let element = waitForAccessibilityElement(matching: predicate)
        if let element = element {
            if let view = try? UIAccessibilityElement.viewContaining(element, tappable: true) {
                testActor.tap(element, in: view)
            } else {
                return false
            }
        }
        return element != nil
    }

    public func waitFor(textToBecomeInvalid: String) -> Bool {
        var textBecameInvalid = false
        let predicate = NSPredicate(format: "%K == %@", "accessibilityLabel", textToBecomeInvalid)
        let element = waitForAccessibilityElement(matching: predicate)
        if element != nil {
            lastExceptions.removeAll()
            testActor.waitForAbsenceOfView(withAccessibilityLabel: textToBecomeInvalid)
            if lastExceptions.isEmpty {
                textBecameInvalid = true
            }
            lastExceptions.removeAll()
        } else {
            textBecameInvalid = true
        }
        return textBecameInvalid
    }
    
    public func waitForever() {
        testActor.wait(forTimeInterval: internalTimeToWaitForever)
    }
    
    public func waitFor(timeInterval: TimeInterval) {
        testActor.wait(forTimeInterval: timeInterval)
    }
    
    public func tapScreen(at point: CGPoint) {
        testActor.tapScreen(at: point)
    }
    
    public func swipeDownView(with accessibilityLabel: String) {
        testActor.swipeView(withAccessibilityLabel: accessibilityLabel, in: .down)
    }

    public func swipeUpView(with accessibilityLabel: String) {
        testActor.swipeView(withAccessibilityLabel: accessibilityLabel, in: .up)
    }
    
    public func swipeLeftView(with accessibilityLabel: String) {
        testActor.swipeView(withAccessibilityLabel: accessibilityLabel, in: .left)
    }
    
    public func swipeRightView(with accessibilityLabel: String) {
        testActor.swipeView(withAccessibilityLabel: accessibilityLabel, in: .right)
    }
    
    public func toggleSwitch(with accessibilityLabel: String) {
        let switchView = testActor.waitForView(withAccessibilityLabel: accessibilityLabel)
        var switchOn = true
        if let accessibilityValue = switchView?.accessibilityValue, accessibilityValue == "1" {
            switchOn = false
        }
        DispatchQueue.main.async {
            self.testActor.setOn(switchOn, forSwitchWithAccessibilityLabel: accessibilityLabel)
        }
    }
    
    public func simulateDeviceRotation(to orientation: UIDeviceOrientation) {
        UIDevice.current.setValue(NSNumber(integerLiteral: orientation.rawValue), forKey: "orientation")
    }
    
    public func enterTextInCurrentFirstResponder(_ text: String) {
        testActor.enterText(intoCurrentFirstResponder: text)
    }
    
    #if targetEnvironment(simulator)
    public func acknowledgeSystemAlert() {
        testActor.acknowledgeSystemAlert()
    }
    #endif
}

extension STKSolo {
    
    func isUserJenkinsOrHudson() -> Bool {
        var username = NSUserName()
        #if targetEnvironment(simulator)
        if username.isEmpty {
            let bundlePathComponents = (Bundle.main.bundlePath as NSString).pathComponents
            if bundlePathComponents.count >= 3 && bundlePathComponents[0] == "/" && bundlePathComponents[1] == "Users" {
                username = bundlePathComponents[2]
            }
        }
        #endif
        return username == "hudson" || username == "jenkins"
    }
    
    func isSingleTestRun() -> Bool {
        /*
        XCTestConfiguration *testConfiguration = [XCTestConfiguration activeTestConfiguration];
        // KO when running test of only one class (testsToRun is an Array<String> with class/test names, or just class name)
        return [testConfiguration.testsToRun count] == 1 && [[testConfiguration.testsToRun anyObject] containsString:@"/"];
        */
        if let plistPath = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"],
           let plistBinary = FileManager.default.contents(atPath: plistPath),
           let unarchivedObject = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(plistBinary),
           let object = unarchivedObject as? NSObject,
           let testsToRun = object.value(forKey: "testsToRun") as? NSSet,
           testsToRun.count == 1,
           let singleTestToRun = testsToRun.anyObject() as? NSString {
            return singleTestToRun.contains("/")
        } else {
            return false
        }
    }
    
    func isMultipleTestsRun() -> Bool {
        return XCTestSuite.default.testCaseCount > 1
    }
}

extension STKSolo: KIFTestActorDelegate {
    public func fail(with exception: NSException!, stopTest stop: Bool) {
        lastExceptions.append(exception)
    }
    
    public func fail(withExceptions exceptions: [Any]!, stopTest stop: Bool) {
        lastExceptions.removeAll()
        lastExceptions.append(contentsOf: exceptions)
    }
}
