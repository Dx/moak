//
//  StoreViewController.swift
//  moak
//
//  Created by Dx on 14/10/16.
//  Copyright © 2016 moak. All rights reserved.
//

import UIKit
import GooglePlaces
import Firebase
import Foundation

class StoreViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var refreshButton: UIButton!
    
    let defaults = UserDefaults.standard
    
    var googlePlaceResults : [GooglePlaceResult] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initiateTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        refreshButton.isEnabled = true
        refreshButton.isHidden = false
        tableView.isHidden = true
        self.reloadStores()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func clickRefresh(_ sender: Any) {
        self.reloadStores()
    }
    
    // MARK: - TableView Delegate
    
    func initiateTableView() {
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.separatorStyle = .singleLine
        self.tableView.tableFooterView = UIView()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if self.googlePlaceResults.count > 0 {
            refreshButton.isEnabled = false
            refreshButton.isHidden = true
            tableView.isHidden = false
        }
        
        return self.googlePlaceResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! StoreTableViewCell
        
        cell.storeName.text = self.googlePlaceResults[(indexPath as NSIndexPath).row].name
        
        cell.storeAddress.text = self.googlePlaceResults[(indexPath as NSIndexPath).row].address
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let delete = UITableViewRowAction(style: .normal, title: "Borrar") { action, index in
            
            let place = self.googlePlaceResults[indexPath.row]
            
            self.googlePlaceResults.remove(at: indexPath.row)
            let firebase = FirebaseClient()
            firebase.deleteStore(storeId: place.id)
            
            // use the UITableView to animate the removal of this row
            self.tableView.beginUpdates()
            self.tableView.deleteRows(at: [indexPath], with: .fade)
            self.tableView.endUpdates()
        }
        
        delete.backgroundColor = UIColor(red: 0.95, green: 0.27, blue: 0.27, alpha: 0.65)

        return [delete]
    }
    
    // MARK: - Functions
    
    func reloadStores() {
        
        let gpClient = GooglePlacesClient()
        let latitude = self.defaults.double(forKey: "currentLatitude")
        let longitude = self.defaults.double(forKey: "currentLongitude")
        let currentLocation = CLLocation(latitude: latitude, longitude: longitude)
        
        if latitude == 0 {
            refreshButton.isEnabled = true
            refreshButton.isHidden = false
            tableView.isHidden = true
        } else {
        
        	gpClient.getCloserStores(currentLocation: currentLocation) { (result: [GooglePlaceResult]?, error: String?) in
            	if result != nil {
            		self.googlePlaceResults = result!
            	}
            	self.tableView.reloadData()
        	}
        }
    }
}
