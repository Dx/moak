//
//  Product.swift
//  ApiAIDemoWatchOSSwift
//
//  Created by Dx on 03/07/16.
//  Copyright © 2016 moak. All rights reserved.
//

import Foundation
import CoreLocation

class Product {
    var productId: String = ""
    var userId: String = ""
    
    var productName: String = ""
    var productSKUName: String = ""
    var productSKU: String = ""
    var quantity: Float = 0
    var listedDate: Date!
    var listedLatitude: Double!
    var listedLongitude: Double!
    
    var checked: Bool = false
    var checkedLatitude: Double!
    var checkedLongitude: Double!
    var checkedDate: Date?
    
    var modeBuying: Int = 0
    
    var shoppingList: String = ""
    
    var unitaryPrice: Float = 0
    var totalPrice: Float = 0
    
    var unitaryEstimatedPrice: Float = 0
    var totalEstimatedPrice: Float = 0
    
    var listedOrder: Float = 0
    
    var ticketId = ""
    
    convenience init (productName: String, productSKUName: String, productSKU: String, lat:Double, lng: Double, order: Float, shoppingList: String) {
        
        self.init(productName: productName, productSKUName: productSKUName, productSKU: productSKU, quantity: 1, listedDate: Date(), listedLatitude: lat, listedLongitude: lng, modeBuying: 0, checked: false, order: order, shoppingList: shoppingList)
    }
    
    init (productName: String, productSKUName: String, productSKU: String, quantity: Float, listedDate: Date, listedLatitude: Double, listedLongitude: Double, modeBuying: Int, checked: Bool, order: Float, shoppingList: String) {
        
        let defaults = UserDefaults.standard
        
        if let puserId = defaults.string(forKey: "userId") {
            self.userId = puserId
        } else {
            self.userId = "unknown"
        }
        
        self.listedOrder = order
        self.productId = "1"
        self.productName = productName
        self.productSKUName = productSKUName
        self.productSKU = productSKU
        self.shoppingList = shoppingList
        self.quantity = quantity
        self.listedDate = listedDate
        self.listedLatitude = listedLatitude
        self.listedLongitude = listedLongitude
        self.modeBuying = modeBuying
        self.checkedLatitude = 0
        self.checkedLongitude = 0
        self.checked = checked
    }
    
    init(parameters: [String: AnyObject]) {
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        
        if let productId = parameters["productId"] as? String {
            self.productId = productId
        } else {
            self.productId = ""
        }
        
        if let userId = parameters["userId"] as? String {
        	self.userId = userId
        }
        
        if let productName = parameters["productName"] as? String {
        	self.productName = productName
        }
        
        if let productSKUName = parameters["productSKUName"] as? String {
            self.productSKUName = productSKUName
        }
        
        if let productSKU = parameters["productSKU"] as? String {
            self.productSKU = productSKU
        }
        
        if let shoppingList = parameters["shoppingList"] as? String {
            self.shoppingList = shoppingList
        }
        
        if let ticketId = parameters["ticketId"] as? String {
            self.ticketId = ticketId
        }
        
        if let quantity = parameters["quantity"] as? Float {
        	self.quantity = quantity
        }
        
        if parameters["listedDate"] != nil {
        	if let listedDate = formatter.date(from: parameters["listedDate"] as! String) {
            	self.listedDate = listedDate
        	}
        }
        
        if let listedPosition = parameters["listedPosition"] as? [String: AnyObject] {
        	if let listedLatitude = listedPosition["lat"] as? Double {
            	self.listedLatitude = listedLatitude
        	}
            if let listedLongitude = listedPosition["long"] as? Double {
                self.listedLongitude = listedLongitude
            }
        }
        
        if let listedOrder = parameters["listedOrder"] as? Float {
            self.listedOrder = listedOrder
        }
        
        if let modeBuying = parameters["modeBuying"] as? Int {
            self.modeBuying = modeBuying
        }
        
        if let checked = parameters["checked"] as? Bool {
        	self.checked = checked
        }
        
        if let unitaryPrice = parameters["unitaryPrice"] as? Float {
        	self.unitaryPrice = unitaryPrice
        }
        
        if let totalPrice = parameters["totalPrice"] as? Float {
        	self.totalPrice = totalPrice
        }
        
        if let parameterCheckedDate = parameters["checkedDate"] as? String {
        	if let checkedDate = formatter.date(from: parameterCheckedDate) {
        		self.checkedDate = checkedDate
        	}
        }
        
        if let purchasePosition = parameters["checkedPosition"] as? [String: AnyObject] {
            if let checkedLatitude = purchasePosition["lat"] as? Double {
                self.checkedLatitude = checkedLatitude
            }
            if let checkedLongitude = purchasePosition["long"] as? Double {
                self.checkedLongitude = checkedLongitude
            }
        }
    }
    
    func getFirebaseObject() -> [String: AnyObject] {
        
        let fchecked = NSNumber.init(value: self.checked as Bool)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        let formattedListedDate = dateFormatter.string(from: self.listedDate)
        
        var formattedPurchasedDate = ""
        if self.checkedDate != nil {
        	formattedPurchasedDate = dateFormatter.string(from: self.checkedDate!)
        }
        
        let firebaseParameters = [
            "productId": self.productId,
            "userId": self.userId,
            "productName":self.productName,
            "productSKUName":self.productSKUName,
            "productSKU":self.productSKU,
            "shoppingList":self.shoppingList,
            "ticketId":self.ticketId,
            "quantity": self.quantity,
            "listedDate":formattedListedDate,
            "listedPosition":
                ["lat":self.listedLatitude!,
                "long":self.listedLongitude!],
            "listedOrder":self.listedOrder,
            "checked": fchecked,
            "unitaryPrice":self.unitaryPrice,
            "totalPrice":self.totalPrice,
            "modeBuying": self.modeBuying,
            "checkedDate":formattedPurchasedDate,
            "checkedPosition":["lat":checkedLatitude!,
                "long":checkedLongitude!]] as [String : Any]
            
		return firebaseParameters as [String : AnyObject]
    }
}
