//
//  LocationModel.swift
//  moak
//
//  Created by Dx on 22/01/20.
//  Copyright © 2020 palmera. All rights reserved.
//

import CoreLocation
import GooglePlaces

class LocationModel: NSObject, CLLocationManagerDelegate {
        
    private lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        manager.allowsBackgroundLocationUpdates = false
        return manager
    }()
    
    func getCloserStores(completion: @escaping(_ result: [MoakPlace]?) -> Void) {
        // Specify the place data types to return.
        let fields: GMSPlaceField = GMSPlaceField(rawValue: UInt(GMSPlaceField.name.rawValue) | UInt(GMSPlaceField.placeID.rawValue) | UInt(GMSPlaceField.types.rawValue))!
        
        var result: [MoakPlace]?
        
        let placesClient = GMSPlacesClient()
        placesClient.findPlaceLikelihoodsFromCurrentLocation(withPlaceFields: fields, callback: {
          (placeLikelihoodList: Array<GMSPlaceLikelihood>?, error: Error?) in
            if let error = error {
                print("An error occurred: \(error.localizedDescription)")
                return
            }

            if let placeLikelihoodList = placeLikelihoodList {
                result = [MoakPlace]()
                
                for likelihood in placeLikelihoodList {
                    
                    let place = likelihood.place
                    
                    // if likelihood.likelihood > 0.3 &&
                    if ((place.types?.contains("supermarket"))! || (place.types?.contains("grocery_or_supermarket"))! || (place.types?.contains("pharmacy"))!) {
                        
                        
                        result?.append(MoakPlace(googlePlace: place))
                    }
                }
                
                completion(result)
            }
        })
    }
    
    func getCurrentLocation(completion: @escaping(_ result: MoakPlace?) -> Void) {
        
        // Specify the place data types to return.
        let fields: GMSPlaceField = GMSPlaceField(rawValue: UInt(GMSPlaceField.name.rawValue) | UInt(GMSPlaceField.placeID.rawValue) | UInt(GMSPlaceField.types.rawValue))!
        
        let placesClient = GMSPlacesClient()
        placesClient.findPlaceLikelihoodsFromCurrentLocation(withPlaceFields: fields, callback: {
          (placeLikelihoodList: Array<GMSPlaceLikelihood>?, error: Error?) in
            if let error = error {
                print("An error occurred: \(error.localizedDescription)")
                return
            }

            if let placeLikelihoodList = placeLikelihoodList {
                for likelihood in placeLikelihoodList {
                    
                    let place = likelihood.place
                    print("Current Place name \(String(describing: place.name)) likelihood: \(likelihood.likelihood) PlaceId: \(String(describing: place.placeID)) PlaceTypes: \(String(describing: place.types))")
                    
                    if likelihood.likelihood > 0.6 && ((place.types?.contains("supermarket"))! || (place.types?.contains("grocery_or_supermarket"))! || (place.types?.contains("store"))! || (place.types?.contains("pharmacy"))!) {
                        
                        completion(MoakPlace(googlePlace: place))
                        return
                    }
                }
                
                
            }
        })
    }
}
