//
//  User.swift
//  ApiAIDemoWatchOSSwift
//
//  Created by Dx on 19/07/16.
//  Copyright © 2016 moak. All rights reserved.
//

import Foundation

class User {
    var id: String = ""
    var name: String = ""
    var userName: String = ""
    var email: String = ""
    var firstName: String = ""
    var lastName: String = ""
    var gender: String = ""
    var birthday: Date? = nil
    var location: String = ""
    var points: Int = 0
    var level: Int = 0
    var lists: [String: String]
    var buyedLists: [String: String]
    
    init(id: String, name: String?, userName: String?, email: String?, firstName: String?, lastName: String?, gender: String?, birthday: Date?, location: String?, level: Int, points: Int, lists: [String: String], buyedLists: [String: String]) {
        self.id = id
        
        if name != nil {
        	self.name = name!
        }
        
        if userName != nil {
            self.userName = userName!
        }
        
        if email != nil {
        	self.email = email!
        }
        
        if firstName != nil {
        	self.firstName = firstName!
        }
        
        if lastName != nil {
        	self.lastName = lastName!
        }
        
        if gender != nil {
        	self.gender = gender!
        }
        
        if birthday != nil {
        	self.birthday = birthday
        }
        
        if location != nil {
        	self.location = location!
        }
        
        self.lists = lists
        self.buyedLists = buyedLists
        self.points = points
        self.level = level
    }
    
    func getFirebaseObject() -> [String: AnyObject] {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        var formattedBirthday = ""
        if self.birthday != nil {
            formattedBirthday = dateFormatter.string(from: self.birthday!)
        }
        
        let firebaseParameters = [
            "id": self.id,
            "name": self.name,
            "userName": self.userName,
            "email":self.email,
            "firstName":self.firstName,
            "lastName":self.lastName,
            "gender":self.gender,
            "birthday":formattedBirthday,
            "location":self.location,
            "lists": self.lists,
            "buyedLists": self.buyedLists] as [String : Any]
        
        return firebaseParameters as [String : AnyObject]
    }
}
