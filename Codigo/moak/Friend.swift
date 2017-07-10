//
//  Friend.swift
//  moak
//
//  Created by Dx on 06/10/16.
//  Copyright © 2016 moak. All rights reserved.
//

import Foundation

class Friend {
    
    var id: String = ""
    var firstName: String = ""
    var lastName: String = ""
    var email: String = ""
    var points: Int = 0
    
    init(parameters: [String: AnyObject]) {
        
        if let id = parameters["id"] as? String {
            self.id = id
        }
        
        if let firstName = parameters["firstName"] as? String {
            self.firstName = firstName
        }
        
        if let lastName = parameters["lastName"] as? String {
            self.lastName = lastName
        }
        
        if let email = parameters["email"] as? String {
            self.email = email
        }
        
        if let points = parameters["points"] as? Int {
            self.points = points
        }
    }
    
    func getFirebaseObject() -> [String: AnyObject] {
        
        let firebaseParameters: [String: AnyObject] = [
            "id": self.id as AnyObject,
            "firstName": self.firstName as AnyObject,
            "lastName": self.lastName as AnyObject,
            "email": self.email as AnyObject,
            "points": self.points as AnyObject]
        
        return firebaseParameters
    }
}
