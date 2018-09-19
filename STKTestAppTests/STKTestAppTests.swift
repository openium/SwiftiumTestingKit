//
//  STKTestAppTests.swift
//  STKTestAppTests
//
//  Created by Richard Bergoin on 19/09/2018.
//  Copyright © 2018 Openium. All rights reserved.
//

import XCTest
import SwiftiumTestingKit

@testable import STKTestApp

class STKTestAppTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testPath() {
        //print(Bundle(for: type(of: self)).bundlePath)
        let helloJsonPath = pathFromCurrentClassBundleRessource(filename: "hello.json", mainBundle: false)
        //print(helloJsonPath)
        XCTAssertNotNil(helloJsonPath)
    }
    
    func testJson() {
        let json = jsonObjectFromRessource(filename: "hello.json")
        //print(json)
        XCTAssertNotNil(json)
    }

}
