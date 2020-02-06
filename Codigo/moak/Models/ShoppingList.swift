//
//  ShoppingList.swift
//  ApiAIDemoWatchOSSwift
//
//  Created by Dx on 19/07/16.
//  Copyright © 2016 moak. All rights reserved.
//

import Foundation
import CoreLocation

class ShoppingList {
    var id: String = ""
    var name: String = ""
    var owner: String = ""
    var place: MoakPlace? = nil
    var placeShopping: MoakPlace? = nil
    var sharedWith = [String: AnyObject]()
    
    init(id: String, name: String, owner: String) {
        self.id = id
        self.name = name
        self.owner = owner
    }
    
    init(parameters: [String: AnyObject]) {
        
        if let id = parameters["id"] as? String {
            self.id = id
        }
        
        if let name = parameters["name"] as? String {
            self.name = name
        }
        
        if let owner = parameters["owner"] as? String {
            self.owner = owner
        }
        
        if let sharedWith = parameters["sharedWith"] as? [String: AnyObject] {
            self.sharedWith = sharedWith
        }
        
        //TODO: Cambiar a GMSPlace
        if let paramsPlace = parameters["place"] as? [String: AnyObject] {
        	self.place = MoakPlace.init(parameters: paramsPlace)
        }

        if let paramsPlaceShopping = parameters["placeShopping"] as? [String: AnyObject] {
            self.placeShopping = MoakPlace.init(parameters: paramsPlaceShopping)
        }
    }
    
    func getFirebaseObject() -> [String: AnyObject] {
        
        if self.place == nil {
        
        	let firebaseParameters = [
            	"id": self.id,
            	"name": self.name,
            	"owner":self.owner,
            	"sharedWith":self.sharedWith] as [String : Any]
            
            return firebaseParameters as [String : AnyObject]
        } else {
            
            var placeObject = [String: AnyObject]()
            var placeShoppingObject = [String: AnyObject]()
            
            if self.place != nil {
                placeObject = self.place!.getFirebaseObject()
            }
            
            if self.placeShopping != nil {
                placeShoppingObject = self.placeShopping!.getFirebaseObject()
            }
            
            let firebaseParametersPlace = [
                "id": self.id,
                "name": self.name,
                "owner":self.owner,
                "sharedWith":self.sharedWith,
                "place": placeObject,
                "placeShopping": placeShoppingObject]
                as [String : Any]
            
            return firebaseParametersPlace as [String : AnyObject]
        }
    }
}
