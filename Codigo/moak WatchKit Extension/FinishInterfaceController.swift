//
//  FinishInterfaceController.swift
//  moak
//
//  Created by Dx on 25/09/16.
//  Copyright © 2016 Dx. All rights reserved.
//

import WatchKit
import Foundation


class FinishInterfaceController: WKInterfaceController {

    @IBOutlet var labelText: WKInterfaceLabel!
    
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
	
    @IBAction func addClick() {
        self.pop()
    }
}
