//
//  Ticket.swift
//  ApiAIDemoWatchOSSwift
//
//  Created by Dx on 23/07/16.
//  Copyright © 2016 moak. All rights reserved.
//

import Foundation

class Ticket {
    var ticketName : String {
        get {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd MMM yy hh:mm"
            if let ticketDate = self.ticketDate {
            	let listedDateString = dateFormatter.string(from: ticketDate)
            	return "\(self.storeName) \(listedDateString)"
            } else {
                return ""
            }
        }
    }
    
	var id: String = ""
    var owner: String = ""
    var shoppingList: String = ""
    var storeId: String = ""
    var storeName: String = ""
    var storeLatitude: Double = 0
    var storeLongitude: Double = 0
    var ticketDate: Date! = nil
    var totalPrice: Float? = 0
    var sharedWith: [String] = []
    
    init(){
    }
    
    init(parameters: [String: AnyObject]) {
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        
        if let id = parameters["id"] as? String {
            self.id = id
        }
        
        if let owner = parameters["owner"] as? String {
            self.owner = owner
        }
        
        if let shoppingList = parameters["shoppingList"] as? String {
            self.shoppingList = shoppingList
        }
        
        if let storeId = parameters["storeId"] as? String {
            self.storeId = storeId
        }
        
        if let storeName = parameters["storeName"] as? String {
            self.storeName = storeName
        }
        
        if let purchasePosition = parameters["storePosition"] as? [String: AnyObject] {
            if let storeLatitude = purchasePosition["lat"] as? Double {
                self.storeLatitude = storeLatitude
            }
            if let storeLongitude = purchasePosition["long"] as? Double {
                self.storeLongitude = storeLongitude
            }
        }
        
        if let parameterTicketDate = parameters["ticketDate"] as? String {
            if let ticketDate = formatter.date(from: parameterTicketDate) {
                self.ticketDate = ticketDate
            }
        }
        
        if let totalPrice = parameters["totalPrice"] as? Float {
            self.totalPrice = totalPrice
        }
    }
    
    func getFirebaseObject() -> [String: AnyObject] {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        
        var formattedDate =  ""
        if let date = self.ticketDate {
            formattedDate = dateFormatter.string(from: date)
        }
        
        let firebaseParameters = [
            "id": self.id as AnyObject,
            "owner": self.owner as AnyObject,
			"shoppingList": self.shoppingList as AnyObject,
            "storeId": self.storeId as AnyObject,
            "storeName": self.storeName as AnyObject,
            "ticketDate": formattedDate as AnyObject,
            "sharedWith": sharedWith as AnyObject,
            "storePosition":
                ["lat":self.storeLatitude,
                "long":self.storeLongitude],
            "totalPrice": self.totalPrice!] as [String : Any]
        
        return firebaseParameters as [String : AnyObject]
    }
}
