//
//  STKPilotableHTTPServerTests.swift
//  STKTestAppTests
//
//  Created by Richard Bergoin on 20/09/2018.
//  Copyright © 2018 Openium. All rights reserved.
//

import XCTest
import SwiftiumTestingKit
import OHHTTPStubs

class STKPilotableHTTPServerTests: XCTestCase {
    
    var sut: STKPilotableHTTPServer!

    override func setUp() {
        sut = STKPilotableHTTPServer(scheme: "https", host: "servername.tld", documentRoot: Bundle(for: type(of: self)).bundlePath)
    }

    override func tearDown() {
        sut = nil
    }
    
    func testMakeRequestAndReleaseServer_shouldEmptyStubs() {
        // Given
        sut.makeRequest(onPath: "/hello.json", serveContentOfFileAtPath: "hello.json")
        let allServedAfterQueuing = sut.hasServedAllQueuedResponses
        
        // When
        sut = nil
        
        // Expect
        XCTAssertFalse(allServedAfterQueuing)
        XCTAssertEqual(HTTPStubs.allStubs().count, 0)
    }
    
    func testMakeRequestReturnData_emptyData_204() {
        // Given
        
        // When
        let url = sut.makeRequest(onPath: "/hello.json", data: nil, statusCode: 204)
        let expectation = self.expectation(description: "file hello.json must be served")
        let urlWithParams = URL(string: url.absoluteString.appending("?parameter=value"))!
        let downloadTask = URLSession.shared.dataTask(with: urlWithParams) { (data, urlResponse, error) in
            if let httpResponse = urlResponse as? HTTPURLResponse,
                httpResponse.statusCode == 204 && data?.isEmpty == true {
                expectation.fulfill()
            }
        }
        downloadTask.resume()
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testMakeRequestReturnData_shouldGiveResourceDataIgnoringQueryParameters_usingData() {
        // Given
        let jsonData = dataFromCurrentClassBundleRessource(filename: "hello.json")
        var servedData: Data? = nil
        
        // When
        let url = sut.makeRequest(onPath: "/hello.json", data: jsonData)
        let expectation = self.expectation(description: "file hello.json must be served")
        let urlWithParams = URL(string: url.absoluteString.appending("?parameter=value"))!
        let downloadTask = URLSession.shared.dataTask(with: urlWithParams) { (data, urlResponse, error) in
            servedData = data
            expectation.fulfill()
        }
        downloadTask.resume()
        self.waitForExpectations(timeout: 1.0, handler: nil)
        
        // Expect
        XCTAssertEqual(servedData, jsonData)
    }

    func testMakeRequestReturnData_shouldGiveResourceDataIgnoringQueryParameters_usingFileContent() {
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
        let downloadTask = URLSession.shared.dataTask(with: url) { (data, urlResponse, error) in
            expectation.fulfill()
        }
        downloadTask.resume()
        self.waitForExpectations(timeout: 1.0, handler: nil)
        
        // Expect
        XCTAssertFalse(allServedAfterQueuing)
        XCTAssertTrue(sut.hasServedAllQueuedResponses)
    }
    
    func testHasServedAllQueuedResponses_shouldReturnTrueEvenWithTwoQueuedResponses() {
        // Given
        
        // When
        let url = sut.makeRequest(onPath: "/hello.json", serveContentOfFileAtPath: "hello.json")
        let urlBis = sut.makeRequest(onPath: "/hellobis.json", serveContentOfFileAtPath: "hello.json")
        let allServedAfterQueuing = sut.hasServedAllQueuedResponses
        let expectation = self.expectation(description: "file hello.json must be served")
        let expectationBis = self.expectation(description: "file hello-bis.json must be served")
        let downloadTask = URLSession.shared.dataTask(with: url) { (data, urlResponse, error) in
            let downloadTaskBis = URLSession.shared.dataTask(with: urlBis) { (data, urlResponse, error) in
                expectationBis.fulfill()
            }
            downloadTaskBis.resume()
            expectation.fulfill()
        }
        downloadTask.resume()

        self.waitForExpectations(timeout: 1.0, handler: nil)
        
        // Expect
        XCTAssertFalse(allServedAfterQueuing)
        XCTAssertTrue(sut.hasServedAllQueuedResponses)
    }
    
    func testHasServedAllQueuedResponses_shouldReturnTrueEvenWithTwoQueuedResponsesOnSamePath() {
        // Given
        
        // When
        let urlBis = sut.makeRequest(onPath: "/hello.json", serveContentOfFileAtPath: "hello.json")
        let url = sut.makeRequest(onPath: "/hello.json", serveContentOfFileAtPath: "hello.json", statusCode: 401)
        let allServedAfterQueuing = sut.hasServedAllQueuedResponses
        let expectation = self.expectation(description: "file hello.json must be served with code 401 first")
        let expectationBis = self.expectation(description: "file hello.json must be served with code 200 then")
        let downloadTask = URLSession.shared.dataTask(with: url) { (data, urlResponse, error) in
            let downloadTaskBis = URLSession.shared.dataTask(with: urlBis) { (data, urlResponseBis, error) in
                if let httpResponse = urlResponseBis as? HTTPURLResponse,
                    httpResponse.statusCode == 200 {
                    expectationBis.fulfill()
                }
            }
            DispatchQueue.main.async {
                downloadTaskBis.resume()
            }
            if let httpResponse = urlResponse as? HTTPURLResponse,
                httpResponse.statusCode == 401 {
                expectation.fulfill()
            }
        }
        downloadTask.resume()
        
        self.waitForExpectations(timeout: 2.0, handler: nil)
        
        // Expect
        XCTAssertFalse(allServedAfterQueuing)
        XCTAssertTrue(sut.hasServedAllQueuedResponses)
    }

    func testResponseFileHasSpecifiedHeadersResponses_shouldReturnWithSpecifiedHeaders() {
        // Given
        let headerContentType = "Content-Type"
        let headerContentTypeValue = "application/vnd.openium.v1+json"
        let headerCacheControl = "Cache-Control"
        let headerCacheControlValue = "no-cache"
        let customResponseHeaders = [headerContentType: headerContentTypeValue]
        sut.defaultResponseHeaders = [headerCacheControl: headerCacheControlValue]
        
        // When
        
        let url = sut.makeRequest(onPath: "/hello.json", serveContentOfFileAtPath: "hello.json", customResponseHeaders: customResponseHeaders)
        let expectation = self.expectation(description: "file hello.json must be served with custom headers content type")
        let downloadTask = URLSession.shared.dataTask(with: url) { (data, urlResponse, error) in
            if let httpResponse = urlResponse as? HTTPURLResponse,
                (httpResponse.allHeaderFields[headerContentType] as? String) == headerContentTypeValue,
                (httpResponse.allHeaderFields[headerCacheControl] as? String) == headerCacheControlValue {
                expectation.fulfill()
            }
        }
        downloadTask.resume()
        
        // Expect
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    func testResponseDataHasSpecifiedHeadersResponses_shouldReturnWithSpecifiedHeaders() {
        // Given
        let jsonData = dataFromCurrentClassBundleRessource(filename: "hello.json")
        let headerContentType = "Content-Type"
        let headerContentTypeValue = "application/vnd.openium.v1+json"
        let headerCacheControl = "Cache-Control"
        let headerCacheControlValue = "no-cache"
        let customResponseHeaders = [headerContentType: headerContentTypeValue]
        sut.defaultResponseHeaders = [headerCacheControl: headerCacheControlValue]
        
        // When
        let url = sut.makeRequest(onPath: "/hello.json", data: jsonData, customResponseHeaders: customResponseHeaders)
        let expectation = self.expectation(description: "file hello.json must be served with custom headers content type")
        let downloadTask = URLSession.shared.dataTask(with: url) { (data, urlResponse, error) in
            if let httpResponse = urlResponse as? HTTPURLResponse,
                (httpResponse.allHeaderFields[headerContentType] as? String) == headerContentTypeValue,
                (httpResponse.allHeaderFields[headerCacheControl] as? String) == headerCacheControlValue {
                expectation.fulfill()
            }
        }
        downloadTask.resume()
        
        // Expect
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    func testHasServedAllQueuedResponses_shouldReturnTrue_withRequestTimeTo5() {
        // Given
        
        // When
        let url = sut.makeRequest(onPath: "/hello.json", serveContentOfFileAtPath: "hello.json", requestTime: 0.5)
        let allServedAfterQueuing = sut.hasServedAllQueuedResponses
        let expectation = self.expectation(description: "file hello.json must be served")
        let downloadTask = URLSession.shared.dataTask(with: url) { (data, urlResponse, error) in
            expectation.fulfill()
        }
        let startDate = Date()
        downloadTask.resume()

        self.waitForExpectations(timeout: 1.0, handler: nil)
        let endDate = Date()
        
        // Expect
        let duration = endDate.timeIntervalSince1970 - startDate.timeIntervalSince1970
        XCTAssertTrue(duration < 0.6)
        XCTAssertTrue(duration > 0.49)
        XCTAssertFalse(allServedAfterQueuing)
        XCTAssertTrue(sut.hasServedAllQueuedResponses)
    }
}

extension STKPilotableHTTPServerTests: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        completionHandler(nil)
    }
}
