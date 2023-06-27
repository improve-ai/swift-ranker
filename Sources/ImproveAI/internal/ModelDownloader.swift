//
//  File.swift
//  
//
//  Created by Hongxi Pan on 2022/11/23.
//

import Foundation
import CoreML
import zlib
import struct Foundation.Data

typealias DownloadCompletionBlock = (URL?, Error?) -> Void

class ModelLoader : NSObject {
    lazy var session: URLSession = {
        return URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue())
    }()
    
    let url: URL
    
    var zstream = z_stream()
    
    var unzippedFileHandle: FileHandle?
    
    var unzippedFileURL: URL!
    
    var unzippedOK: Bool = false
    
    var completionHandler: DownloadCompletionBlock?
    
    init(url: URL) {
        self.url = url
    }
    
    public func loadAsync(_ url: URL, completion handler: @escaping DownloadCompletionBlock) {
        if url.hasDirectoryPath {
            handler(url, nil)
            return
        }
        
        if url.absoluteString.hasSuffix(".gz") {
            loadZippedModel(url: url, completion: handler)
        } else {
            loadPlainModel(url: url, completion: handler)
        }
    }
    
    func compileModel(url: URL) throws -> URL {
        let startTime = CFAbsoluteTimeGetCurrent()
        let compiledURL = try MLModel.compileModel(at: url)
        print("[ImproveAI] model: \(url.lastPathComponent) compile time \((CFAbsoluteTimeGetCurrent() - startTime) * 1000)ms")
        return compiledURL
    }
}

extension ModelLoader {
    func loadPlainModel(url: URL, completion handler: @escaping DownloadCompletionBlock) {
        let session = URLSession.shared
        let request = URLRequest(url: url)
        let task = session.downloadTask(with: request) { location, response, error in
            if error != nil {
                handler(nil, error)
                return
            }
            
            do {
                let compiledURL = try self.compileModel(url: location!)
                handler(compiledURL, nil)
            } catch {
                handler(nil, error)
            }
        }
        task.resume()
    }
}

extension ModelLoader : URLSessionDataDelegate {
    func loadZippedModel(url: URL, completion handler: @escaping DownloadCompletionBlock) {
        var request = URLRequest(url: url)
        request.addValue("identity", forHTTPHeaderField: "Accept-Encoding")
        let task = self.session.dataTask(with: request)
        self.completionHandler = handler
        task.resume()
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        if let response = response as? HTTPURLResponse {
            if response.statusCode != 200 {
                completionHandler(.cancel)
                return
            }
        }
        
        let uuid = UUID().uuidString
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("ai.improve.tmp.\(uuid).mlmodel")
        if !FileManager.default.createFile(atPath: url.path, contents: nil) {
            completionHandler(.cancel)
            return
        }
        
        guard let fileHandle = FileHandle(forWritingAtPath: url.path) else {
            completionHandler(.cancel)
            return
        }
        
        unzippedFileHandle = fileHandle
        unzippedFileURL = url
        
        guard Z_OK == inflateInit2_(&zstream, 47, ZLIB_VERSION, Int32(DataSize.stream)) else {
            completionHandler(.cancel)
            return
        }
        
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        var status: Int32 = Z_OK
        var zipOutputData = Data(capacity: data.count * 2)
        let total_out = zstream.total_out
        data.withUnsafeBytes { (inputPointer: UnsafeRawBufferPointer) in
            zstream.next_in = UnsafeMutablePointer<Bytef>(mutating: inputPointer.bindMemory(to: Bytef.self).baseAddress!)
            zstream.avail_in += uInt(data.count)
            
            repeat {
                if (zstream.total_out - total_out) >= zipOutputData.count {
                    zipOutputData.count += data.count * 2
                }
                let outputCount = zipOutputData.count
                zipOutputData.withUnsafeMutableBytes { (outputPointer: UnsafeMutableRawBufferPointer) in
                    zstream.next_out = outputPointer.bindMemory(to: Bytef.self).baseAddress!.advanced(by: Int(zstream.total_out - total_out))
                    zstream.avail_out = uInt(outputCount) - uInt(zstream.total_out - total_out)
                    status = inflate(&zstream, Z_SYNC_FLUSH)
                }
            } while status == Z_OK && (zstream.total_out - total_out) >= zipOutputData.count
        }
        
        if status == Z_OK || status == Z_STREAM_END || status == Z_BUF_ERROR {
            zipOutputData.count = Int(zstream.total_out - total_out)
            
            if #available(iOS 13.4, *) {
                do {
                    try unzippedFileHandle?.write(contentsOf: zipOutputData)
                    if status == Z_STREAM_END {
                        unzippedOK = true
                    }
                } catch {
                }
            } else {
                // TODO: the write method could raise an exception
                unzippedFileHandle?.write(zipOutputData)
                if status == Z_STREAM_END {
                    unzippedOK = true
                }
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if error != nil {
            inflateEnd(&zstream)
            self.completionHandler?(nil, error)
            return
        }
        
        let status = inflateEnd(&zstream)
        guard status == Z_OK else {
            self.completionHandler?(nil, ImproveAIError.downloadFailure(reason: "unzip error \(status)"))
            return
        }
        
        guard unzippedOK else {
            self.completionHandler?(nil, ImproveAIError.downloadFailure(reason: "unzip error"))
            return
        }
        
        guard let compiledURL = try? self.compileModel(url: unzippedFileURL) else {
            self.completionHandler?(nil, ImproveAIError.invalidModel(reason: "failed to compile \(url). Is it a valid model?"))
            return
        }
        
        self.completionHandler?(compiledURL, nil)
    }
    
    private enum DataSize {
        static let stream = MemoryLayout<z_stream>.size
    }
}
