//
//  GMSPlace.swift
//  moak
//
//  Created by Dx on 05/02/20.
//  Copyright © 2020 moak. All rights reserved.
//

import CoreLocation
import GooglePlaces


class MoakPlace {
    
    var id: String?
    var storeName: String?
    var address: String?
    var position: CLLocationCoordinate2D?
    
    init(googlePlace: GMSPlace) {
        self.id = googlePlace.placeID
        self.storeName = googlePlace.name
        self.address = googlePlace.formattedAddress
        self.position = googlePlace.coordinate
    }
    
    init(parameters: [String: AnyObject]) {
        
        self.position = nil
        if let listedPosition = parameters["position"] as? [String: AnyObject] {
            if let latitude = listedPosition["lat"] as? Double {
                if let longitude = listedPosition["long"] as? Double {
                    self.position = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                }
            }
        }
        
        if let id = parameters["id"] as? String {
            self.id = id
        }
        
        if let name = parameters["name"] as? String {
            self.storeName = name
        }
        
        if let address = parameters["address"] as? String {
            self.address = address
        }
    }
    
    func getFirebaseObject() -> [String: AnyObject] {
        
        let firebaseParameters = [
            "id": self.id!,
            "name": self.storeName!,
            "address": self.address ?? "",
            "position":
                ["lat":self.position?.latitude,
                 "long":self.position?.longitude]] as [String : Any]
        
        return firebaseParameters as [String : AnyObject]
        
    }
    
    func getStoreLocation() -> CLLocation {
        return CLLocation(latitude: self.position!.latitude, longitude: self.position!.longitude)
    }
    
    func getDistance() -> Int {
        let defaults = UserDefaults.standard
        let currentLocation = CLLocation(latitude: defaults.double(forKey: defaultKeys.currentLatitude), longitude: defaults.double(forKey: defaultKeys.currentLongitude))
        return Int((self.getStoreLocation() as AnyObject).distance(from: currentLocation))
    }
}
