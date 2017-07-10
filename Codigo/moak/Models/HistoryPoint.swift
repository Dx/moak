//
//  HistoryPoint.swift
//  moak
//
//  Created by Dx on 27/08/16.
//  Copyright © 2016 Dx. All rights reserved.
//

import Foundation

class HistoryPoint {
    var id: String = ""
    var reason: String = ""
    var date: Date? = nil
    var points: Int = 0
    var userId: String = ""
    
    init(id: String, reason: String, date: Date, points: Int, userId: String) {
        self.id = id
        self.reason = reason
        self.date = date
        self.points = points
        self.userId = userId
    }
    
    init(parameters: [String: AnyObject]) {
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        
        if let id = parameters["id"] as? String {
            self.id = id
        }
        
        if let reason = parameters["reason"] as? String {
            self.reason = reason
        }
        
        if let parameterDate = parameters["date"] as? String {
            if let date = formatter.date(from: parameterDate) {
                self.date = date
            }
        }
        
        if let points = parameters["points"] as? Int {
            self.points = points
        }
        
        if let userId = parameters["userId"] as? String {
            self.id = userId
        }
    }
    
    func getFirebaseObject() -> [String: AnyObject] {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        let formattedDate = dateFormatter.string(from: self.date!)
        
        let firebaseParameters = [
            "id": self.id,
            "reason": self.reason,
            "date": formattedDate,
            "points":self.points,
            "userId":self.userId] as [String : Any]
        
        return firebaseParameters as [String : AnyObject]
    }

}
