//
//  YZWebCalls.swift
//  AlmofireDemo
//
//  Created by Yudiz on 12/12/16.
//  Copyright © 2016 Yudiz. All rights reserved.
//

import Foundation
import Alamofire

// MARK: Web Operation
let kInternetDown       = "Your internet connection seems to be down"
let kHostDown           = "Your host seems to be down"
let kTimeOut            = "The request timed out"
let kTokenExpire        = "Session expired - please login again."
let _appName            = "AlamofierDemo"

func jprint(items: Any...) {
    for item in items {
        print(item)
    }
}

class AccessTokenAdapter: RequestInterceptor {
    var accessToken: String?
    
    init(accessToken: String? = nil) {
        self.accessToken = accessToken
    }
    
    func adapt(_ urlRequest: URLRequest, for session: Alamofire.Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var adaptedRequest = urlRequest
        if let accessToken = accessToken {
            adaptedRequest.setValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
        }
        completion(.success(urlRequest))
    }
    
    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        guard let response = request.task?.response as? HTTPURLResponse, response.statusCode == 401 else {
            /// The request did not fail due to a 401 Unauthorized response.
            /// Return the original error and don't retry the request.
            return completion(.doNotRetryWithError(error))
        }
    }
}

let _baseUrl = "http://www.json-generator.com/api/"
typealias WSBlock = (_ json: Any?, _ flag: Int) -> ()
typealias WSProgress = (Progress) -> ()?
typealias WSFileBlock = (_ path: String?, _ success: Bool) -> ()

class YZWebCall:NSObject{
    
    static var call: YZWebCall = YZWebCall()
    let manager: Session
    let accessTokenAdapter = AccessTokenAdapter()
    var networkManager: NetworkReachabilityManager
    var headers: HTTPHeaders = [
        "Content-Type": "application/x-www-form-urlencoded"
    ]
    
    var paramEncode: ParameterEncoding = URLEncoding.default
    
    var successBlock: (String, HTTPURLResponse?, AnyObject?, WSBlock) -> Void
    var errorBlock: (String, HTTPURLResponse?, NSError, WSBlock) -> Void
    
    override init() {
        manager = Session(interceptor: accessTokenAdapter)
        networkManager = NetworkReachabilityManager()!
        
        // Will be called on success of web service calls.
        successBlock = { (relativePath, res, respObj, block) -> Void in
            // Check for response it should be there as it had come in success block
            if let response = res{
                jprint(items: "Response Code: \(response.statusCode)")
                jprint(items: "Response(\(relativePath)): \(String(describing: respObj))")
                if response.statusCode == 200 {
                    block(respObj, response.statusCode)
                } else {
                    block(respObj, response.statusCode)
                }
            } else {
                // There might me no case this can get execute
                block(nil, 404)
            }
        }
        
        // Will be called on Error during web service call
        errorBlock = { (relativePath, res, error, block) -> Void in
            // First check for the response if found check code and make decision
            if let response = res {
                jprint(items: "Response Code: \(response.statusCode)")
                jprint(items: "Error Code: \(error.code)")
                if let data = error.userInfo["com.alamofire.serialization.response.error.data"] as? NSData {
                    let errorDict = (try? JSONSerialization.jsonObject(with: data as Data, options: JSONSerialization.ReadingOptions.mutableContainers)) as? NSDictionary
                    if errorDict != nil {
                        jprint(items: "Error(\(relativePath)): \(errorDict!)")
                        block(errorDict!, response.statusCode)
                        if response.statusCode == 423{

                        }
                    } else {
                        let code = response.statusCode
                        block(nil, code)
                    }
                } else {
                    block(nil, response.statusCode)
                }
                // If response not found rely on error code to find the issue
            } else if error.code == -1009  {
                jprint(items: "Error(\(relativePath)): \(error)")
                block([_appName: kInternetDown] as AnyObject, error.code)
                return
            } else if error.code == -1003  {
                jprint(items: "Error(\(relativePath)): \(error)")
                block([_appName: kHostDown] as AnyObject, error.code)
                return
            } else if error.code == -1001  {
                jprint(items: "Error(\(relativePath)): \(error)")
                block([_appName: kTimeOut] as AnyObject, error.code)
                return
            } else {
                jprint(items: "Error(\(relativePath)): \(error)")
                block(nil, error.code)
            }
        }
        super.init()
        addInternetListener()
    }
    
    deinit {
        networkManager.stopListening()
    }
}

// MARK: Other methods
extension YZWebCall{
    func getFullUrl(relPath : String) throws -> URL{
        do{
            if relPath.lowercased().contains("http") || relPath.lowercased().contains("www"){
                return try relPath.asURL()
            }else{
                return try (_baseUrl+relPath).asURL()
            }
        }catch let err{
            throw err
        }
    }
    
