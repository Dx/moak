//
//  DetailViewController.swift
//  moak
//
//  Created by Dx on 03/04/16.
//  Copyright © 2016 moak. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

class DetailViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Properties
    @IBOutlet weak var productName: UITextField!
    @IBOutlet weak var productQuantity: UITextField!
    @IBOutlet weak var productPrice: UITextField!
    @IBOutlet weak var productTotalPrice: UITextField!
    @IBOutlet weak var tablePicker: UISegmentedControl!
    @IBOutlet weak var skuText: UITextField!
    @IBOutlet weak var barcodeButton: UIButton!
    @IBOutlet weak var historyTableView: UITableView!
    @IBOutlet weak var modePicker: UISegmentedControl!
    
    var comesFromList = false
    var inputText: UITextField?
    var levelNavigationControllers = 0
    var productsHistory: [ProductComparer] = []
    var productsComparer: [ProductComparer] = []
    var shoppingList: String?
    var storeId: String?
    var ticketSelected: String?
    var selectedProduct : Product?
    var list : ListsViewController?
    var historyList: HistoryViewController?
    var screenWidth : CGFloat = 0.0
    var screenHeight : CGFloat = 0.0
    var unityCaptured = true
    
    // MARK: - View methods
    
    override func viewDidLoad() {
        configureAutoCompleteList()
        self.configureScreen()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.loadValues()
        
    }
    
    func loadValues() {
        
        if self.selectedProduct != nil {
            loadScreen()
        } else {
        	let firebase = FirebaseClient()
        
        	firebase.getProductInShoppingList(shoppingList: (self.selectedProduct?.shoppingList)!, productId: (self.selectedProduct?.productSKU)!, completion: {(product: Product?) in
            
            	if let product = product {
            		self.selectedProduct = product
                	
                    self.loadScreen()
            	}
            
            	self.productPrice.becomeFirstResponder()
        	})
        }
    }
        
    func loadScreen() {
        if let product = self.selectedProduct {
        	self.productName.text = product.productName
        
        	let formatter = NumberFormatter()
        	formatter.numberStyle = .currency
        	self.productPrice.text = formatter.string(from: product.unitaryPrice as NSNumber)
        	if product.quantity != 0 {
            	let nf = NumberFormatter()
            	nf.numberStyle = .decimal
            	self.productQuantity.text = nf.string(from: product.quantity as NSNumber)
        	} else {
            	self.productQuantity.text = "0"
        	}
            
            if product.buyThreePayTwo {
            	self.modePicker.selectedSegmentIndex = 1
            } else {
                self.modePicker.selectedSegmentIndex = 0
            }
        
        	self.productTotalPrice.text = formatter.string(from: product.totalPrice as NSNumber)
        
        	if product.productSKU != "" {
            	self.skuText.text = product.productSKU
            	self.searchForSKUInHistory()
            	self.reloadTables()
        	}
            
            self.productPrice.becomeFirstResponder()
        }
    }
    
    func configureScreen() {
        self.hideKeyboardWhenTappedAround()
        productName.delegate = self
        
        self.productName.autocapitalizationType = .sentences
        
        productQuantity.keyboardType = .decimalPad
        productQuantity.delegate = self
        
        productPrice.keyboardType = .decimalPad
        productPrice.delegate = self
        
        productTotalPrice.keyboardType = .decimalPad
        productTotalPrice.delegate = self
        
        self.historyTableView.reloadData()
        
        let screenSize: CGRect = UIScreen.main.bounds
        self.screenWidth = screenSize.width
        self.screenHeight = screenSize.height
        
        if ticketSelected != nil { // It comes from history ticket
            productQuantity.isEnabled = false
            productPrice.isEnabled = false
            productTotalPrice.isEnabled = false
            barcodeButton.isEnabled = false
        } else {
            self.addDoneButtonOnKeyboard()
            productQuantity.isEnabled = true
            productPrice.isEnabled = true
            productTotalPrice.isEnabled = true
            barcodeButton.isEnabled = true
        }
    }
    
    @IBAction func clickToCart(_ sender: Any) {
        addToList()
    }
    
    @IBAction func clickJustPrice(_ sender: Any) {
        captureJustPrice()
    }
    
    @IBAction func searchProductClick(_ sender: AnyObject) {
        self.performSegue(withIdentifier: "showProductDescription", sender: nil)
    }
    
    @IBAction func modePickerChanged(_ sender: Any) {
        
        switch modePicker.selectedSegmentIndex {
        case 0:
            productTotalPrice.isEnabled = true
            textFieldDidEndEditing(self.productQuantity)
            productPrice.becomeFirstResponder()
        case 1:
            if productQuantity.text == "0" || productQuantity.text == "1" || (productQuantity.text?.contains("."))! {
            	productQuantity.text = "3"
            }
            textFieldDidEndEditing(self.productQuantity)
            productPrice.becomeFirstResponder()
            textFieldDidBeginEditing(self.productPrice)
            productTotalPrice.isEnabled = false
        default:
            print("dev/null")
        }
    }
    
    @IBAction func tablePickerChanged(_ sender: Any) {
        self.historyTableView.reloadData()
    }
   
    @IBAction func clickTutorial(_ sender: Any) {
        performSegue(withIdentifier: "showTutorial", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.identifier! {
        case "showProductDescription":
            let destination = segue.destination as! AddProductDescriptionController
            destination.product = self.selectedProduct
        case "showBarCodeScanner":
            let destination = segue.destination as! BarCodeScannerViewController
            destination.selectedProduct = self.selectedProduct
            destination.detailController = self
        case "showTutorial":
            let tutorial = segue.destination as! TutorialViewController
            tutorial.requiredScreen = "Detail"
        default:
            print ("dev/null")
        }
    }
    
    @IBAction func barcodeButtonClicked(_ sender: AnyObject) {
        
        self.performSegue(withIdentifier: "showBarCodeScanner", sender: self)
    }
    
    // MARK: - Functions
        
    func searchForSKUInHistory() {
        if ticketSelected == nil && self.storeId != nil { // It comes from shopping list, not history
            
            let firebase = FirebaseClient()
            firebase.getLastPriceInStore(storeId: self.storeId!, skuNumber: self.selectedProduct!.productSKU ) {(productComparer: ProductComparer?) in
            
                if productComparer != nil {
                    DispatchQueue.main.async {
                        let formatter = NumberFormatter()
                        formatter.numberStyle = .decimal
                        formatter.maximumFractionDigits = 2
                        
                        _ = NSNumber(value:(productComparer?.unitaryPrice)!)
                        
                        // self.productPrice.text = formatter.string(from: number)
                    }
                }
            }
        }
    }
    
    func configureAutoCompleteList() {
        self.historyTableView.delegate = self
        self.historyTableView.dataSource = self
        self.historyTableView.separatorStyle = .singleLine
        self.historyTableView.tableFooterView = UIView()
    }
    
    func productSelected(_ product: SearchProduct) {
        self.productName.text = product.nombre
        self.skuText.text = product.sku
    }
        
    func reloadTables() {
        
        if let sku = skuText.text {
            
            let skuText = sku.trimmingCharacters(
                in: CharacterSet.whitespacesAndNewlines)
            
            let firebase = FirebaseClient()
            
        	if skuText != "" {
        
                firebase.getLastProductPrices(skuNumber: skuText ) { (comparers: [ProductComparer]) in
                    self.productsComparer = comparers.sorted( by: { $0.priceDate > $1.priceDate } )
            
                    if self.productsComparer.count > 0 {
                        self.historyTableView.reloadData()
                    }
                }
                
                firebase.getLastUserPrices(skuNumber: skuText, priceNumber: 5) { (historyProducts: [ProductComparer]) in
                    
                    self.productsHistory = historyProducts.sorted( by: { $0.priceDate > $1.priceDate })
                    
                    if self.productsHistory.count > 0 {
                        self.historyTableView.reloadData()
                    }
                }
        	}
    	}
    }
    
    func barcodeFound(_ code: String) {
        let firebase = FirebaseClient()
        self.selectedProduct?.productSKU = code
        self.skuText.text = code
        firebase.updateProductName(shoppingList: self.shoppingList!, purchaseId: (self.selectedProduct?.productId)!, productName: self.productName.text!, productSKUName: self.productName.text!, productSKU: self.skuText.text!)
        
        self.searchForSKUInHistory()
        
        let searchClient = SearchClient()
        searchClient.retrieveDescription(code, completion: {(result: String?, error: String?) in
            if error == nil {
                DispatchQueue.main.async {
                	self.productName.text = result!
                }
                
                firebase.updateProductName(shoppingList: self.shoppingList!, purchaseId: (self.selectedProduct?.productId)!, productName: (self.selectedProduct?.productName)!, productSKUName: result!,  productSKU: self.skuText.text!)
                
                self.reloadTables()
            } else {
                let firebase = FirebaseClient()
                
                firebase.getProductSKU(sku: code, completion: {(name: String) in
                    if name != "" {
                        print("Sí encontró sku \(code) en firebase")
                        firebase.updateProductName(shoppingList: self.shoppingList!, purchaseId: (self.selectedProduct?.productId)!, productName: (self.selectedProduct?.productName)!, productSKUName: name,  productSKU: self.skuText.text!)
                    } else {
                    	firebase.setProductSKU(productName: name, sku: code)
                    }
                })
            }
        })
    }
    
    func showAlertForProduct(_ completion:@escaping (String?) -> ()) {
        let alertController = UIAlertController(title: "No se encontró el código de barras", message: "Captura el nombre del producto", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) {
            UIAlertAction in
            
            if self.inputText != nil {
                completion(self.inputText!.text)
            }
            
            NSLog("OK Undo Pressed")
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) {
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
    
    func addDoneButtonOnKeyboard() {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: 50))
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Al carrito", style: UIBarButtonItemStyle.done, target: self, action: #selector(DetailViewController.addToList))
        
        done.tintColor = .red
        
        let onlyPrice: UIBarButtonItem = UIBarButtonItem(title: "Solo precio", style: UIBarButtonItemStyle.done, target: self, action: #selector(DetailViewController.captureJustPrice))
        
        onlyPrice.tintColor = .red
        
        var items: [UIBarButtonItem]? = [UIBarButtonItem]()
        items?.append(flexSpace)
        items?.append(done)
        items?.append(flexSpace)
        items?.append(onlyPrice)
        items?.append(flexSpace)
        
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        productPrice.inputAccessoryView=doneToolbar
        productTotalPrice.inputAccessoryView=doneToolbar
        productQuantity.inputAccessoryView=doneToolbar
    }
    
    func finishDetailView() {
        
        if let listsViewController = self.list {
            listsViewController.reloadProducts()
        } else {
            if let historyViewController = self.historyList {
                historyViewController.tableView.reloadData()
            }
        }
        
        if self.comesFromList {
            self.dismiss(animated: true, completion: nil)
        } else {
        	self.parent?.dismiss(animated: true, completion: nil)
        }
    }
    
    func addToList() {
        
        if productTotalPrice.isFirstResponder {
            productQuantity.becomeFirstResponder()
        } else {
            productTotalPrice.becomeFirstResponder()
        }
        
        if self.selectedProduct != nil {
            if self.selectedProduct!.totalPrice > 0 {
                let firebase = FirebaseClient()
                firebase.check(shoppingList: self.selectedProduct!.shoppingList, purchaseId: self.selectedProduct!.productId, checked: true)
            }
        }
        self.finishDetailView()
    }
    
    func captureJustPrice() {
        
        self.productName.becomeFirstResponder()
        
        if self.selectedProduct != nil {
            if self.selectedProduct!.totalPrice > 0 {
                let firebase = FirebaseClient()
                firebase.check(shoppingList: self.selectedProduct!.shoppingList, purchaseId: self.selectedProduct!.productId, checked: false)
            }
        }
        self.finishDetailView()
    }
    
    // MARK: - TableView Delegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch self.tablePicker.selectedSegmentIndex {
        case 0:
            return productsHistory.count
        case 1:
            return productsComparer.count
        default:
            print ("not found")
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let product : ProductComparer
        let cell : DetailHistoryCell
        
        switch self.tablePicker.selectedSegmentIndex {
        case 0:
            product = productsHistory[(indexPath as NSIndexPath).row]
        case 1:
            product = productsComparer[(indexPath as NSIndexPath).row]
        default:
            print ("not found")
            return UITableViewCell()
        }
        
        cell = self.historyTableView.dequeueReusableCell(withIdentifier: "historyCell", for: indexPath) as! DetailHistoryCell
        
        cell.storeLabel.text = product.storeName
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd"
        
        var formattedDate =  ""
        if let date = product.priceDate {
            formattedDate = dateFormatter.string(from: date as Date)
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        
        cell.dateLabel.text = formattedDate
        
        let number = NSNumber(value:product.unitaryPrice)
        cell.priceLabel.text = formatter.string(from: number)
        
        let bgColorView = UIView()
        bgColorView.backgroundColor = UIColor(red: 0, green: 0.619, blue: 0.655, alpha: 1)
        cell.selectedBackgroundView = bgColorView
        
        return cell
    }

    
    // MARK: - TextField Delegate
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField.text == "." {
            textField.text = "0."
        }
        
        if textField.text?.range(of: ",") != nil {
            
        }
        
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        switch textField {
        case productQuantity:
            if let product = selectedProduct {
                let formatter = NumberFormatter()
                formatter.numberStyle = .decimal
                formatter.maximumFractionDigits = 3
                
                self.productQuantity.text = formatter.string(from: product.quantity as NSNumber)
                
                if self.productQuantity.text == "0" {
                    self.productQuantity.text = ""
                }
                
                self.productQuantity.selectedTextRange = self.productQuantity.textRange(from: self.productQuantity.beginningOfDocument, to: self.productQuantity.endOfDocument)
            }
        case productPrice:
        	if let product = selectedProduct {
                let formatter = NumberFormatter()
        		formatter.numberStyle = .decimal
        		formatter.maximumFractionDigits = 2
                
                self.productPrice.text = formatter.string(from: product.unitaryPrice as NSNumber)
                
                if self.productPrice.text == "0" {
                    self.productPrice.text = ""
                }
                
                self.productPrice.selectedTextRange = self.productPrice.textRange(from: self.productPrice.beginningOfDocument, to: self.productPrice.endOfDocument)
        	}
            
        case productTotalPrice:
            if let product = selectedProduct {
                let formatter = NumberFormatter()
                formatter.numberStyle = .decimal
                formatter.maximumFractionDigits = 2
                
                self.productTotalPrice.text = formatter.string(from: product.totalPrice as NSNumber)
                
                if self.productTotalPrice.text == "0" {
                    self.productTotalPrice.text = ""
                }
                
                self.productTotalPrice.selectedTextRange = self.productTotalPrice.textRange(from: self.productTotalPrice.beginningOfDocument, to: self.productTotalPrice.endOfDocument)                
            }
        default:
            print("not a good option")
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        let stringToNumberFormatter = NumberFormatter()
        let firebase = FirebaseClient()
        
        switch textField {
        case productName:
            firebase.updateProductName(shoppingList: self.shoppingList!, purchaseId: (self.selectedProduct?.productId)!, productName: self.productName.text!, productSKUName: (self.selectedProduct?.productSKUName)!,  productSKU: self.skuText.text!)
            self.selectedProduct?.productName = self.productName.text!
			self.reloadTables()
            
        case productPrice:
            
            if let _ = Float(self.productPrice.text!) {}
            else {
                self.productPrice.text = "0"
            }
            
            if self.productPrice.text != "" {
                unityCaptured = true
            	self.selectedProduct!.unitaryPrice = (self.productPrice.text! as NSString).floatValue
                
                let nf = NumberFormatter()
                nf.numberStyle = .decimal
                
                self.selectedProduct!.buyThreePayTwo = modePicker.selectedSegmentIndex == 1
                
                if !self.selectedProduct!.buyThreePayTwo {
                    
            		self.selectedProduct!.totalPrice = (self.selectedProduct?.unitaryPrice)! * (stringToNumberFormatter.number(from: productQuantity.text!)!).floatValue
                } else {
                    self.selectedProduct!.totalPrice = (self.selectedProduct?.unitaryPrice)! * ((stringToNumberFormatter.number(from: productQuantity.text!)!).floatValue / 3 * 2)
                }
                
            	let formatter = NumberFormatter()
            	formatter.numberStyle = .currency
            	self.productTotalPrice.text = formatter.string(from: self.selectedProduct!.totalPrice as NSNumber)
            	
                firebase.updateProductPrice(shoppingList: self.shoppingList!, purchaseId: (self.selectedProduct?.productId)!, buyThreePayTwo: self.selectedProduct!.buyThreePayTwo, unitaryPrice: self.selectedProduct!.unitaryPrice, totalPrice: self.selectedProduct!.totalPrice)
            }
        case productTotalPrice:
            if let _ = Float(self.productTotalPrice.text!) {}
            else {
                self.productTotalPrice.text = "0"
            }
            
            self.selectedProduct!.buyThreePayTwo = modePicker.selectedSegmentIndex == 1
            
            unityCaptured = false
            if self.productTotalPrice.text != "" {
                if !self.selectedProduct!.buyThreePayTwo {
                    self.selectedProduct!.totalPrice = (stringToNumberFormatter.number(from: self.productTotalPrice.text!)?.floatValue)!
                    
                    let quantity = (stringToNumberFormatter.number(from: productQuantity.text!))!.floatValue
                    if quantity == 0 {
                        self.selectedProduct!.unitaryPrice = 0
                    } else {
                        self.selectedProduct!.unitaryPrice = (self.selectedProduct?.totalPrice)! / quantity
                    }
                }
            
            	let formatter = NumberFormatter()
            	formatter.numberStyle = .currency
            	self.productTotalPrice.text = formatter.string(from: self.selectedProduct!.totalPrice as NSNumber)
            
                firebase.updateProductPrice(shoppingList: self.shoppingList!, purchaseId: (self.selectedProduct?.productId)!, buyThreePayTwo: self.selectedProduct!.buyThreePayTwo, unitaryPrice: self.selectedProduct!.unitaryPrice, totalPrice: self.selectedProduct!.totalPrice)
            }
        case productQuantity:
            if let _ = Float(self.productQuantity.text!) {
            } else {
                    self.productQuantity.text = "0"
            }
            
            if unityCaptured {
                
                self.selectedProduct!.buyThreePayTwo = modePicker.selectedSegmentIndex == 1
                
                if !self.selectedProduct!.buyThreePayTwo {
                	self.selectedProduct!.totalPrice = (self.selectedProduct?.unitaryPrice)! * (stringToNumberFormatter.number(from: productQuantity.text!))!.floatValue
                } else {
                    
                    let number = stringToNumberFormatter.number(from: productQuantity.text!)
                    
                    if let intNumber = number {
                        if  Int(intNumber) % 3 > 0 {
                        	self.productQuantity.text = "3"
                        	self.selectedProduct!.quantity = 3
                        }
                    } else {
                        self.productQuantity.text = "3"
                        self.selectedProduct!.quantity = 3
                    }
                    
                    self.selectedProduct!.quantity = Float(Int(stringToNumberFormatter.number(from: productQuantity.text!)!))
                    
                    self.selectedProduct!.totalPrice = (self.selectedProduct?.unitaryPrice)! * ((stringToNumberFormatter.number(from: productQuantity.text!))!.floatValue / 3 * 2)
                }
            } else {
                let quantity = (stringToNumberFormatter.number(from: productQuantity.text!))!.floatValue
                if quantity == 0 {
                    self.selectedProduct!.unitaryPrice = 0
                } else {
                	self.selectedProduct!.unitaryPrice = (self.selectedProduct?.totalPrice)! / quantity
                }
            }
            
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            self.productTotalPrice.text = formatter.string(from: self.selectedProduct!.totalPrice as NSNumber)
            
            firebase.updateProductQuantity(shoppingList: self.shoppingList!, purchaseId: (self.selectedProduct?.productId)!, quantity: NSDecimalNumber(string:productQuantity.text!), totalPrice: self.selectedProduct!.totalPrice)
            
            firebase.updateProductPrice(shoppingList: self.shoppingList!, purchaseId: (self.selectedProduct?.productId)!, buyThreePayTwo: self.selectedProduct!.buyThreePayTwo, unitaryPrice: self.selectedProduct!.unitaryPrice, totalPrice: self.selectedProduct!.totalPrice)

        default:
            selectedProduct?.productName = "err"
        }
        
        self.productName.text = selectedProduct!.productName
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        self.productPrice.text = formatter.string(from: selectedProduct!.unitaryPrice as NSNumber)
    }
}

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
}
