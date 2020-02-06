//
//  AddContactViewController.swift
//  moak
//
//  Created by Dx on 09/08/16.
//  Copyright © 2016 Dx. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

class AddContactViewController: UIViewController, UITextFieldDelegate {
	
    @IBOutlet weak var mailText: UITextField!
    @IBOutlet weak var nombreLabel: UILabel!
    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var pictureView: UIImageView!
    
    var userFound : UserToShareWith?
    var shoppingListId : String = ""
    var shoppingListName: String = ""
    
    let storage = Storage.storage()
    var storageRef : StorageReference? = nil
    
    override func viewDidLoad() {
        mailText.becomeFirstResponder()
        
        self.okButton.isEnabled = false
        
        self.pictureView.layer.cornerRadius = 30 //self.pictureView.frame.size.width / 2
        self.pictureView.clipsToBounds = true
        self.pictureView.layer.borderWidth = 3.0
        self.pictureView.layer.borderColor = UIColor(red: 0, green: 0.611, blue: 0.655, alpha: 1.0).cgColor
        self.pictureView.isHidden = true
    }
    
    @IBAction func cancelClick(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func okClick(_ sender: AnyObject) {
        if userFound != nil {
            let firebase = FirebaseClient()
            firebase.shareShoppingList(shoppingListId: shoppingListId, name: shoppingListName, idUser: userFound!.id)
            firebase.addFriend(friendId: userFound!.id)
            self.dismiss(animated: true, completion: nil)
        } else {
            print("not user found")
        }
    }
    
    @IBAction func searchClick(_ sender: AnyObject) {
        
        let userSearch = mailText.text!
        
        let firebase = FirebaseClient()
        firebase.getUsersWithEmail(email: userSearch) { (user: UserToShareWith?) in
            if user != nil {
                self.nombreLabel.text = "\(user!.firstName) \(user!.lastName)"
                self.nombreLabel.isHidden = false
                self.userFound = user
                self.okButton.isEnabled = true
                
                self.storageRef = self.storage.reference(forURL: "gs://moak-1291.appspot.com")
                let avatarsRef = self.storageRef!.child("avatars/\(user!.id).jpg")
                avatarsRef.getData(maxSize: 1 * 1024 * 1024) { (data, error) -> Void in
                    if (error != nil) {
                        // Uh-oh, an error occurred!
                        print("error downloading avatar \(String(describing: error))")
                    } else {
                        // Data for "images/island.jpg" is returned
                        let avatarImage: UIImage! = UIImage(data: data!)
                        
                        DispatchQueue.main.async {
                            self.pictureView.image = avatarImage
                            self.pictureView.isHidden = false
                        }
                    }
                }
            } else {
                firebase.getUserByUserName(userName: userSearch) { (user: UserToShareWith? ) in
                    if user != nil {
                        self.nombreLabel.text = "\(user!.firstName) \(user!.lastName)"
                        self.nombreLabel.isHidden = false
                        self.pictureView.isHidden = false
                        self.userFound = user
                        self.okButton.isEnabled = true
                        
                        self.storageRef = self.storage.reference(forURL: "gs://moak-1291.appspot.com")
                        let avatarsRef = self.storageRef!.child("avatars/\(user!.id).jpg")
                        avatarsRef.getData(maxSize: 1 * 1024 * 1024) { (data, error) -> Void in
                            if (error != nil) {
                                // Uh-oh, an error occurred!
                                print("error downloading avatar \(String(describing: error))")
                            } else {
                                // Data for "images/island.jpg" is returned
                                let avatarImage: UIImage! = UIImage(data: data!)
                                
                                self.pictureView.image = avatarImage
                                self.pictureView.isHidden = false
                            }
                        }
                    }
                }
            }
        }
    }
}
