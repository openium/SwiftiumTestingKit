//
//  STKPilotableHTTPServer.swift
//  SwiftiumTestingKit
//
//  Created by Richard Bergoin on 20/09/2018.
//  Copyright © 2018 Openium. All rights reserved.
//

import UIKit
import OHHTTPStubs
import MobileCoreServices

public func isMethod(_ verb: STKPilotableHTTPServer.HTTPVerb) -> OHHTTPStubsTestBlock {
    return { $0.httpMethod == verb.rawValue }
}

public class STKPilotableHTTPServer: NSObject {
    
    static var nonForeverQueuedDescriptors: [OHHTTPStubsDescriptor] = {
        OHHTTPStubs.onStubActivation({ (request, descriptor, response) in
            if removeDescriptorFromNonForeverQueue(descriptor) {
                OHHTTPStubs.removeStub(descriptor)
            }
        })
        return [OHHTTPStubsDescriptor]()
    }()
    
    static func removeDescriptorFromNonForeverQueue(_ descriptor: OHHTTPStubsDescriptor) -> Bool {
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
    
    static func addDescriptorToNonForeverQueue(_ descriptor: OHHTTPStubsDescriptor) {
        descriptor.name = descriptor.debugDescription
        nonForeverQueuedDescriptors.append(descriptor)
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
        return STKPilotableHTTPServer.nonForeverQueuedDescriptors.count == 0
    }
    
    let scheme: String
    let host: String
    let documentRoot: String
    var defaultResponseHeaders: [String: String]?
    
    public init(scheme: String, host: String, documentRoot: String) {
        self.scheme = scheme
        self.host = host
        self.documentRoot = documentRoot
        OHHTTPStubs.onStubMissing({ (request) in
            NSLog("no served response queued for request \(request)")
        })
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
                            serveContentOfFileAtPath fileAtPath: String,
                            httpVerb: HTTPVerb = .get,
                            statusCode: Int32 = 200,
                            serveForever: Bool = false) -> URL {
        let stubPath = self.pathFromDocumentRoot(of: fileAtPath)
        let descriptor = stub(condition: isScheme(scheme) && isHost(host) && isPath(path) && isMethod(httpVerb)) { _ in
            return OHHTTPStubsResponse(fileAtPath: stubPath,
                                       statusCode: statusCode,
                                       headers: self.headersWithMimeTypeOfFile(at: fileAtPath))
        }
        if serveForever == false {
            STKPilotableHTTPServer.addDescriptorToNonForeverQueue(descriptor)
        }
        return urlForRequest(onPath: path)
    }
    
    @discardableResult
    public func makeRequest(onPath path: String,
                            beRedirectedToLocation toLocation: String,
                            statusCode: Int32 = 301,
                            serveForever: Bool = false) -> URL {
        let descriptor = stub(condition: isScheme(scheme) && isHost(host) && isPath(path)) { _ in
            return OHHTTPStubsResponse(data: Data(),
                                       statusCode: statusCode,
                                       headers: [HTTPHeaders.location.rawValue: toLocation])
        }
        if serveForever == false {
            STKPilotableHTTPServer.nonForeverQueuedDescriptors.append(descriptor)
        }
        return urlForRequest(onPath: path)
    }
}
