//
//  ShoppingListViewController.swift
//  ApiAIDemoWatchOSSwift
//
//  Created by Dx on 24/07/16.
//  Copyright © 2016 moak. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import Firebase

class ShoppingListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, ShareUserCellDelegate {
    
    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var shoppingListText: UITextField!
    @IBOutlet weak var usersToShareTable: UITableView!
    @IBOutlet weak var addButton: UIButton!
    
    let defaults = UserDefaults.standard
    
    var shoppingListIdSelected = ""
    var usersToShare = [String]()
    var friends = [Friend]()
    
    // MARK: - View
    override func viewDidLoad() {
        self.usersToShareTable.delegate = self
        self.usersToShareTable.dataSource = self
        self.shoppingListText.delegate = self
        self.usersToShareTable.tableFooterView = UIView()
        
        self.shoppingListText.autocapitalizationType = .sentences
        
        self.addDoneButtonOnKeyboard()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        self.reloadShoppingList()
        
        self.shoppingListText.becomeFirstResponder()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showAddContact" {
            let controller = segue.destination as! AddContactViewController
            controller.shoppingListId = shoppingListIdSelected
            controller.shoppingListName = self.shoppingListText.text!
        }
    }
    
    // MARK: - Events
    
    @IBAction func okClicked(_ sender: AnyObject) {
		self.save()
    }
    
    @IBAction func backClicked(_ sender: AnyObject) {
        self.navigationController!.popToViewController(self.navigationController!.viewControllers[0], animated: true)
    }
    
    @IBAction func addSharedContact(_ sender: AnyObject) {
        performSegue(withIdentifier: "showAddContact", sender: self)
    }
    
    // MARK: TextField
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return true
    }
    
    //MARK: Tableview
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.friends.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = usersToShareTable.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ShareUserCell
        
        cell.delegate = self
        
        cell.idUser = self.friends[(indexPath as NSIndexPath).row].id
        
        cell.shareSwitch.isOn = self.usersToShare.contains(self.friends[(indexPath as NSIndexPath).row].id )
        
        let name = "\(self.friends[(indexPath as NSIndexPath).row].firstName) \(self.friends[(indexPath as NSIndexPath).row].lastName)"
        cell.userNameLabel.text = name
        
        let storage = Storage.storage()
        var storageRef : StorageReference? = nil
        
        storageRef = storage.reference(forURL: "gs://moak-1291.appspot.com")
        
        let isRef = storageRef!.child("avatars/\(self.friends[(indexPath as NSIndexPath).row].id).jpg")
        
        cell.pictureView.layer.cornerRadius = 30 //cell.pictureView.frame.size.width / 2
        cell.pictureView.clipsToBounds = true
        cell.pictureView.layer.borderWidth = 3.0
        cell.pictureView.layer.borderColor = UIColor(red: 0.952, green: 0.278, blue: 0.278, alpha: 0.65).cgColor
        
        // Download in memory with a maximum allowed size of 1MB (1 * 1024 * 1024 bytes)
        isRef.getData(maxSize: 1 * 1024 * 1024) { (data, error) -> Void in
            if (error != nil) {
                // Uh-oh, an error occurred!
                print("error downloading avatar \(String(describing: error))")
            } else {
                let avatarImage: UIImage! = UIImage(data: data!)
                
                cell.pictureView.image = avatarImage
            }
        }
        
        return cell
    }
    
	@objc func save() {
        let firebase = FirebaseClient()
        let nameList = self.shoppingListText!.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        if nameList == "" {
            self.showAlert(error: "Se necesita un nombre de lista", title: "Ups")
            self.shoppingListText.becomeFirstResponder()
            return
        }
        
        if shoppingListIdSelected != "" {            
            
            firebase.updateNameShoppingList(id: shoppingListIdSelected, name: nameList)
            
        } else {
            
            let list = ShoppingList(id: "", name: nameList, owner: "")
            
            self.shoppingListIdSelected = firebase.addUserShoppingList(shoppingList: list)
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
	@objc func deleteList() {
        let firebase = FirebaseClient()
        firebase.deleteShoppingList(self.shoppingListIdSelected)
        self.dismiss(animated: true, completion: nil)
    }
    
	@objc func cancel() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func showAlert(error:String, title: String) {
        let myAlert = UIAlertController(title: title, message: error, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
            // ...
        }
        myAlert.addAction(OKAction)
        self.present(myAlert, animated: true, completion: nil)
    }
    
    func changeSharing(userId: String, share: Bool) {
        
        let nameList = self.shoppingListText!.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        if nameList != "" {
        
        	let firebase = FirebaseClient()
        
        	if shoppingListIdSelected == "" {
            	let list = ShoppingList(id: "", name: nameList, owner: "")
            
            	self.shoppingListIdSelected = firebase.addUserShoppingList(shoppingList: list)
        	}
        
        	if share {
            	firebase.shareShoppingList(shoppingListId: shoppingListIdSelected, name: self.shoppingListText.text!, idUser: userId)
        	} else {
            	firebase.deleteUserToShareInList(userId, shoppingListId: shoppingListIdSelected)
        	}
            
            reloadShoppingList()
        }
    }
    
    // MARK: Functions
    
    func addDoneButtonOnKeyboard() {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: 50))
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        
        let done: UIBarButtonItem = UIBarButtonItem(title: "Guardar", style: UIBarButtonItemStyle.done, target: self, action: #selector(ShoppingListViewController.save))
        
        done.tintColor = .red
        
//        let doneButton = UIButton()
//        doneButton.layer.cornerRadius = 12
//        doneButton.layer.backgroundColor = UIColor.red.cgColor
//        doneButton.addTarget(self, action: #selector(ShoppingListViewController.save), for: UIControlEvents.touchUpInside)
//        
//        let done2: UIBarButtonItem = UIBarButtonItem.init(customView: doneButton)
        
        let delete: UIBarButtonItem = UIBarButtonItem(title: "Borrar", style: UIBarButtonItemStyle.done, target: self, action: #selector(ShoppingListViewController.deleteList))
        
        delete.tintColor = .red
        
        let cancel: UIBarButtonItem = UIBarButtonItem(title: "Cancelar", style: UIBarButtonItemStyle.done, target: self, action: #selector(ShoppingListViewController.cancel))
        
        cancel.tintColor = .red
        
        var items: [UIBarButtonItem]? = [UIBarButtonItem]()
        items?.append(done)
        items?.append(flexSpace)
        items?.append(delete)
        items?.append(flexSpace)
        items?.append(cancel)
        
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        shoppingListText.inputAccessoryView=doneToolbar
    }
    
    func reloadShoppingList() {
        let firebase = FirebaseClient()
        firebase.getFriends(completion: {(friends: [Friend]?) in
            if friends != nil {
                self.friends = friends!
                self.usersToShareTable.reloadData()
            }
        })
            
        if self.shoppingListIdSelected != "" {
        	firebase.getShoppingList(shoppingListId: self.shoppingListIdSelected, completion:{(shoppingList: ShoppingList?) in
                
            	self.usersToShare = [String]()
            	let userId = self.defaults.string(forKey: "userId")!
            	if let list = shoppingList {
                    
                	if list.owner != userId {
                    	DispatchQueue.main.async {
                        	self.addButton.isHidden = true
                        	self.usersToShareTable.isUserInteractionEnabled = false
                    	}
                	}
                    
                	self.shoppingListText.text = list.name
                	if list.sharedWith.count > 0 {
                    	for user in list.sharedWith.keys {
                        	self.usersToShare.append(user)
                    	}
                	}
            	}
        	})
        }
    }
}

