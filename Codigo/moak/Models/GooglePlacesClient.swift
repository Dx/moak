//
//  GooglePlacesClient.swift
//  moak
//
//  Created by Dx on 12/05/17.
//  Copyright © 2017 moak. All rights reserved.
//

import Foundation
import GooglePlaces
import Alamofire

class GooglePlacesClient {
    
    func getCloserStore(currentLocation: CLLocation, completion: @escaping(_ result:GooglePlaceResult?, _ error: String?) -> Void) {
        self.getCloserStores(currentLocation: currentLocation) { (result: [GooglePlaceResult]?, error: String?) in
            if result != nil {
                completion(result![0], nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    func getCloserStoreIds(currentLocation: CLLocation, completion: @escaping (_ result:[String]?, _ error: String?) -> Void) {
        
        let queue = DispatchQueue(label: "searchClient", attributes: [.concurrent])
        
        let headers = ["Content-Type": "application/json"]
        
        let getUrl = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?key=AIzaSyDPfiiPEWUoKW4knF1T5NV_G1OTv4T0iIg&location=\(currentLocation.coordinate.latitude),\(currentLocation.coordinate.longitude)&radius=300&types=store&keyword=supermarket|convenience_store|food"
        
        let urlwithPercentEscapes = getUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        
        Alamofire.request(urlwithPercentEscapes!, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON(
            queue: queue,
            options: .allowFragments,
            completionHandler: { response in
                
                if response.result.value != nil {
                    if let values = response.result.value! as? [String: AnyObject] {
                        
                        if values["results"] != nil {
                            if let results = values["results"]! as? [AnyObject] {
                                if results.count < 1 {
                                    completion(nil, "Not found")
                                } else {
                                    var gpResults = [String]()
                                    for result in results {
                                        
                                        var placeId = ""
                                        if let pPlaceId = result["place_id"] as? String {
                                            placeId = pPlaceId
                                            gpResults.append(placeId)
                                        }
                                    }
                                    
                                    completion(gpResults, nil)
                                }
                            } else {
                                completion(nil, "Search failed")
                            }
                        } else {
                            completion(nil, "Service failed")
                        }
                    } else {
                        completion(nil, "Search failed")
                    }
                } else {
                    completion(nil, "Search failed")
                }
        }
        )
    }
    
    func getCloserStores(currentLocation: CLLocation, completion: @escaping (_ result:[GooglePlaceResult]?, _ error: String?) -> Void)  {
        
        let queue = DispatchQueue(label: "searchClient", attributes: [.concurrent])
        
        let headers = ["Content-Type": "application/json"]
        
        let getUrl = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?key=AIzaSyDPfiiPEWUoKW4knF1T5NV_G1OTv4T0iIg&location=\(currentLocation.coordinate.latitude),\(currentLocation.coordinate.longitude)&radius=200&types=store&keyword=supermarket|convenience_store|food|pharmacy"
        
        let urlwithPercentEscapes = getUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        
        print("urlToFindStores: \(getUrl)")
        
        Alamofire.request(urlwithPercentEscapes!, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON(
            queue: queue,
            options: .allowFragments,
            completionHandler: { response in
                
                if response.result.value != nil {
                    if let values = response.result.value! as? [String: AnyObject] {
                        
                        if values["results"] != nil {
                            if let results = values["results"]! as? [AnyObject] {
                                if results.count < 1 {
                                    completion(nil, "Not found")
                                } else {
                                    var gpResults = [GooglePlaceResult]()
                                    for result in results {
                                        
                                        var placeId = ""
                                        if let pPlaceId = result["place_id"] as? String {
                                            placeId = pPlaceId
                                        }
                                        
                                        var name = ""
                                        if let pName = result["name"] as? String {
                                            name = pName
                                        }
                                        
                                        var address = ""
                                        if let pAddress = result["vicinity"] as? String {
                                            address = pAddress
                                        }
                                        
                                        var latitude : Double = 0
                                        if let pLatitude = (((result["geometry"]! as! [String: AnyObject])["location"]) as! [String: AnyObject])["lat"] as? Double {
                                            latitude = pLatitude
                                        }
                                        
                                        var longitude : Double = 0
                                        if let pLongitude = (((result["geometry"]! as! [String: AnyObject])["location"]) as! [String: AnyObject])["lng"] as? Double {
                                            longitude = pLongitude
                                        }
                                        
                                        let gpResult = GooglePlaceResult(id: placeId, name: name, address: address, lat: latitude, lng: longitude)
                                        
                                        gpResult.distance = Int(gpResult.getStoreLocation().distance(from: currentLocation))
                                        
                                        gpResults.append(gpResult)
                                    }
                                    
                                    gpResults = gpResults.sorted( by: { $0.distance < $1.distance } )
                                    
                                    completion(gpResults, nil)
                                }
                            } else {
                                completion(nil, "Search failed")
                            }
                        } else {
                            completion(nil, "Service failed")
                        }
                    } else {
                        completion(nil, "Search failed")
                    }
                } else {
                    completion(nil, "Search failed")
                }
        }
        )
    }

}
