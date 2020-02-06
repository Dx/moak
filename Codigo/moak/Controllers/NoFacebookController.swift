//
//  NoFacebookController.swift
//  ApiAIDemoWatchOSSwift
//
//  Created by Dx on 06/06/16.
//  Copyright © 2016 moak. All rights reserved.
//

import UIKit

class NoFacebookController: UIViewController {
    
    let defaults = UserDefaults.standard
    
    
    @IBOutlet weak var userNameText: UITextField!
    
    @IBOutlet weak var firstNameText: UITextField!
    
    @IBOutlet weak var lastNameText: UITextField!

    @IBOutlet weak var birthdayText: UITextField!
    
    @IBOutlet weak var emailText: UITextField!
    
    @IBOutlet weak var genderText: UITextField!
    
    @IBOutlet weak var cityText: UITextField!
    
    @IBAction func okClick(_ sender: AnyObject) {
        
        print("User Name is: \(String(describing: userNameText.text))")
        self.defaults.set(userNameText.text, forKey: defaultKeys.userName)
        
        print("User Email is: \(String(describing: emailText.text))")
        self.defaults.set(emailText.text, forKey: defaultKeys.userEmail)
        
        print("User First Name is: \(String(describing: firstNameText.text))")
        self.defaults.set(firstNameText.text, forKey: defaultKeys.userFirstName)
        
        print("User Last name is: \(String(describing: lastNameText.text))")
        self.defaults.set(lastNameText.text, forKey: defaultKeys.userLastName)
        
        print("User Gender is: \(String(describing: genderText.text))")
            self.defaults.set(genderText.text, forKey: defaultKeys.userGender)
        
        print("User Birthday is: \(String(describing: birthdayText.text))")
        self.defaults.set(birthdayText.text, forKey: defaultKeys.userBirthday)
        
        print("User Location is: \(String(describing: cityText.text))")
        self.defaults.set(cityText.text, forKey: defaultKeys.userLocation)
        
        self.showLanguageView()
    }
    
    func showLanguageView() {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "showTabView", sender: self)
        }
    }
}
