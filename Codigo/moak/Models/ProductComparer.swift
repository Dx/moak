//
//  ProductComparer.swift
//  moak
//
//  Created by Dx on 14/08/16.
//  Copyright © 2016 Dx. All rights reserved.
//

import Foundation

class ProductComparer {
    var id = ""
    var sku = ""
    var productName = ""
    var storeId = ""
    var storeName = ""
    var capturedByUserId = ""
    var unitaryPrice: Float = 0
    var priceDate: Date! = nil
    
    init(){
    }
    
    init(sku: String, productName: String, storeId: String, storeName: String, capturedByUserId: String, unitaryPrice: Float, priceDate: Date) {
        self.sku = sku
        self.productName = productName
        self.storeId = storeId
        self.storeName = storeName
        self.capturedByUserId = capturedByUserId
        self.unitaryPrice = unitaryPrice
        self.priceDate = priceDate
    }
    
    init(parameters: [String: AnyObject]) {
        
        if let id = parameters["id"] as? String {
            self.id = id
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        
        if let sku = parameters["sku"] as? String {
            self.sku = sku
        }
        
        if let productName = parameters["productName"] as? String {
            self.productName = productName
        }
        
        if let storeId = parameters["storeId"] as? String {
            self.storeId = storeId
        }
        
        if let storeName = parameters["storeName"] as? String {
            self.storeName = storeName
        }
        
        if let capturedByUserId = parameters["capturedByUserId"] as? String {
            self.capturedByUserId = capturedByUserId
        }
        
        if let unitaryPrice = parameters["unitaryPrice"] as? Float {
            self.unitaryPrice = unitaryPrice
        }
        
        if let parameterPriceDate = parameters["priceDate"] as? String {
            if let priceDate = formatter.date(from: parameterPriceDate) {
                self.priceDate = priceDate
            }
        }
    }
    
    func getFirebaseObject() -> [String: AnyObject] {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        var formattedDate =  ""
        if let date = self.priceDate {
            formattedDate = dateFormatter.string(from: date)
        }
        
        let firebaseParameters = [
            "id": self.id as AnyObject,
            "sku": self.sku,
            "productName": self.productName,
            "storeId":self.storeId,
            "storeName":self.storeName,
            "capturedByUserId":self.capturedByUserId,
            "unitaryPrice":unitaryPrice,
        	"priceDate":formattedDate] as [String : Any]
        
        return firebaseParameters as [String : AnyObject]
    }
}
