//
//  STKPilotableHTTPServerTests.swift
//  STKTestAppTests
//
//  Created by Richard Bergoin on 20/09/2018.
//  Copyright © 2018 Openium. All rights reserved.
//

import XCTest
import SwiftiumTestingKit

class STKPilotableHTTPServerTests: XCTestCase {
    
    var sut: STKPilotableHTTPServer!

    override func setUp() {
        sut = STKPilotableHTTPServer(scheme: "https", host: "servername.tld", documentRoot: Bundle(for: type(of: self)).bundlePath)
    }

    override func tearDown() {
        sut = nil
    }

    func testMakeRequestReturnData_shouldGiveResourceDataIgnoringQueryParameters() {
        // Given
        let jsonData = dataFromCurrentClassBundleRessource(filename: "hello.json")
        var servedData: Data? = nil
        var servedResponse: HTTPURLResponse?

        // When
        let url = sut.makeRequest(onPath: "/hello.json", serveContentOfFileAtPath: "hello.json")
        let expectation = self.expectation(description: "file hello.json must be served")
        let urlWithParams = URL(string: url.absoluteString.appending("?parameter=value"))!
        let downloadTask = URLSession.shared.dataTask(with: urlWithParams) { (data, urlResponse, error) in
            servedData = data
            servedResponse = urlResponse as? HTTPURLResponse
            expectation.fulfill()
        }
        downloadTask.resume()
        self.waitForExpectations(timeout: 1.0, handler: nil)
        
        // Expect
        XCTAssertEqual(servedData, jsonData)
        let contentTypeGivenBack = servedResponse?.allHeaderFields["Content-Type"] as? String
        XCTAssertEqual(contentTypeGivenBack, "application/json")
    }

    func testMakeRequestRedirect_shouldRedirect() {
        // Given
        var servedResponse: HTTPURLResponse?
        let toLocation = "/redirected-from-test.html"
        
        // When
        let url = sut.makeRequest(onPath: "/test.html", beRedirectedToLocation:toLocation, statusCode: 302)
        let expectation = self.expectation(description: "A 302 must be served")
        let sessionConfiguration = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
        let downloadTask = session.dataTask(with: url) { (data, urlResponse, error) in
            servedResponse = urlResponse as? HTTPURLResponse
            expectation.fulfill()
        }
        downloadTask.resume()
        self.waitForExpectations(timeout: 1.0, handler: nil)
        
        // Expect
        XCTAssertEqual(servedResponse?.statusCode, 302)
        let locationGivenBack = servedResponse?.allHeaderFields["Location"] as? String
        XCTAssertEqual(locationGivenBack, toLocation)
    }
    
    func testHasServedAllQueuedResponses_shouldReturnTrue() {
        // Given
        
        // When
        let url = sut.makeRequest(onPath: "/hello.json", serveContentOfFileAtPath: "hello.json")
        let allServedAfterQueuing = sut.hasServedAllQueuedResponses
        let expectation = self.expectation(description: "file hello.json must be served")
        let urlWithParams = URL(string: url.absoluteString.appending("?parameter=value"))!
        let downloadTask = URLSession.shared.dataTask(with: urlWithParams) { (data, urlResponse, error) in
            expectation.fulfill()
        }
        downloadTask.resume()
        self.waitForExpectations(timeout: 1.0, handler: nil)
        
        // Expect
        XCTAssertFalse(allServedAfterQueuing)
        XCTAssertTrue(sut.hasServedAllQueuedResponses)
    }
}

extension STKPilotableHTTPServerTests: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        completionHandler(nil)
    }
}
