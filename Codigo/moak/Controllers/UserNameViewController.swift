//
//  UserNameViewController.swift
//  moak
//
//  Created by Dx on 23/08/16.
//  Copyright © 2016 Dx. All rights reserved.
//

import UIKit

class UserNameViewController: UIViewController {

    @IBOutlet weak var userNameText: UITextField!
    
    @IBOutlet weak var foundLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        userNameText.becomeFirstResponder()
    }
    
    @IBAction func okClick(_ sender: AnyObject) {
        let firebase = FirebaseClient()
        let userName = userNameText.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        firebase.checkUserName(userName: userName, completion: {(found: Bool) in
            
            if found {
                self.foundLabel.isHidden = false
            } else {
                print("username created \(userName)")
                
                firebase.setUserName(userName: userName)
                
                self.performSegue(withIdentifier: "showTabView", sender: self)
            }
        })
    }
}
