//
//  MenuController.swift
//  moak
//
//  Created by Dx on 20/03/17.
//  Copyright © 2017 moak. All rights reserved.
//

import UIKit
import Firebase

class MenuController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var menuTable: UITableView!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var pointsLabel: UILabel!
    
    let defaults = UserDefaults.standard
    let storage = Storage.storage()
    var storageRef : StorageReference? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableList()
        menuTable.delegate = self
        menuTable.dataSource = self
        menuTable.reloadData()
        
        self.loadProfileImage()
        
        self.loadUserData()
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadProfileImage() {
        self.profileImage.layer.cornerRadius = 55
        self.profileImage.clipsToBounds = true
        self.profileImage.layer.borderWidth = 2.0
        self.profileImage.layer.borderColor = UIColor(red: 0.952, green: 0.278, blue: 0.278, alpha: 0.65).cgColor
        
        storageRef = storage.reference(forURL: "gs://moak-1291.appspot.com")
        
        let userId = self.defaults.string(forKey: "userId")!
        let avatarsRef = storageRef!.child("avatars/\(userId).jpg")
        
        // Download in memory with a maximum allowed size of 1MB (1 * 1024 * 1024 bytes)
        avatarsRef.getData(maxSize: 1 * 1024 * 1024) { (data, error) -> Void in
            if (error != nil) {
                // Uh-oh, an error occurred!
                print("error downloading avatar \(error!.localizedDescription)")
            } else {
                let avatarImage: UIImage! = UIImage(data: data!)
                
                self.profileImage.image = avatarImage
            }
        }
    }
    
    func loadUserData() {
        let firebase = FirebaseClient()
        
        firebase.getUser({(user: User?) in
            if user != nil {
                self.nameLabel.text = user!.userName
                
                self.pointsLabel.text = "\(user!.points)"
            }
        })

    }
    
    func configureTableList() {
        self.menuTable.separatorStyle = .singleLine
        self.menuTable.tableFooterView = UIView()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) 
        
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "Mi lista"
        case 1:
            cell.textLabel?.text = "Mis tickets"
        default:
            cell.textLabel?.text = "Mis comentarios"
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch indexPath.row {
        case 0:
            performSegue(withIdentifier: "listSegue", sender: self)
        case 1:
            performSegue(withIdentifier: "ticketsSegue", sender: self)
        default:
            print("opción inválida")
        }
    }
}
