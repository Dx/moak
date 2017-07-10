//
//  GameLevels.swift
//  moak
//
//  Created by Dx on 29/08/16.
//  Copyright © 2016 Dx. All rights reserved.
//

import Foundation

class GameLevel {
    var id = 0
    var name = ""
    var minValue = 0
    var maxValue = 0
    
    func getFirebaseObject() -> [String: AnyObject] {
        
        let firebaseParameters = [
            "id": self.id,
            "name": self.name,
            "minValue": self.minValue,
            "maxValue":self.maxValue] as [String : Any]
        
        return firebaseParameters as [String : AnyObject]
    }
}
