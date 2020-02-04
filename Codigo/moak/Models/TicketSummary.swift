//
//  TicketSummary.swift
//  ApiAIDemoWatchOSSwift
//
//  Created by Dx on 06/08/16.
//  Copyright © 2016 moak. All rights reserved.
//

import Foundation

class TicketSummary {
    var id: String!
    var storeName: String = ""
    var totalPrice: Float = 0
    var ticketDate: Date! = nil
    
    init(id: String, storeName: String, totalPrice: Float, ticketDate: Date) {
        self.id = id
        self.storeName = storeName
        self.totalPrice = totalPrice
        self.ticketDate = ticketDate
    }
    
    init(parameters: [String: AnyObject]) {
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        
        if let id = parameters["id"] as? String {
            self.id = id
        }
        
        if let storeName = parameters["storeName"] as? String {
            self.storeName = storeName
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
            "id": self.id!,
            "storeName": self.storeName,
            "totalPrice":self.totalPrice,
            "ticketDate":formattedDate] as [String : Any]
        
        return firebaseParameters as [String : AnyObject]
    }
}
