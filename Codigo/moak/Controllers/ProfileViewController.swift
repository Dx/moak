//
//  ProfileViewController.swift
//  moak
//
//  Created by Dx on 25/08/16.
//  Copyright © 2016 Dx. All rights reserved.
//

import UIKit
import Firebase

class ProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var pictureView: UIImageView!
    @IBOutlet weak var nickNameLabel: UILabel!
    @IBOutlet weak var historyTableView: UITableView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var levelLabel: UILabel!
    @IBOutlet weak var pointsLabel: UILabel!
    @IBOutlet weak var userNameLabel: UILabel!
    
    let defaults = UserDefaults.standard
    
    var points: [HistoryPoint] = []
    var dayPoints: [DayPoints] = []
    
    let storage = Storage.storage()
    var storageRef : StorageReference? = nil
    
    override func viewDidLoad() {
        
        self.historyTableView.delegate = self
        self.historyTableView.dataSource = self
        self.historyTableView.tableFooterView = UIView()
        
        self.pictureView.layer.cornerRadius = 50
        self.pictureView.clipsToBounds = true
        self.pictureView.layer.borderWidth = 4.0
        self.pictureView.layer.borderColor = UIColor(red: 0.952, green: 0.278, blue: 0.278, alpha: 0.65).cgColor
        
        storageRef = storage.reference(forURL: "gs://moak-1291.appspot.com")
        
        let userId = self.defaults.string(forKey: "userId")!
        let avatarsRef = storageRef!.child("avatars/\(userId).jpg")
        
        // Download in memory with a maximum allowed size of 1MB (1 * 1024 * 1024 bytes)
        avatarsRef.getData(maxSize: 1 * 1024 * 1024) { (data, error) -> Void in
            if (error != nil) {
                // Uh-oh, an error occurred!
                print("error downloading avatar \(String(describing: error))")
            } else {
                let avatarImage: UIImage! = UIImage(data: data!)
                
                self.pictureView.image = avatarImage
            }
        }
        
        let firebase = FirebaseClient()
		
        firebase.getUser({(user: User?) in
            if user != nil {
                self.nameLabel.text = "\(user!.firstName) \(user!.lastName)"
                self.userNameLabel.text = user!.userName
                
                self.pointsLabel.text = "\(user!.points)"
                
                switch user!.level {
                case 0:
                	self.levelLabel.text = "Nivel 0. Próximo nivel a los 200 puntos"
                case 1:
                    self.levelLabel.text = "Nivel 1. Próximo nivel a los 450 puntos"
                case 2:
                    self.levelLabel.text = "Nivel 2. Próximo nivel a los 1000 puntos"
                case 3:
                    self.levelLabel.text = "Nivel 3. Próximo nivel a los 1500 puntos"
                case 4:
                    self.levelLabel.text = "Nivel 4. Próximo nivel a los 2000 puntos"
                case 5:
                    self.levelLabel.text = "Nivel 5. Próximo nivel a los 10000 puntos"
                default:
                    self.levelLabel.text = "No sé tu nivel :S"
                }
            }
        })
        
        let points = firebase.getPointHistory()
        
        _ = points.observe(DataEventType.value, with: { (snapshot) in
            var newItems: [HistoryPoint] = []
            var newDayPoints: [DayPoints] = []
            
            if let postDict = snapshot.value as? [String : AnyObject] {
                
                for item in postDict.values {
                    
                    let itemType = HistoryPoint(parameters: item as! [String: AnyObject])
                    newItems.append(itemType)
                }
                
                let calendar = Calendar.current
                
                for item in newItems {
                    let components = (calendar as NSCalendar).components([.day , .month , .year], from: item.date! as Date)
                    
                    let year =  components.year!
                    let month = components.month!
                    let day = components.day!
                    let stringDate = "\(day) \(month) \(year)"
                    
                    if newDayPoints.contains( where: { $0.dateString == stringDate } ) {
                        newDayPoints[newDayPoints.index( where: { $0.dateString == stringDate } )!].totalPoints += item.points
                    } else {
                        let point = DayPoints()
                        point.dateString = stringDate
                        point.totalPoints = item.points
                        newDayPoints.append(point)
                    }
                }
                
                self.dayPoints = newDayPoints.sorted( by: { $0.dateString > $1.dateString })
                
                self.historyTableView.reloadData()
            }
        })

    }
    
    @IBAction func editClick(_ sender: AnyObject) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.camera;
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        
        let newImage = self.resizeImage(image, newWidth: 200)
        
        self.pictureView.image = newImage
        
        if storageRef != nil {
            
            let imageData: Data = UIImagePNGRepresentation(newImage)!
            let userId = self.defaults.string(forKey: "userId")!
            
            let avatarsRef = storageRef!.child("avatars/\(userId).jpg")
            
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            _ = avatarsRef.putData(imageData, metadata: metadata) { metadata, error in
                if (error != nil) {
                    // Uh-oh, an error occurred!
                } else {
                    // Metadata contains file metadata such as size, content-type, and download URL.
                    let downloadURL = metadata!.downloadURL
                    print (downloadURL)
                }
            }
        }
        
        self.dismiss(animated: true, completion: nil);
    }
    
    func resizeImage(_ image: UIImage, newWidth: CGFloat) -> UIImage {
        
        let width = image.size.width
        let height = image.size.height
        var middleImage : UIImage? = nil
        
        if width < height { // portrait
            let newsize = CGSize(width: width, height: width)
            UIGraphicsBeginImageContextWithOptions(newsize, false, 1.0)
            image.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
            middleImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        } else {
            let newsize = CGSize(width: height, height: height)
            UIGraphicsBeginImageContextWithOptions(newsize, false, 1.0)
            image.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
            middleImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        }
        
        if middleImage != nil {
        	let scale = newWidth / middleImage!.size.width
        	let newHeight = middleImage!.size.height * scale
        	UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        	middleImage!.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        	let newImage = UIGraphicsGetImageFromCurrentImageContext()
        	UIGraphicsEndImageContext()
        
        	return newImage!
        } else {
            return UIImage()
        }
    }
    
    // MARK: - TableViewDelegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dayPoints.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) 
        cell.selectionStyle = .none
        
//        let dateFormatter = NSDateFormatter()
//        dateFormatter.dateFormat = "MMM dd"
//        
//        let date = dateFormatter.stringFromDate(points[indexPath.row].date!)
        
        cell.textLabel?.text =  "\(self.dayPoints[(indexPath as NSIndexPath).row].dateString)"
        cell.detailTextLabel?.text = "\(self.dayPoints[(indexPath as NSIndexPath).row].totalPoints)"
        
        return cell
    }
}
