//
//  LoginViewController.swift
//  ApiAIDemoWatchOSSwift
//
//  Created by Dx on 19/03/16.
//  Copyright © 2016 moak. All rights reserved.
//

import FBSDKCoreKit
import FBSDKLoginKit
import Firebase

class LoginViewController: UIViewController, LoginButtonDelegate {
    
    @IBOutlet weak var labelName: UILabel!
    
    var logged = false
    var tabShowed = false
    
    let defaults = UserDefaults.standard
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        if (AccessToken.current != nil)
        {
            if !logged {
            	self.goToNextView()
            }
            logged = true
        }
        else
        {
            let loginView : FBLoginButton = FBLoginButton()
            self.view.addSubview(loginView)
            loginView.center = self.view.center
            loginView.permissions = ["public_profile", "email"]
            loginView.delegate = self
        }
    }    
    
    @IBAction func showNext(_ sender: AnyObject) {
        if logged {
            self.performSegue(withIdentifier: "showMenuView", sender: self)
        }
    }
    
    // MARK: - FBSDKLoginButtonDelegate delegate
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        print("User Logged In")
        
        if ((error) != nil)
        {
            print(error!)
        } else if result!.isCancelled {
            // Handle cancellations
        } else {
            
            let credential = FacebookAuthProvider.credential(withAccessToken: AccessToken.current!.tokenString)
            
            Auth.auth().signIn(with: credential) { (user, error) in
                if error != nil && user != nil {
                    self.defaults.set(user?.user.uid, forKey: "userId")
                    self.logged = true
                    self.goToNextView()
                } else {
                    print("Error en login \(error.debugDescription)")
                }
            }
            
            if result!.grantedPermissions.contains("email") {
                self.logged = true
                self.goToNextView()
            }
        }
    }
    
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        logged = false
        print("User Logged Out")
    }
    
    func completeUserData(_ completion:@escaping (Bool) -> ())
    {
        let graphRequest : GraphRequest = GraphRequest(graphPath: "me", parameters: ["fields": "id, name, first_name, last_name, email, birthday"])
        graphRequest.start(completionHandler: { (connection, result, error) -> Void in
            
            if ((error) != nil)
            {
                // Process error
                print("Error: \(String(describing: error))")
            }
            else
            {
                print("fetched user: \(String(describing: result))")
                
                if let user = result as? [String: AnyObject] {
                
                    let firebaseClient = FirebaseClient()
                    
                    if let userName : NSString = user["name"] as? NSString {
                        print("User Name is: \(userName)")
                        self.defaults.set(userName, forKey: "userName")
                    }
                    if let userEmail : NSString = user["email"] as? NSString {
                        print("User Email is: \(userEmail)")
                        self.defaults.set(userEmail, forKey: "userEmail")
                    }
                    if let userFirstName : NSString = user["first_name"] as? NSString {
                        print("User First Name is: \(userFirstName)")
                        self.defaults.set(userFirstName, forKey: "userFirstName")
                    }
                    
                    DispatchQueue.main.async {
                        if let firstName = self.defaults.object(forKey: "userFirstName") as? String {
                            self.labelName.text = "Welcome \(firstName)"
                        }
                    }
                    
                    if let userLastName : NSString = user["last_name"] as? NSString {
                        print("User Last name is: \(userLastName)")
                        self.defaults.set(userLastName, forKey: "userLastName")
                    }
                    if let userGender : NSString = user["gender"] as? NSString {
                        print("User Gender is: \(userGender)")
                        self.defaults.set(userGender, forKey: "userGender")
                    }
                    if let userBirthday : NSString = user["birthday"] as? NSString {
                        print("User Birthday is: \(userBirthday)")
                        self.defaults.set(userBirthday, forKey: "userBirthday")
                    }
                    if let userLocation : NSString = user["location"] as? NSString {
                        print("User Location is: \(userLocation)")
                        self.defaults.set(userLocation, forKey: "userLocation")
                    }
                    
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
                    
                    var birthday: Date? = nil
                    if self.defaults.string(forKey: "userBirthday") != nil {
                        if let userbirthday = formatter.date(from: self.defaults.string(forKey: "userBirthday")! as String) {
                            birthday = userbirthday
                        }
                    }
                    
                    firebaseClient.getUser({(user: User?) in
                        if user == nil {
                            let newUser = User(id: self.defaults.string(forKey: "userId")!, name: self.defaults.string(forKey: "userName"), userName: "", email: self.defaults.string(forKey: "userEmail"), firstName: self.defaults.string(forKey: "userFirstName"), lastName: self.defaults.string(forKey: "userLastName"), gender: self.defaults.string(forKey: "userGender"), birthday: birthday, location: self.defaults.string(forKey: "userLocation"), level: 0, points: 0, lists: [String: String](), buyedLists: [String: String]())
                            firebaseClient.addUser(user: newUser)
                        } else {
                            if user!.userName == "" {
                                completion(false)
                                return
                            }
                        }
                        
                        completion(true)
                    })
                }
            }
        })
    }
    
    func goToNextView() {
        let firebase = FirebaseClient()
        firebase.getUserId( { (userId: String) in
                print("Usuario!:\(userId)")
            self.defaults.set(userId, forKey: "userId")
            self.completeUserData({(result: Bool) in
                if result {
                    
                    self.defaults.set("BarCode", forKey: "CaptureMode")
                    let cero: Double = 0
                    self.defaults.set(cero, forKey: "currentLatitude")
                    self.defaults.set(cero, forKey: "currentLongitude")
                    
                    if !self.tabShowed {
                		self.performSegue(withIdentifier: "showMenuView", sender: self)
                    	self.tabShowed = true
                    }
                } else {
                    self.performSegue(withIdentifier: "showMenuView", sender: self)
                }
            })
        })
    }    
}
