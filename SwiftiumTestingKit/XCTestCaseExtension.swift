//
//  XCTestCaseExtension.swift
//  SwiftiumTestingKit
//
//  Created by Richard Bergoin on 19/09/2018.
//  Copyright © 2018 Openium. All rights reserved.
//

import XCTest

extension XCTestCase {
    
    public func pathFromCurrentClassBundleRessource(filename: String, mainBundle: Bool = false) -> String {
        var path: String? = nil
        let filenameAsURL = URL(string: filename)!
        let fileExtension = filenameAsURL.pathExtension
        let fileWithoutExtension = filenameAsURL.deletingPathExtension().absoluteString
        
        var bundle = Bundle(for: type(of: self))
        if mainBundle {
            bundle = Bundle.main
        }
        
        if filename.range(of: "/") != nil {
            path = bundle.path(forResource: fileWithoutExtension, ofType: fileExtension)
        } else {
            path = (bundle.bundlePath as NSString).appendingPathComponent(filename)
        }
        
        return path!
    }
    
    public func dataFromCurrentClassBundleRessource(filename: String, mainBundle: Bool = false) -> Data {
        let path = pathFromCurrentClassBundleRessource(filename: filename, mainBundle: mainBundle)
        var data: Data? = nil
        do {
            data = try Data(contentsOf: URL(fileURLWithPath: path))
        } catch let error as NSError {
            fatalError("Can't load data from bundle resource \(filename) (path \(path) \(error.localizedDescription))")
        }
        return data!
    }
    
    public func jsonObjectFromRessource(filename: String, mainBundle: Bool = false) -> Any {
        let data = dataFromCurrentClassBundleRessource(filename: filename, mainBundle: mainBundle)
        var json: Any! = nil
        do {
            json = try JSONSerialization.jsonObject(with: data)
        } catch let error as NSError {
            fatalError("Can't load json from data of bundle resource \(filename): \(error.localizedDescription)")
        }
        return json
    }
    
    // MARK: -
    
    func classNamePlusMethodCleaned(_ methodName: StaticString) -> String {
        var methodNameCleaned = methodName.description
        methodNameCleaned = methodNameCleaned.replacingOccurrences(of: "testInteGraphique", with: "")
        methodNameCleaned = methodNameCleaned.replacingOccurrences(of: "_shouldWaitForever()", with: "")
        let className = self.theClassName
        return className + "_" + methodNameCleaned
    }
    
    public func attachScreenshot(of window: UIWindow,
                                 name: StaticString = #function,
                                 cleaningMethodNameWith: (StaticString) -> String) {
        //let image = solo.window.otk_screenshot(withStatusBar: true)
        let image = XCUIScreen.main.screenshot().image
        //let image = window.layer.screenshot
        let attachment = XCTAttachment(image: image, quality: .medium)
        attachment.lifetime = .keepAlways
        let nameCleaned = cleaningMethodNameWith(name)
        attachment.name = nameCleaned
        add(attachment)
    }
    
    public func attachScreenshot(name: String, useLangPhonePrefix: Bool = true, separator: String = "_") {
        let image = XCUIScreen.main.screenshot().image
        let attachment = XCTAttachment(image: image, quality: .medium)
        attachment.lifetime = .keepAlways
        if useLangPhonePrefix {
            attachment.name = NSLocale.current.identifier + separator + UIDevice.current.name + separator + name
        } else {
            attachment.name = name
        }
        add(attachment)
    }
}

extension UIView {
    var screenshot: UIImage {
        return layer.screenshot
    }
}

extension CALayer {
    var screenshot: UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: frame)
        let image = renderer.image { context in
            render(in: context.cgContext)
        }
        return image
    }
}

extension NSObject {
    var theClassName: String {
        var theClassName = NSStringFromClass(type(of: self))
        if let rangeOfDotFromEnd = theClassName.range(of: ".", options: .backwards) {
            theClassName = String(theClassName[rangeOfDotFromEnd.upperBound...])
        }
        return theClassName
    }
}

extension UIActivityIndicatorView {
    public static func accessibilityLabelForHaltedInstance() -> String {
        let instance = UIActivityIndicatorView()
        return instance.accessibilityLabel ?? "accessibilityLabelForHaltedInstance"
    }
    
    public static func accessibilityLabelForAnimatedInstance() -> String {
        let instance = UIActivityIndicatorView()
        instance.startAnimating()
        return instance.accessibilityLabel ?? "accessibilityLabelForAnimatedInstance"
    }
}
