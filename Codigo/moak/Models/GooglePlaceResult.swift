//
//  GooglePlaceResult.swift
//  ApiAIDemoWatchOSSwift
//
//  Created by Dx on 13/05/16.
//  Copyright © 2016 moak. All rights reserved.
//

import Foundation
import CoreLocation

class GooglePlaceResult {
    var id: String = ""
    var name: String = ""
    var address: String = ""
    var latitude: Double = 0
    var longitude: Double = 0
    var distance: Int = 0
    
    init(id: String, name: String, address: String, lat: Double, lng: Double) {
        self.id = id
        self.name = name
        self.address = address
        self.latitude = lat
        self.longitude = lng
    }
    
    init(parameters: [String: AnyObject]) {
        
        if let listedPosition = parameters["position"] as? [String: AnyObject] {
            if let latitude = listedPosition["lat"] as? Double {
                self.latitude = latitude
            }
            if let longitude = listedPosition["long"] as? Double {
                self.longitude = longitude
            }
        }
        
        if let id = parameters["id"] as? String {
            self.id = id
        }
        
        if let name = parameters["name"] as? String {
            self.name = name
        }
        
        if let address = parameters["address"] as? String {
            self.address = address
        }
    }
    
    func getFirebaseObject() -> [String: AnyObject] {
        
        let firebaseParameters = [
            "id": self.id,
            "name": self.name,
            "address": self.address,
            "position":
                ["lat":self.latitude,
                "long":self.longitude]
            ] as [String : Any]
        
        return firebaseParameters as [String : AnyObject]
    }
    
    func getStoreLocation() -> CLLocation {
        return CLLocation(latitude: self.latitude, longitude: self.longitude)
    }
}
