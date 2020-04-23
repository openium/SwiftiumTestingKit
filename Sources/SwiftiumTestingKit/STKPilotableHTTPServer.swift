//
//  STKPilotableHTTPServer.swift
//  SwiftiumTestingKit
//
//  Created by Richard Bergoin on 20/09/2018.
//  Copyright © 2018 Openium. All rights reserved.
//

import Foundation
import OHHTTPStubs
import OHHTTPStubsSwift
import MobileCoreServices

public func isMethod(_ verb: STKPilotableHTTPServer.HTTPVerb) -> HTTPStubsTestBlock {
    return { $0.httpMethod == verb.rawValue }
}

public class STKPilotableHTTPServer: NSObject {
    
    struct WeakServerWrapper {
        weak var server: STKPilotableHTTPServer?
    }
    
    static var allPilotableServers: [WeakServerWrapper] = {
        activateStubMissingAndActivationObservers()
        let allPilotableServers = [WeakServerWrapper]()
        return allPilotableServers
    }()
    static func addToAllPilotableServers(_ pilotableServer: STKPilotableHTTPServer) {
        let unownedServer = WeakServerWrapper(server: pilotableServer)
        allPilotableServers.append(unownedServer)
    }
    static func removeFromAllPilotableServers(_ pilotableServer: STKPilotableHTTPServer) {
        allPilotableServers.removeAll { $0.server == nil }
        pilotableServer.foreverQueuedDescriptors.forEach { HTTPStubs.removeStub($0) }
        pilotableServer.nonForeverQueuedDescriptors.forEach { HTTPStubs.removeStub($0) }
    }
    static func activateStubMissingAndActivationObservers() {
        HTTPStubs.onStubMissing({ (request) in
            NSLog("no served response queued for request \(request)")
        })
        HTTPStubs.onStubActivation({ (request, descriptor, response) in
            allPilotableServers.forEach({ (unownedServer) in
                guard let server = unownedServer.server else { return }
                if server.removeDescriptorFromNonForeverQueue(descriptor) {
                    HTTPStubs.removeStub(descriptor)
                }
            })
        })
    }
    
    var foreverQueuedDescriptors = [HTTPStubsDescriptor]()
    var nonForeverQueuedDescriptors = [HTTPStubsDescriptor]()
    
    func queue(descriptor: HTTPStubsDescriptor, serveForever: Bool) {
        if serveForever == false {
            descriptor.name = descriptor.debugDescription
            nonForeverQueuedDescriptors.append(descriptor)
        } else {
            foreverQueuedDescriptors.append(descriptor)
        }
    }

    func removeDescriptorFromNonForeverQueue(_ descriptor: HTTPStubsDescriptor) -> Bool {
        var removed = false
        let index = nonForeverQueuedDescriptors.firstIndex(where: { (nonForeverDescriptor) -> Bool in
            return nonForeverDescriptor.name == descriptor.name
        })
        if let index = index {
            nonForeverQueuedDescriptors.remove(at: index)
            removed = true
        }
        return removed
    }
    
    public enum HTTPVerb: String {
        case head = "HEAD"
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case patch = "PATCH"
        case delete = "DELETE"
        case options = "OPTIONS"
        case trace = "TRACE"
        case connect = "CONNECT"
    }
    
    public enum HTTPHeaders: String {
        case location = "Location"
        case contentType = "Content-Type"
    }
    
    public var hasServedAllQueuedResponses: Bool {
        return nonForeverQueuedDescriptors.count == 0
    }
    
    let scheme: String
    let host: String
    let documentRoot: String
    public var defaultResponseHeaders: [String: String]?
    
    public init(scheme: String, host: String, documentRoot: String) {
        self.scheme = scheme
        self.host = host
        self.documentRoot = documentRoot
        super.init()
        STKPilotableHTTPServer.addToAllPilotableServers(self)
    }
    
    deinit {
        STKPilotableHTTPServer.removeFromAllPilotableServers(self)
    }
    
