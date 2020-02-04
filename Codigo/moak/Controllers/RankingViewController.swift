//
//  RankingViewController.swift
//  moak
//
//  Created by Dx on 12/09/16.
//  Copyright © 2016 Dx. All rights reserved.
//

import UIKit
import Firebase
import FBSDKCoreKit
import FBSDKShareKit

class RankingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource { //FBSDKAppInviteDialogDelegate {
	
    @IBOutlet weak var friendsList: UITableView!
    
    var friends = [Friend]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configureList()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.reloadFriends()
    }
    
    @IBAction func addClick(_ sender: AnyObject) {
        
    }
    
    @IBAction func inviteFriends(_ sender: Any) {
//        let inviteDialog:FBSDKAppInviteDialog = FBSDKAppInviteDialog()
//        if(inviteDialog.canShow()){
//            let appLinkUrl:NSURL = NSURL(string: "http://yourwebpage.com")!
//            let previewImageUrl:NSURL = NSURL(string: "http://yourwebpage.com/preview-image.png")!
//
//            let inviteContent:FBSDKAppInviteContent = FBSDKAppInviteContent()
//            inviteContent.appLinkURL = appLinkUrl as URL!
//            inviteContent.appInvitePreviewImageURL = previewImageUrl as URL!
//
//            inviteDialog.content = inviteContent
//            inviteDialog.delegate = self
//            inviteDialog.show()
//        }
    }
    
//    // MARK: - Invite Delegate
//    func appInviteDialog (_ appInviteDialog: FBSDKAppInviteDialog!, didCompleteWithResults results: [AnyHashable : Any]!) {
//        
//        if results != nil {
//        
//        	let resultObject = NSDictionary(dictionary: results)
//        
//        	if let didCancel = resultObject.value(forKey: "completionGesture") {
//            	if (didCancel as AnyObject).caseInsensitiveCompare("Cancel") == ComparisonResult.orderedSame
//            	{
//                	print("User Canceled invitation dialog")
//            	}
//        	}
//        } else {
//            print("No invite results")
//        }
//    }
//    
//    func appInviteDialog(_ appInviteDialog: FBSDKAppInviteDialog!, didFailWithError error: Error!) {
//        print("Error tool place in appInviteDialog \(error)")
//    }
//    
    
    // MARK: - TableView
    
    func configureList() {
        self.friendsList.delegate = self
        self.friendsList.dataSource = self
        self.friendsList.separatorStyle = .singleLine
        self.friendsList.tableFooterView = UIView()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.friends.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = friendsList.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! FriendCell
        
        let name = "\(self.friends[(indexPath as NSIndexPath).row].firstName) \(self.friends[(indexPath as NSIndexPath).row].lastName)"
        cell.name.text = name
        
        cell.points.text = "\(self.friends[(indexPath as NSIndexPath).row].points)"
        
        let storage = Storage.storage()
        var storageRef : StorageReference? = nil
        
        storageRef = storage.reference(forURL: "gs://moak-1291.appspot.com")
        
        let avatarsRef = storageRef!.child("avatars/\(self.friends[(indexPath as NSIndexPath).row].id).jpg")
        
        cell.picture.layer.cornerRadius = 30 //cell.pictureView.frame.size.width / 2
        cell.picture.clipsToBounds = true
        cell.picture.layer.borderWidth = 3.0
        cell.picture.layer.borderColor = UIColor(red: 0.952, green: 0.278, blue: 0.278, alpha: 0.65).cgColor
        
        // Download in memory with a maximum allowed size of 1MB (1 * 1024 * 1024 bytes)
        avatarsRef.getData(maxSize: 1 * 1024 * 1024) { (data, error) -> Void in
            if (error != nil) {
                // Uh-oh, an error occurred!
                print("error downloading avatar \(String(describing: error))")
            } else {
                let avatarImage: UIImage! = UIImage(data: data!)
                
                cell.picture.image = avatarImage
            }
        }
        
        return cell

    }
    
    func reloadFriends() {
        let firebase = FirebaseClient()
        firebase.getFriends(completion: {(friends: [Friend]?) in
            if friends != nil {
                self.friends = friends!
            } else {
                self.friends = [Friend]()
            }
            
            self.friendsList.reloadData()
        })
    }
}