    func setAccesTokenToHeader(token:String){
        accessTokenAdapter.accessToken = token
    }
    
    func removeAccessTokenFromHeader(){
        accessTokenAdapter.accessToken = nil
    }
}

// MARK: - Request, ImageUpload and Dowanload methods
extension YZWebCall{
    func getRequest(relPath: String, param: [String: Any]?, block: @escaping WSBlock)-> DataRequest?{
        do{
            return manager.request(try getFullUrl(relPath: relPath), method: HTTPMethod.get, parameters: param, encoding: paramEncode, headers: headers).responseData { (resObj) in
                switch resObj.result{
                case .success:
                    if let resData = resObj.data{
                        do {
                            let res = try JSONSerialization.jsonObject(with: resData, options: [.allowFragments]) as AnyObject
                            self.successBlock(relPath, resObj.response, res, block)
                        } catch let errParse{
                            jprint(items: errParse)
                            self.errorBlock(relPath, resObj.response, errParse as NSError, block)
                        }
                    }
                    break
                case .failure(let err):
                    jprint(items: err)
                    self.errorBlock(relPath, resObj.response, err as NSError, block)
                    break
                }
            }
        }catch let error{
            jprint(items: error)
            errorBlock(relPath, nil, error as NSError, block)
            return nil
        }
    }
    
    func postRequest(relPath: String, param: [String: Any]?, block: @escaping WSBlock)-> DataRequest?{
        do{
            return manager.request(try getFullUrl(relPath: relPath), method: HTTPMethod.post, parameters: param, encoding: paramEncode, headers: headers).responseData { (resObj) in
                switch resObj.result{
                case .success:
                    if let resData = resObj.data{
                        do {
                            let res = try JSONSerialization.jsonObject(with: resData, options: []) as AnyObject
                            self.successBlock(relPath, resObj.response, res, block)
                        } catch let errParse{
                            jprint(items: errParse)
                            self.errorBlock(relPath, resObj.response, errParse as NSError, block)
                        }
                    }
                    break
                case .failure(let err):
                    jprint(items: err)
                    self.errorBlock(relPath, resObj.response, err as NSError, block)
                    break
                }
            }
        }catch let error{
            jprint(items: error)
            errorBlock(relPath, nil, error as NSError, block)
            return nil
        }
    }
    
    
    func uploadImage(relPath: String, img: UIImage, param: [String: String]?, block: @escaping WSBlock, progress: WSProgress?) {
        do {
            manager.upload(multipartFormData: { formData in
                formData.append(Data(), withName: "keyName", fileName: "image.jpeg", mimeType: "image/jpeg")
                if let param = param {
                    for (key, value) in param {
                        formData.append(Data(value.utf8), withName: key)
                    }
                }
            }, to: try getFullUrl(relPath: relPath), method: .post, headers: headers).uploadProgress { prog in
                progress?(prog)
            }.response { resObj in
                switch resObj.result{
                case .success:
                    if let resData = resObj.data{
                        do {
                            let res = try JSONSerialization.jsonObject(with: resData, options: []) as AnyObject
                            self.successBlock(relPath, resObj.response, res, block)
                        } catch let errParse{
                            jprint(items: errParse)
                            self.errorBlock(relPath, resObj.response, errParse as NSError, block)
                        }
                    }
                    break
                case .failure(let err):
                    jprint(items: err)
                    self.errorBlock(relPath, resObj.response, err as NSError, block)
                    break
                }
            }
        } catch let err {
            self.errorBlock(relPath, nil, err as NSError, block)
        }
    }
    
    func dowanloadFile(relPath : String, saveFileWithName: String, progress: WSProgress?, block: @escaping WSFileBlock){
        let destination: DownloadRequest.Destination = { _, _ in
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent("pig.png")
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        do{
            manager.download(try getFullUrl(relPath: relPath), to: destination).downloadProgress { (prog) in
                progress?(prog)
                }.response { (responce) in
                    if let destinationURL = responce.fileURL, responce.error == nil {
                        block(destinationURL.path, true)
                    } else {
                        block(nil, false)
                    }
                }
        }catch{
            block(nil, false)
        }
    }
}


// MARK: - Internet Availability
extension YZWebCall{
    func addInternetListener() {
        networkManager.startListening { status in
            if status == .notReachable {
                print("No Internet")
            } else {
                print("Internet Available")
            }
        }
    }
    
    func isInternetAvailable() -> Bool {
        return networkManager.isReachable
    }
}

// MARK: - API Call extention
extension YZWebCall{
    
    func simpleGetApiCall(block: @escaping WSBlock){
        let relPath = "json/get/cdTiCPExGq?indent=2"
        let _ = getRequest(relPath: relPath, param: nil, block: block)
    }
}
