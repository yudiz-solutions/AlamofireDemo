//
//  KPWebCalls.swift
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

class AccessTokenAdapter: RequestAdapter {
    private let accessToken: String
    
    init(accessToken: String) {
        self.accessToken = accessToken
    }
    
    func adapt(_ urlRequest: URLRequest) throws -> URLRequest {
        var urlRequest = urlRequest
        urlRequest.setValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
        return urlRequest
    }
}

let _baseUrl = "http://www.json-generator.com/api/"
typealias WSBlock = (_ json: Any?, _ flag: Int) -> ()
typealias WSProgress = (Progress) -> ()?
typealias WSFileBlock = (_ path: String?, _ success: Bool) -> ()

class KPWebCall:NSObject{

    static var call: KPWebCall = KPWebCall()
    
    let manager: SessionManager
    var networkManager: NetworkReachabilityManager
    var headers: HTTPHeaders = [
        "Content-Type": "application/x-www-form-urlencoded"
    ]
    
    var paramEncode: ParameterEncoding = URLEncoding.default
    
    var successBlock: (String, HTTPURLResponse?, AnyObject?, WSBlock) -> Void
    var errorBlock: (String, HTTPURLResponse?, NSError, WSBlock) -> Void
    
    override init() {
        manager = Alamofire.SessionManager.default
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
        addInterNetListner()
    }
    
    deinit {
        networkManager.stopListening()
    }
}

// MARK: Other methods
extension KPWebCall{
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
        manager.adapter = AccessTokenAdapter(accessToken: token)
    }
    
    func removeAccessTokenFromHeader(){
        manager.adapter = nil
    }
}

// MARK: - Request, ImageUpload and Dowanload methods
extension KPWebCall{
    func getRequest(relPath: String, param: [String: Any]?, block: @escaping WSBlock)-> DataRequest?{
        do{
            return manager.request(try getFullUrl(relPath: relPath), method: HTTPMethod.get, parameters: param, encoding: paramEncode, headers: headers).responseJSON { (resObj) in
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
    
    func postRequest(relPath: String, param: [String: Any]?, block: @escaping WSBlock)-> DataRequest?{
        do{
            return manager.request(try getFullUrl(relPath: relPath), method: HTTPMethod.post, parameters: param, encoding: paramEncode, headers: headers).responseJSON { (resObj) in
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
    
    
    func uploadImage(relPath: String,img: UIImage,param: [String: String]?, block: @escaping WSBlock, progress: WSProgress?){
        do{
            manager.upload(multipartFormData: { (formData) in
                formData.append(img.jpegData(compressionQuality: 1.0)!, withName: "keyName", fileName: "image.jpeg", mimeType: "image/jpeg")
                if let _ = param{
                    for (key, value) in param!{
                        formData.append(value.data(using: String.Encoding.utf8, allowLossyConversion: false)!, withName: key)
                    }
                }
            }, to: try getFullUrl(relPath: relPath), method: HTTPMethod.post, headers: headers, encodingCompletion: { encoding in
                switch encoding{
                case .success(let req, _, _):
                    req.uploadProgress(closure: { (prog) in
                        progress?(prog)
                    }).responseJSON { (resObj) in
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
                    break
                case .failure(let err):
                    jprint(items: err)
                    self.errorBlock(relPath, nil, err as NSError, block)
                    break
                }
            })
        }catch let err{
            self.errorBlock(relPath, nil, err as NSError, block)
        }
    }
    
    func dowanloadFile(relPath : String, saveFileWithName: String, progress: WSProgress?, block: @escaping WSFileBlock){
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent("pig.png")
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        do{
            manager.download(try getFullUrl(relPath: relPath), to: destination).downloadProgress { (prog) in
                progress?(prog)
                }.response { (responce) in
                    if responce.error == nil, let path = responce.destinationURL?.path{
                        block(path, true)
                    }else{
                        block(nil, false)
                    }
                }.resume()

        }catch{
            block(nil, false)
        }
    }
}


// MARK: - Internet Availability
extension KPWebCall{
    func addInterNetListner(){
        networkManager.listener = { (status) in
            if status == NetworkReachabilityManager.NetworkReachabilityStatus.notReachable{
                print("No InterNet")
            }else{
                print("Internet Avail")
            }
        }
        networkManager.startListening()
    }
    
    func isInternetAvailable() -> Bool {
        if networkManager.isReachable{
            return true
        }else{
            return false
        }
    }
}

// MARK: - API Call extention
extension KPWebCall{
    
    func simpleGetApiCall(block: @escaping WSBlock){
        let relPath = "json/get/cdTiCPExGq?indent=2"
        let _ = getRequest(relPath: relPath, param: nil, block: block)
    }
}
