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
        OHHTTPStubs.onStubMissing({ (request) in
            // ??
        })
        OHHTTPStubs.onStubActivation({ (request, descriptor, response) in
            removeDescriptorFromQueue(descriptor)
        })
        return [OHHTTPStubsDescriptor]()
    }()
    
    static func removeDescriptorFromQueue(_ descriptor: OHHTTPStubsDescriptor) {
        let index = nonForeverQueuedDescriptors.firstIndex(where: { (nonForeverDescriptor) -> Bool in
            return nonForeverDescriptor.name == descriptor.name
        })
        if let index = index {
            nonForeverQueuedDescriptors.remove(at: index)
        }
    }
    
    static func addDescriptorToQueue(_ descriptor: OHHTTPStubsDescriptor) {
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
        let descriptor = stub(condition: isScheme(scheme) && isHost(host) && isPath(path) && isMethod(httpVerb)) { _ in
            let stubPath = self.pathFromDocumentRoot(of: fileAtPath)
            return OHHTTPStubsResponse(fileAtPath: stubPath,
                                       statusCode: statusCode,
                                       headers: self.headersWithMimeTypeOfFile(at: path))
        }
        if serveForever == false {
            STKPilotableHTTPServer.nonForeverQueuedDescriptors.append(descriptor)
        }
        return urlForRequest(onPath: path)
    }
    
    public func makeRequest(onPath path: String,
                            beRedirectedToLocation toLocation: String,
                            statusCode: Int32 = 200,
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
    
    /*
    func enqueueToken200() {
        makeRequest(forVerb: "POST",
                    onPath: R.secure.api_path + R.secure.api_segment_token,
                    returnDataOfFile: "restests/api/token/200.json",
                    statusCode: 200,
                    serveForever: false)
    }
    
    func enqueueToken401() {
        makeRequest(forVerb: "POST",
                    onPath: R.secure.api_path + R.secure.api_segment_token,
                    returnDataOfFile: "restests/api/token/401.json",
                    statusCode: 401,
                    serveForever: false)
    }

    func mockCommonData() {
        stub(condition: isScheme(R.secure.https_scheme) && isHost(R.secure.ws_host_dev) && isPath("\(R.secure.ws_api_base_path)\(R.secure.ws_common_data_path)")) { _ in
            
            // Stub it with our "wsresponse.json" stub file (which is in same bundle as self)
            if let stubPath = OHPathForFile("ressources/webservices/get/common_datas.json", type(of: self)) {
                //return fixture(filePath: stubPath!, headers: ApiRequest.headers)
                return OHHTTPStubsResponse(fileAtPath: stubPath, statusCode: 200, headers: ApiRequest.headers + ["Content-Type": "application/json"])
            }
            return OHHTTPStubsResponse(fileAtPath: "", statusCode: 666, headers: ApiRequest.headers)
        }
    }
    */
}
