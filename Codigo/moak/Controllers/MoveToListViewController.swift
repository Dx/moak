//
//  MoveToListViewController.swift
//  moak
//
//  Created by Dx on 21/08/16.
//  Copyright © 2016 Dx. All rights reserved.
//

import UIKit
import Firebase
import CoreLocation

class MoveToListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate {

    var lists = [String: String]()
    
    var selectedRow: IndexPath? = nil
    
    var selectedProducts: [Product] = []
    
    var locationManager = CLLocationManager()
    
    var lastLocation : CLLocation? = nil
    
    var historyController : HistoryViewController!
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.delegate = self
        
        self.locationManager.distanceFilter  = 500
        self.locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        
        self.configureList()
        
        let firebase = FirebaseClient()
        
        let shoppingLists = firebase.getUserShoppingLists()
        
        _ = shoppingLists.observe(DataEventType.value, with: { (snapshot) in
            self.lists = [:]
            if let postDict = snapshot.value as? [String : String] {
                self.lists = postDict
                
                self.tableView.reloadData()
            }
        })
    }
    
    func configureList(){
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.separatorStyle = .none
        self.tableView.backgroundColor = UIColor.white
        self.tableView.rowHeight = 50
    }
    
    @IBAction func cancelClick(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Table View
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lists.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let index = lists.index(lists.startIndex, offsetBy: (indexPath as NSIndexPath).row)
        let key = lists.keys[index]
        cell.textLabel!.text = lists[key]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedRow = indexPath
        let firebase = FirebaseClient()
        
        if let indexPath = self.selectedRow {
            let index = lists.index(lists.startIndex, offsetBy: (indexPath as NSIndexPath).row)
            let key = lists.keys[index]
            
            for product in self.selectedProducts {
                if let location = self.lastLocation {
                    let newProduct = Product(productName: product.productName, productSKUName:product.productSKUName, productSKU: product.productSKU, quantity: product.quantity, listedDate: Date(), listedLatitude: location.coordinate.latitude, listedLongitude: location.coordinate.longitude, buyThreePayTwo: false, checked: false, order: 0, shoppingList: key)
                    newProduct.unitaryPrice = product.unitaryPrice
                    newProduct.totalPrice = product.totalPrice
                    firebase.addProductInShoppingList(shoppingList: key, product: newProduct)
                } else {
                    let newProduct = Product(productName: product.productName, productSKUName:product.productSKUName, productSKU: product.productSKU, quantity: product.quantity, listedDate: Date(), listedLatitude: 0, listedLongitude: 0, buyThreePayTwo: false, checked: false, order: 0, shoppingList: key)
                    newProduct.unitaryPrice = product.unitaryPrice
                    newProduct.totalPrice = product.totalPrice
                    firebase.addProductInShoppingList(shoppingList: key, product: newProduct)
                }
            }
        }
        
        self.historyController.selectedProducts = []
        self.historyController.tableView.reloadData()
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - CoreLocationManager
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("didChangeAuthorizationStatus")
        
        switch status {
        case .notDetermined:
            print(".NotDetermined")
            break
            
        case .authorizedAlways:
            print(".Authorized")
            self.locationManager.startUpdatingLocation()
            break
            
        case .denied:
            print(".Denied")
            break
            
        default:
            print("Unhandled authorization status")
            break
            
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.lastLocation = locations.last! as CLLocation
        if self.lastLocation != nil {
            print("didUpdateLocations:  \(self.lastLocation!.coordinate.latitude), \(self.lastLocation!.coordinate.longitude)")
        }
    }
}
