//
//  InterfaceController.swift
//  ApiAIDemoWatchOSSwift WatchKit Extension
//
//  Created by Dx on 21/10/15.
//  Copyright © 2015 Palmera. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity

class InterfaceController: WKInterfaceController, WCSessionDelegate {
    
    @IBOutlet var tableView: WKInterfaceTable!
    
    var shoppingLists = [String: String]()
    
    var session : WCSession!
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        if (WCSession.isSupported()) {
            session = WCSession.default()
            session.delegate = self
            session.activate()
            self.askForTable()
        } else {
            print ("Error en reloj: No se soporta WCSession")
        }
    }
    
    func askForTable() {
        
        let message = ["mensaje": "PasameLaBotella"]
        
        session.sendMessage(message, replyHandler: nil, errorHandler: {(error) -> Void in
                print("Error: \(error.localizedDescription)")
        })
    }
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        
        self.textRequest(rowIndex: rowIndex)
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let lists = message as? [String: String] {
            self.shoppingLists = lists
            
            self.reloadTable()
        }
    }
    
    private func textRequest(rowIndex: Int) {
        
        self.presentTextInputController(withSuggestions:nil, allowedInputMode: .plain) { (results) -> Void in
            
            guard let results = results as? [String] else {
                return
            }
            
            guard let text = results.first else {
                return
            }
            
            let arrayList = Array(self.shoppingLists.keys)
            let key = arrayList[rowIndex]
            
            let infoDictionary = ["message" : text, "list": key]
            
            self.session.sendMessage(infoDictionary, replyHandler: {(result: [String : Any]) -> Void in
                if (result["message"] as? String) != nil {
                    
                    self.pushController(withName: "finishController", context: text)
                } else {
                    self.pushController(withName: "finishController", context: nil)
                }
                
                WKInterfaceDevice.current().play(.success)
                
                },  errorHandler: {(error ) -> Void in
                    //self.labelMoak.setText("Error 3- \(error.localizedDescription)")
                    
                    WKInterfaceDevice.current().play(.failure)
            })
        }
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func reloadTable() {
        tableView.setNumberOfRows(shoppingLists.count, withRowType: "NameRowControllerIdentifier")
        
        for (index, name) in shoppingLists.enumerated() {
            if let row = tableView.rowController(at: index) as? NameRowController {
                row.nameLabel.setText(name.value)
            }
        }
    }
    
    // MARK: WCSession Delegate
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if error != nil {
            print("Error en reloj \(String(describing: error?.localizedDescription))")
        }
    }
    
//    public func sessionDidBecomeInactive(_ session: WCSession) {
//    }
//    
//    public func sessionDidDeactivate(_ session: WCSession){
//    }
}
