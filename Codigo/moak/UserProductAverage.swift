//
//  UserProductAverage.swift
//  moak
//
//  Created by Dx on 30/05/17.
//  Copyright © 2017 moak. All rights reserved.
//

import Foundation

class UserProductAverage {
    var sku = ""
    var productName = ""
    var average: Double = 0
    var lastPrice: Float = 0
    var lastShoppingDate: Date! = nil
    
    init(){
    }
    
    init(sku: String, productName: String, average: Double, lastPrice: Float, lastShoppingDate: Date) {
        self.sku = sku
        self.productName = productName
        self.average = average
        self.lastPrice = lastPrice
        self.lastShoppingDate = lastShoppingDate
    }
    
    init(parameters: [String: AnyObject]) {
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        
        if let sku = parameters["sku"] as? String {
            self.sku = sku
        }
        
        if let productName = parameters["productName"] as? String {
            self.productName = productName
        }
        
        if let average = parameters["average"] as? Double {
            self.average = average
        }
        
        if let lastPrice = parameters["lastPrice"] as? Float {
            self.lastPrice = lastPrice
        }
        
        if let parameterLastShoppingDate = parameters["lastShoppingDate"] as? String {
            if let lastShoppingDate = formatter.date(from: parameterLastShoppingDate) {
                self.lastShoppingDate = lastShoppingDate
            }
        }
    }
    
    func nextShoppingDate() -> Date {
        let calendar = NSCalendar.current
        
        return calendar.date(byAdding: .day, value: Int(average), to: self.lastShoppingDate)!
    }
    
    func floatProgressBar() -> Double {
        
        if daysToBuy() <= 0 {
            return 1
        } else {
            return Swift.abs((Double(self.daysToBuy()) - Double(self.average)) / Double(self.average))
        }
    }
    
    func daysToBuy() -> Int {
        let calendar = NSCalendar.current
        
        let date1 = calendar.startOfDay(for: Date())
        let date2 = calendar.startOfDay(for: self.nextShoppingDate())
        
        let components = calendar.dateComponents([.day], from: date1, to: date2)
        return components.day!
    }
    
    func getFirebaseObject() -> [String: AnyObject] {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        var formattedDate =  ""
        if let date = self.lastShoppingDate {
            formattedDate = dateFormatter.string(from: date)
        }
        
        let firebaseParameters = [
            "sku": self.sku,
            "productName": self.productName,
            "average":average,
            "lastPrice":lastPrice,
            "lastShoppingDate":formattedDate] as [String : Any]
        
        return firebaseParameters as [String : AnyObject]
    }

}
