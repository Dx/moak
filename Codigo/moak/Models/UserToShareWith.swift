//
//  UserToShareWith.swift
//  ApiAIDemoWatchOSSwift
//
//  Created by Dx on 24/07/16.
//  Copyright © 2016 moak. All rights reserved.
//

import Foundation

class UserToShareWith {
    var id: String = ""
    var firstName: String = ""
    var lastName: String = ""
    var email: String = ""
    
    func getFirebaseObject() -> [String: AnyObject] {
        
        let firebaseParameters: [String: AnyObject] = [
            "id": self.id as AnyObject,
            "firstName": self.firstName as AnyObject,
            "lastName": self.lastName as AnyObject,
            "email": self.email as AnyObject]
        
        return firebaseParameters
    }

}
