//
//  MagicListViewController.swift
//  moak
//
//  Created by Dx on 30/05/17.
//  Copyright © 2017 moak. All rights reserved.
//

import UIKit
import CoreLocation

class MagicListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    let defaults = UserDefaults.standard
    var listId: String? = ""
    var locationManager = CLLocationManager()
    var lastLocation : CLLocation? = nil
    var currentGooglePlace: GooglePlaceResult?
    
    var products: [UserProductAverage] = []
    
    // MARK: - View Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureTableList()
        
        loadProducts()
        
        if self.defaults.string(forKey: "listId") != nil {
            self.listId = self.defaults.string(forKey: "listId")!
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        //self.navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "showTutorial":
            let tutorial = segue.destination as! TutorialViewController
            tutorial.requiredScreen = "MagicList"
        default :
            print ("Ups")
        }
    }
    
    @IBAction func cancelClick(_ sender: Any) {
        self.defaults.set("MagicList", forKey: "CaptureMode")
        self.parent?.dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: - Table View
    
    func configureTableList() {
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.separatorStyle = .singleLine
        self.tableView.tableFooterView = UIView()
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ""
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MMM"
        
        let formatterCurrency = NumberFormatter()
        formatterCurrency.numberStyle = .currency
        
        let row = (indexPath as NSIndexPath).row
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! MagicListCell
        cell.selectionStyle = .none
            
        cell.productName.text = products[row].productName
        cell.averageDays.text = "Cada \(Int(products[row].average)) días"
        
        cell.lastPrice.text = formatterCurrency.string(from: products[row].lastPrice as NSNumber)
        
        cell.lastShopped.text = formatter.string(from: products[row].lastShoppingDate!)
        cell.nextShopped.text = formatter.string(from: products[row].nextShoppingDate())
        
        cell.progressBar.progress = Float(products[row].floatProgressBar())
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = (indexPath as NSIndexPath).row
        addToCart(product: products[row], row: row)
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
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    // MARK: - Functions
    
    func addToCart(product: UserProductAverage, row: Int) {
        self.showToast(message: "\(product.productName) agregado a la lista")
        
        _ = addNewProduct(productName: product.productName, sku: product.sku)
        
        products.remove(at: row)
        
        tableView.reloadData()
    }
    
    func loadProducts() {
        let firebase = FirebaseClient()
        
        firebase.getAverageProducts { (result: [UserProductAverage]) in
            self.products = result
            self.tableView.reloadData()
        }
    }
    
    func addNewProduct(productName: String, sku: String) -> Product {
        let product = self.addNewProduct(productName: productName, skuName: "", sku: sku)
        return product
    }
    
    func addNewProduct(productName: String, skuName: String, sku: String) -> Product {
        var product : Product?
        let firebase = FirebaseClient()
        
        if let location = self.lastLocation {
            product = Product(productName: productName, productSKUName: skuName, productSKU: sku, lat: location.coordinate.latitude, lng: location.coordinate.longitude, order: 0, shoppingList: self.listId!)
        } else {
            product = Product(productName: productName, productSKUName: skuName, productSKU: sku, lat: 0, lng: 0, order: 0, shoppingList: self.listId!)
        }
        
        if let store = self.currentGooglePlace {
            firebase.getLastPriceInStore(storeId: store.id, skuNumber: sku ) {(productComparer: ProductComparer?) in
                if let price = productComparer {
                    product?.unitaryPrice = price.unitaryPrice
                    
                    firebase.updateProductPrice(shoppingList: self.listId!, purchaseId: (product?.productId)!, modeBuying: 0, unitaryPrice: price.unitaryPrice, totalPrice: price.unitaryPrice)
                }
            }
        }
        
        firebase.addProductInShoppingList(shoppingList: self.listId!, product: product!)
        
        return product!
    }

}
