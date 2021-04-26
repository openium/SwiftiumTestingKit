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

@objcMembers
public class STKSolo: NSObject {
    public var animationSpeed: Float = 1.0
    public var timeToWaitForever: Double = 20
    static var isSingleTestRunning: Bool = {
        return isSingleTestRun()
    }()
    
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
    
    public private(set) var window: UIWindow?
    
    lazy var testActor: KIFUITestActor = {
        guard let testActor = KIFUITestActor(inFile: "STKSolo.swift", atLine: 12, delegate: self) else {
            fatalError("Can't instanciate a KIFUITestActor")
        }
        testActor.executionBlockTimeout = timeoutForWaitForMethods

        return testActor
    }()
    var lastExceptions = [Any]()
    
    public override init() {
        if KIFAccessibilityEnabled() == false {
            KIFEnableAccessibility()
        }
        super.init()
        _ = testActor
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
    
    func waitRunLoops(timeBetweenChecks: TimeInterval) {
        RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: timeBetweenChecks / 3.0))
        RunLoop.current.run(mode: .common, before: Date(timeIntervalSinceNow: timeBetweenChecks / 3.0))
        RunLoop.current.run(mode: .tracking, before: Date(timeIntervalSinceNow: timeBetweenChecks / 3.0))
        if !STKSolo.isSingleTestRunning {
            CATransaction.flush() // prevents animations
        }
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
            waitRunLoops(timeBetweenChecks: timeBetweenChecks)
            now = Date.timeIntervalSinceReferenceDate
        } while (now - start) < timeout
    }
    
    private func waitForAccessibilityElement(matching predicateBlock: @escaping (UIAccessibilityElement) -> Bool) -> UIAccessibilityElement? {
        var element: UIAccessibilityElement? = nil
        // IMPROVEMENT: don't reevaluate until having received a UIAccessibilityLayoutChangedNotification
        waitClosureToReturnTrue({ () -> Bool in
            element = UIApplication.shared.accessibilityElement(matching: { (element) -> Bool in
                guard let element = element else { return false }
                return predicateBlock(element)
            })
            return element != nil
        }, withinTimeout: timeoutForWaitForMethods, timeBetweenChecks: timeBetweenChecks)
        return element
    }
    
    public func accessibilityCleaned(text: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: "(?<!\n)\n(?!\n)", options: []) else { return text }
        
        return regex.stringByReplacingMatches(
            in: text,
            options: [],
            range: NSMakeRange(0, text.count),
            withTemplate: " "
        )
    }
    
    public func waitFor(text: String) -> Bool {
        let cleanedText = accessibilityCleaned(text: text)
        let element = waitForAccessibilityElement { $0.accessibilityLabel == cleanedText }
        return element != nil
    }
    
    public func waitFor(textWithPrefix prefix: String) -> Bool {
        let cleanedText = accessibilityCleaned(text: prefix)
        let element = waitForAccessibilityElement { $0.accessibilityLabel?.hasPrefix(cleanedText) ?? false }
        return element != nil
    }

    public func waitFor(textWithSuffix suffix: String) -> Bool {
        let cleanedText = accessibilityCleaned(text: suffix)
        let element = waitForAccessibilityElement { $0.accessibilityLabel?.hasSuffix(cleanedText) ?? false }
        return element != nil
    }

    @discardableResult
    public func waitFor(tappableText: String, andTapIt tapIt: Bool) -> Bool {
        let cleanedText = accessibilityCleaned(text: tappableText)
        let element = waitForAccessibilityElement { $0.accessibilityLabel == cleanedText }
        if let element = element {
            var view: UIView? = nil
            waitClosureToReturnTrue({ () -> Bool in
                view = try? UIAccessibilityElement.viewContaining(element, tappable: true)
                return view != nil
            }, withinTimeout: timeoutForWaitForMethods, timeBetweenChecks: timeBetweenChecks)
            if let view = view {
                if tapIt {
                    testActor.tap(element, in: view)
                    waitRunLoops(timeBetweenChecks: timeBetweenChecks)
                }
            } else {
                return false
            }
        }
        return element != nil
    }

    public func waitFor(textToBecomeInvalid: String) -> Bool {
        var textBecameInvalid = false
        let cleanedText = accessibilityCleaned(text: textToBecomeInvalid)
        let element = waitForAccessibilityElement { $0.accessibilityLabel == cleanedText }
        if element != nil {
            lastExceptions.removeAll()
            testActor.waitForAbsenceOfView(withAccessibilityLabel: cleanedText)
            if lastExceptions.isEmpty {
                textBecameInvalid = true
            }
            lastExceptions.removeAll()
        } else {
            textBecameInvalid = true
        }
        return textBecameInvalid
    }
    
    public func waitForAnimationsToFinish() {
        testActor.waitForAnimationsToFinish()
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

extension STKSolo: KIFTestActorDelegate {
    public func fail(with exception: NSException!, stopTest stop: Bool) {
        if let exception = exception {
            lastExceptions.append(exception)
        }
    }
    
    public func fail(withExceptions exceptions: [Any]!, stopTest stop: Bool) {
        lastExceptions.removeAll()
        lastExceptions.append(contentsOf: exceptions)
    }
}
