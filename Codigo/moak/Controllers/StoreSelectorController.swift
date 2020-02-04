//
//  StoreSelectorController.swift
//  moak
//
//  Created by Dx on 18/11/16.
//  Copyright © 2016 moak. All rights reserved.
//

import UIKit
import CoreLocation
import GooglePlaces
import GooglePlacePicker

protocol StoreSelectorDelegate {
    func storeSelected(store: GooglePlaceResult?)
}

class StoreSelectorController: UIViewController, UITableViewDelegate, UITableViewDataSource, GMSPlacePickerViewControllerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	
    var googlePlaceResults : [GooglePlaceResult] = []
    var delegate: StoreSelectorDelegate?
    var lastLocation : CLLocation? = nil
    var placeShopping : String? = nil
    
    var currentGooglePlace : GooglePlaceResult?
    
    // MARK: - View methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initiateTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
		activityIndicator.isHidden = false
		tableView.isHidden = true
        self.reloadStores()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func addStoreClick(_ sender: Any) {
        self.selectFromGooglePicker()
    }
    
    // MARK: - Google Picker
    func selectFromGooglePicker() {
        var center : CLLocationCoordinate2D? = nil
        if let currentLocation = self.lastLocation {
            center = CLLocationCoordinate2DMake(currentLocation.coordinate.latitude, currentLocation.coordinate.longitude)
        }
        
        if let center = center {
            let northEast = CLLocationCoordinate2DMake(center.latitude + 0.001, center.longitude + 0.001)
            let southWest = CLLocationCoordinate2DMake(center.latitude - 0.001, center.longitude - 0.001)
            let viewport = GMSCoordinateBounds(coordinate: northEast, coordinate: southWest)
            let config = GMSPlacePickerConfig(viewport: viewport)
            let placePicker = GMSPlacePickerViewController(config: config)
            
            placePicker.delegate = self
        } else {
            print("Google place picker failed")
        }
    }
    
    // MARK: - GMSPlacePickerViewControllerDelegate
    func placePicker(_ viewController: GMSPlacePickerViewController, didPick place: GMSPlace) {
        let googlePlace = GooglePlaceResult(id: place.placeID!, name: place.name!, address: place.formattedAddress!, lat: place.coordinate.latitude, lng: place.coordinate.longitude)
        
        self.currentGooglePlace = googlePlace
        
        let firebase = FirebaseClient()
        
        firebase.setStoreInUserFavs(store: googlePlace)
        
        self.delegate!.storeSelected(store: googlePlace)
        
        _ = self.navigationController?.popViewController(animated: true)
        
        print("Place name \(place.name)")
        print("Place address \(place.formattedAddress ?? "")")
    }
    
    func placePicker(_ viewController: GMSPlacePickerViewController, didFailWithError error: Error) {
        // In your own app you should handle this better, but for the demo we are just going to log
        // a message.
        NSLog("An error occurred while picking a place: \(error)")
    }
    
    func placePickerDidCancel(_ viewController: GMSPlacePickerViewController) {
        NSLog("The place picker was canceled by the user")
        
        // Dismiss the place picker.
        viewController.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - TableView Delegate
    
    func initiateTableView() {
        self.edgesForExtendedLayout = UIRectEdge.init(rawValue: 0)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.separatorStyle = .singleLine
        self.tableView.tableFooterView = UIView()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print ("tiendas: \(self.googlePlaceResults.count)")
        return self.googlePlaceResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let index = (indexPath as NSIndexPath).row
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! StoreSelectorViewCell
        
        cell.storeName.text = self.googlePlaceResults[index].name
        
        if placeShopping != nil && self.googlePlaceResults[index].id == self.placeShopping {
        	cell.storeName.textColor = UIColor.red
        } else {
            cell.storeName.textColor = UIColor.black
        }
        
        cell.storeAddress.text = self.googlePlaceResults[index].address
        
        if self.googlePlaceResults[index].distance >= 0 {
        	cell.storeDistance.text = "\(self.googlePlaceResults[index].distance) m"
        } else {
            cell.storeDistance.text = ""
        }
        
        cell.storeDistance.isHidden = self.lastLocation == nil
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if delegate != nil {
            
            let index = (indexPath as NSIndexPath).row
            
            if self.googlePlaceResults[index].id == "000" {
                delegate!.storeSelected(store:  nil)
            } else {
        		delegate!.storeSelected(store:
                    self.googlePlaceResults[index])
            }
        }
        
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .normal, title: "Borrar") { action, index in
            
            let place = self.googlePlaceResults[indexPath.row]
            
            self.googlePlaceResults.remove(at: indexPath.row)
            let firebase = FirebaseClient()
            firebase.deleteStore(storeId: place.id)
            
            self.reloadStores()
        }
        
        delete.backgroundColor = UIColor(red: 0.95, green: 0.27, blue: 0.27, alpha: 0.65)
        
        return [delete]
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // MARK: - Functions
    
    func reloadStores() {
		
		let firebase = FirebaseClient()
		firebase.getUserStores(location: self.lastLocation!) { (resultFirebase: [GooglePlaceResult]) in
			
			self.googlePlaceResults = resultFirebase
			
			let client = GooglePlacesClient()
			client.getCloserStores(currentLocation: self.lastLocation!) { (result: [GooglePlaceResult]?, error: String?) in
				
				if result != nil {
					self.googlePlaceResults.append(contentsOf: result!)
					DispatchQueue.main.async {
						self.tableView.reloadData()
						self.tableView.isHidden = false
						self.activityIndicator.isHidden = true
					}
				}
			}
		}
		
		
    }
}
