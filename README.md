# YZWebCall Demo with Alamofire
Minimal coding for API calls using alamofier, `YZWebCall` Allow user to create it's API call method and return response in block.

## Useges
+ Install `Alamofier` via pod and add `YZWebCall.swift` file in your project.

+ if your base url if fixed then set it to `_baseUrl` in `YZWebCall`
```
let _baseUrl = // Your base path
```

+ First you want to create your own api method under ApiCall extention. in this you need to add your relative path, request param if needed, and pass `WSBlock` in method argument for hundle respose. `YZWebCall` provide methods like `getRequest`, `postRequest`, and `uploadImage` for multipart request.

```
// MARK: - API Call extention
extension YZWebCall{
    // Demo 
    func simpleGetApiCall(block: @escaping WSBlock){
        let relPath = // Your api relative path
        let _ = getRequest(relPath: relPath, param: nil, block: block)
    }
    
    // If you make another api call then create second method
    func simpleGetApiCall2(userID: String, block: @escaping WSBlock){
        let relPath = // Your api relative path
        let param = ["userID" : userID]
        let _ = getRequest(relPath: relPath, param: param, block: block)
    }
}
```

+ Now you can call your api form anywhere in your project and get respose in it's own block
```
YZWebCall.call.simpleGetApiCall { (json, statusCode) in
  // Your code
  // josn is responce data
  // statusCode is http responce status code.
}
```

+ Also you can dowanload file with `YZWebCall` in simplest way, you need to create one more method for dowanload file, simple as api call.
```
// MARK: - API Call extention
extension YZWebCall{
  // api call 1
  // api call 2

  func dowanlodFileCall(progressBlock: @escaping WSProgress, resBlock: @escaping WSFileBlock){
      let relPath = "Your path"
      dowanloadFile(relPath: relPath, saveFileWithName: "file.png", progress: progressBlock, block: resBlock)
  }
}
```

+ Now you can call `dowanlodFileCall` method from your any controller and get dowanload progeress block and dowanload completion block with dowanloaded image path
```
YZWebCall.call.dowanlodFileCall(progressBlock: { (progress) -> ()? in
    // progress of dowanload
}) { (path, isComplete) in
    // completion or failur. with dowanloade file path
}
```

## Other API Usages

+ `YZWebCall.swift` allow you make your webcall simple and esier. set your http header in `headers` in 'YZWebCall' file. also it allow to set parameter encoding like. (Josn, xml), default set to urlencoding.
```
var headers: HTTPHeaders = [
  "Content-Type": "application/x-www-form-urlencoded"
]
var paramEncode: ParameterEncoding = URLEncoding.default
```

+ `YZWebCall` has one more important method to set `Authorization` in http header. it accept tokern in string argument.
```
YZWebCall.call.setAccesTokenToHeader(token: "")
```

+ Remove `Authorization` from http header
```
YZWebCall.call.removeAccessTokenFromHeader()
```

+ It Also provied reachability block for internet. it called when internet seems to be down or avalable. you can hundel no internet event in following code.
```
func addInterNetListner(){
        networkManager.listener = { (status) in
            if status == NetworkReachabilityManager.NetworkReachabilityStatus.notReachable{
              // Your Code
            }else{
              // Your Code
            }
        }
        networkManager.startListening()
    }
```

+ If you want to check fot internet at any point then it also provide one mothod for check internet status in boolen.
```
let isAvail = YZWebCall.call.isInternetAvailable()
```