    func pathFromDocumentRoot(of fileAtPath: String) -> String {
        let fullPath = documentRoot.appending("/\(fileAtPath)")
        guard FileManager.default.fileExists(atPath: fullPath) else {
            let exception = NSException(name: NSExceptionName(rawValue: "Can't find file"),
                                        reason: "No file exists in documentRoot at path : \(fullPath)",
                                        userInfo: nil)
            exception.raise()
            fatalError()
        }
        return fullPath
    }

    func urlForRequest(onPath path: String) -> URL {
        var urlComponents = URLComponents()
        urlComponents.scheme = scheme
        urlComponents.host = host
        //urlComponents.port = port
        urlComponents.path = path
        guard let url = urlComponents.url else { fatalError("can't create url from \(urlComponents)") }
        return url
    }
    
    func mimeTypeFromFileExtension(fileExtension: String) -> String? {
        guard let uti: CFString = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension as NSString, nil)?.takeRetainedValue() else {
            return nil
        }
        
        guard let mimeType: CFString = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() else {
            return nil
        }
        
        return mimeType as String
    }
    
    func headersWithMimeTypeOfFile(at path: String) -> [String: String]? {
        var headers = defaultResponseHeaders ?? [String: String]()
        if let mimeType = mimeTypeFromFileExtension(fileExtension: (path as NSString).pathExtension) {
            headers[HTTPHeaders.contentType.rawValue] = mimeType
        }
        return headers
    }
    
    @discardableResult
    public func makeRequest(onPath path: String,
                            data: Data?,
                            httpVerb: HTTPVerb = .get,
                            statusCode: Int32 = 200,
                            serveForever: Bool = false,
                            customResponseHeaders: [String: String]? = nil) -> URL {
        let descriptor = stub(condition: isScheme(scheme) && isHost(host) && isPath(path) && isMethod(httpVerb)) { _ in
            var headers = self.defaultResponseHeaders ?? [String: String]()
            if let customResponseHeaders = customResponseHeaders {
                headers.merge(customResponseHeaders) { (left, right) -> String in
                    return right
                }
            }
            return HTTPStubsResponse(data: data ?? Data(), statusCode: statusCode, headers: headers)
        }
        queue(descriptor: descriptor, serveForever: serveForever)
        return urlForRequest(onPath: path)
    }
    
    @discardableResult
    public func makeRequest(onPath path: String,
                            serveContentOfFileAtPath fileAtPath: String,
                            httpVerb: HTTPVerb = .get,
                            statusCode: Int32 = 200,
                            serveForever: Bool = false,
                            customResponseHeaders: [String: String]? = nil) -> URL {
        let stubPath = self.pathFromDocumentRoot(of: fileAtPath)
        var headers = [String: String]()
        if let headersWithMimeType = self.headersWithMimeTypeOfFile(at: fileAtPath) {
            headers.merge(headersWithMimeType) { (left, right) -> String in
                return right
            }
        }
        if let customResponseHeaders = customResponseHeaders {
            headers.merge(customResponseHeaders) { (left, right) -> String in
                return right
            }
        }
        
        let descriptor = stub(condition: isScheme(scheme) && isHost(host) && isPath(path) && isMethod(httpVerb)) { _ in
            return HTTPStubsResponse(fileAtPath: stubPath,
                                       statusCode: statusCode,
                                       headers: headers)
        }
        queue(descriptor: descriptor, serveForever: serveForever)
        return urlForRequest(onPath: path)
    }
    
    @discardableResult
    public func makeRequest(onPath path: String,
                            beRedirectedToLocation toLocation: String,
                            statusCode: Int32 = 301,
                            serveForever: Bool = false) -> URL {
        let descriptor = stub(condition: isScheme(scheme) && isHost(host) && isPath(path)) { _ in
            return HTTPStubsResponse(data: Data(),
                                       statusCode: statusCode,
                                       headers: [HTTPHeaders.location.rawValue: toLocation])
        }
        queue(descriptor: descriptor, serveForever: serveForever)
        return urlForRequest(onPath: path)
    }
}
