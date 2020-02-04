//
//  AddProductNavigation.swift
//  moak
//
//  Created by Dx on 13/11/16.
//  Copyright © 2016 moak. All rights reserved.
//

import UIKit
import CoreLocation

class AddProductNavigation: UINavigationController, CLLocationManagerDelegate {
    
    var modeList: String = "l"
    var listId: String?
    var currentGooglePlace: GooglePlaceResult?
    
    var sku: String?
    var productName: String?
    var skuName: String?
    
    var completeProduct: Product?
    
    var inputText: UITextField?
    
    var locationManager = CLLocationManager()
    
    var lastLocation : CLLocation? = nil
    
    var listsController: ListsViewController?
    
    // MARK: - View Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Adding product methods
    func barcodeFound() {
        
        let searchClient = SearchClient()
        searchClient.retrieveDescription(sku!, completion: {(result: String?, error: String?) in
            if error == nil {
                self.addNewProduct(productName: result!, skuName: result!, sku: self.sku!)

            } else {
                print("No encontró sku \(self.sku!) en search: \(error!) intentará en firebase")
                let firebase = FirebaseClient()
                
                firebase.getProductSKU(sku: self.sku!, completion: {(name: String) in
                    if name != "" {
                        print("Sí encontró sku \(self.sku!) en firebase")
                        self.addNewProduct(productName: name, skuName: name, sku: self.sku!)
                    } else {
                        self.showAlertForProduct({(productName: String?) in
                            if let name = productName {
                                self.addNewProduct(productName: name, sku: self.sku!)
                            }
                        })
                    }
                })
            }
        }
        )
    }
    
    func showAlertForProduct(_ completion:@escaping (String?) -> ()) {
        let alertController = UIAlertController(title: "No se encontró el código de barras", message: "Captura el nombre del producto", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) {
            UIAlertAction in
            
            if self.inputText != nil {
                completion(self.inputText!.text)
            }
            
            NSLog("OK Undo Pressed")
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) {
            UIAlertAction in
            NSLog("Cancel Undo Pressed")
        }
        
        // Add the actions
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        
        // Add the textField
        alertController.addTextField(configurationHandler: configurationTextField)
        
        // Present the controller
        self.present(alertController, animated: true, completion: nil)
        
    }
    
    func configurationTextField(textField: UITextField!)
    {
        if (textField) != nil {
            self.inputText = textField!        //Save reference to the UITextField
            self.inputText?.text = ""
        }
    }

    func addNewProduct(productName: String) {
        self.addNewProduct(productName: productName, skuName: "", sku: "")
    }
    
    func addNewProduct(productName: String, sku: String) {
        self.addNewProduct(productName: productName, skuName: "", sku: sku)
    }
    
    func addNewProduct(productName: String, skuName: String, sku: String) {
        let product : Product?
        let firebase = FirebaseClient()
        if let location = self.lastLocation {
            
            product = Product(productName: productName, productSKUName: skuName, productSKU: sku, lat: location.coordinate.latitude, lng: location.coordinate.longitude, order: 0, shoppingList: self.listId!)
            firebase.addProductInShoppingList(shoppingList: self.listId!, product: product!)
        } else {
            product = Product(productName: productName, productSKUName: skuName, productSKU: sku, lat: 0, lng: 0, order: 0, shoppingList: self.listId!)
            firebase.addProductInShoppingList(shoppingList: self.listId!, product: product!)
        }
        
        self.completeProduct = product
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
            case "showDetail":
                let detailViewController = segue.destination as! DetailViewController
                detailViewController.shoppingList = self.listId!
                detailViewController.selectedProduct = self.completeProduct!
                let backItem = UIBarButtonItem()
                backItem.title = "Atrás"
                navigationItem.backBarButtonItem = backItem
                if let googlePlace = self.currentGooglePlace {
                    detailViewController.storeId = googlePlace.id
                }
            	print ("showDetail")
        	default:
            	print ("nada")
        }
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
