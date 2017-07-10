//
//  ChrixClient.swift
//  moak
//
//  Created by Dx on 20/12/16.
//  Copyright © 2016 moak. All rights reserved.
//

import Foundation
import Alamofire

class ChrixClient {
    
    var sessionManager = SessionManager()
    
    init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10
        self.sessionManager = Alamofire.SessionManager(configuration: configuration)
    }
    
    func askForSuggestedList(userName: String, idlist: String,  completion: @escaping (_ result:String) -> Void)  {
        
        let params: Parameters = ["iduser": userName, "idlist": idlist]
        
        self.sessionManager.request("https://cvp4m11h12.execute-api.us-west-2.amazonaws.com/produccion/entirelist?iduser=\(userName)&idlist=\(idlist)", method: .post, parameters: params, encoding: JSONEncoding.default).responseString{ (response: DataResponse<String>) in
            
            print(response)
            
            completion(response.description)
        }
    }
}
