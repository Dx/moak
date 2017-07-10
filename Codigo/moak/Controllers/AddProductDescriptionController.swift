//
//  AddProductDescriptionController.swift
//  moak
//
//  Created by Dx on 03/10/16.
//  Copyright © 2016 moak. All rights reserved.
//

import UIKit
import AudioToolbox
import Speech
import CoreLocation

class AddProductDescriptionController: UIViewController, UITableViewDataSource, UITableViewDelegate, SFSpeechRecognizerDelegate, CLLocationManagerDelegate {
    

    @IBOutlet weak var searchText: UITextField!
    @IBOutlet weak var searchTable: UITableView!
    @IBOutlet weak var listBottomMargin: NSLayoutConstraint!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    let defaults = UserDefaults.standard
    
    var product: Product?
    var listId: String?
    
    var enableDictation = true
    
    var selectedProduct : Product?
    var skuSelected = ""
    var isUserProduct = false
    var products: [SearchProduct] = []
    var modeList: String = "l"
    var currentGooglePlace: GooglePlaceResult?
    
    var locationManager = CLLocationManager()
    var lastLocation : CLLocation? = nil
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "es-MX"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    var screenWidth : CGFloat = 0.0
    var screenHeight : CGFloat = 0.0
    
    var listController: ListsViewController? = nil
    
    var descriptions: [String] = []
    
    // MARK: - View methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.searchText.autocapitalizationType = .words
        
        self.listId = self.defaults.string(forKey: "listId")!

        let tap = UITapGestureRecognizer(target: self, action: #selector(self.viewTapped))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name:NSNotification.Name.UIKeyboardWillShow, object: self.view.window)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name:NSNotification.Name.UIKeyboardWillHide, object: self.view.window)
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            
            switch authStatus {
            case .authorized:
                print("Speech recognition autorized :)")
                
            case .denied:
                print("User denied access to speech recognition")
                
            case .restricted:
                print("Speech recognition restricted on this device")
                
            case .notDetermined:
                print("Speech recognition not yet authorized")
            }
        }
        
        self.configureTable()
        
        self.searchText.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: UIControlEvents.editingChanged)
        
        self.startActivity(on: false)
        
        speechRecognizer?.delegate = self
        
        addDictationButtonOnKeyboard()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.searchText.becomeFirstResponder()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        //self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "showTutorial":
            let tutorial = segue.destination as! TutorialViewController
            tutorial.requiredScreen = "Description"
        case "addToListQuestionSegue":
            let questionViewController = segue.destination as! AddToListQuestionViewController
            questionViewController.selectedProduct = self.selectedProduct
            questionViewController.shoppingListId = self.listId!
            let backItem = UIBarButtonItem()
            backItem.title = "Atrás"
            navigationItem.backBarButtonItem = backItem
            if let googlePlace = self.currentGooglePlace {
                questionViewController.storeId = googlePlace.id
            }
            
            self.defaults.set("Description", forKey: "CaptureMode")
        default :
            print ("Ups")
        }
    }
    
    // MARK: - Methods
    
    func addDictationButtonOnKeyboard() {
        self.searchText.inputAccessoryView = nil
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: 50))
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        
        let dictation: UIBarButtonItem = UIBarButtonItem(title: "Dictar", style: UIBarButtonItemStyle.done, target: self, action: #selector(AddProductDescriptionController.startDictation))
        
        dictation.tintColor = .red
        dictation.isEnabled = self.enableDictation
        
        let cancel: UIBarButtonItem = UIBarButtonItem(title: "Cancelar", style: UIBarButtonItemStyle.done, target: self, action: #selector(AddProductDescriptionController.cancel))
        
        cancel.tintColor = .red
        
        var items: [UIBarButtonItem]? = [UIBarButtonItem]()
        
        items?.append(dictation)
        items?.append(flexSpace)
        items?.append(cancel)
        
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        self.searchText.inputAccessoryView = doneToolbar
        
        self.searchText.resignFirstResponder()
        self.searchText.becomeFirstResponder()
    }
    
    func cancel() {
        self.parent?.dismiss(animated: true, completion: nil)
    }
    
    func addStopDictationButtonOnKeyboard() {
        self.searchText.inputAccessoryView = nil
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: 50))
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        let dictation: UIBarButtonItem = UIBarButtonItem(title: "Detener", style: UIBarButtonItemStyle.done, target: self, action: #selector(AddProductDescriptionController.stopRecording))
        
        dictation.tintColor = .red
        
        var items: [UIBarButtonItem]? = [UIBarButtonItem]()
        
        items?.append(dictation)
        items?.append(flexSpace)
        
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
    	self.searchText.inputAccessoryView = doneToolbar
        
        self.searchText.resignFirstResponder()
        self.searchText.becomeFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func startDictation() {
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
        
        if !audioEngine.isRunning {
            startRecording()
        }
        
        searchText.inputAccessoryView = nil
        
        addStopDictationButtonOnKeyboard()
    }
    
    @IBAction func cancelClick(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Dictation
    
    func stopRecording() {
        audioEngine.stop()
        
        if self.searchText.text == "Te escucho..." {
            self.searchText.text = ""
        }
        
        recognitionRequest?.endAudio()
        
        addDictationButtonOnKeyboard()
    }
    
    func startRecording() {
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode = audioEngine.inputNode else {
            fatalError("Audio engine has no input node")
        }
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isFinal = false
            
            if result != nil {
                
                self.searchText.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
                
                self.searchProducts(self.searchText.text!)
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        
        self.searchText.text = "Te escucho..."
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        self.enableDictation = available
        addDictationButtonOnKeyboard()
    }
    
    func keyboardWillHide(_ sender: Notification) {
        listBottomMargin.constant = 50
    }
    
    func keyboardWillShow(_ sender: Notification) {
        listBottomMargin.constant = 270
    }
    
    func addProductToList() {
        self.selectedProduct = self.addProduct()
        
    }
    
    func searchProducts(_ name: String) {
        self.products = []
        
        if name.characters.count > 0 {
            
            self.startActivity(on: true)
            let name = name.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            if !self.products.contains(where: { $0.precioEstimado == -2 }) {
                let product = SearchProduct()
                product.nombre = name
                product.userProduct = true
                product.sku = self.generateProvisionalSku()
                product.precioEstimado = -2
                self.products.append(product)
            }
            
            // Search on user products
            let firebase = FirebaseClient()
            firebase.getUserProductsWithName(nameSearch: name) { (result: [SearchProduct]?) in
                if result != nil {
                    self.products.append(contentsOf: result!)
                }
                
                DispatchQueue.main.async {
                	self.reloadTable(name: name)
                	self.startActivity(on: false)
                }
            }
            
            let search = SearchClient()
            search.retrieveProductsWithName(name) { (result:[SearchProduct], error: String?) in
                if result.count > 0 {
                    self.products.append(contentsOf: result)
                }
                
                DispatchQueue.main.async {
                    self.reloadTable(name: name)
                    self.startActivity(on: false)
                }
            }
            
        } else {
            self.products = []
            self.searchTable.reloadData()
        }
    }
    
    func reloadTable(name: String) {
        
        if self.products.filter({ $0.nombre == name }).count > 1 && self.products.contains(where: { $0.precioEstimado == -2 } ) {
            self.products = self.products.filter({ $0.precioEstimado != -2 })
        }
        
        self.products = self.products.sorted(by: { $0.userProduct && !$1.userProduct })
        self.searchTable.reloadData()
    }
    
    func generateProvisionalSku() -> String {
        let someDate = Date()
        let timeInterval = someDate.timeIntervalSince1970
        let stringInt = String(Int(timeInterval))
        let defaults = UserDefaults.standard
        let userId = defaults.string(forKey: "userId")!
        let result = "m" + userId.substring(from: 0, to:2) + stringInt.substring(from:0, to:8)
        return result
    }
    
    func startActivity(on: Bool) {
        if on {
            self.activityIndicator.startAnimating()
            self.activityIndicator.isHidden = false
        } else {
            self.activityIndicator.stopAnimating()
            self.activityIndicator.isHidden = true
        }
    }
    
    func viewTapped() {
        self.searchText?.resignFirstResponder()
    }
    
    override var canBecomeFirstResponder : Bool {
        return true
    }

    // MARK: - UITextFieldDelegate
    
    func textFieldDidChange(_ textField: UITextField) {
        self.searchProducts(self.searchText.text!)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        var searchString:NSString = self.searchText.text! as NSString
        searchString = searchString.replacingCharacters(in: range, with: string) as NSString
        
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.searchText {
            self.resignFirstResponder()
            self.searchReturnAction()
        }
        return false
    }
    
    // MARK: - Table View
    
    func configureTable() {
        searchTable.delegate = self
        searchTable.dataSource = self
        self.searchTable.tableFooterView = UIView()
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
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! SearchProductCell
        
        let product = products[(indexPath as NSIndexPath).row]
        
        cell.categoryLabel.text = product.categorias.joined(separator: "-")
        cell.nameLabel.text = product.nombre
        cell.skuLabel.text = product.sku
        if product.precioEstimado == -2 {
    		cell.nameLabel.textColor = UIColor.red
        } else {
            cell.nameLabel.textColor = UIColor.black
        }
        self.startActivity(on: false)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.stopRecording()
        self.searchText.text = products[indexPath.row].nombre
        self.skuSelected = products[indexPath.row].sku
        self.isUserProduct = products[indexPath.row].precioEstimado == -2
        self.addProductToList()
        performSegue(withIdentifier: "addToListQuestionSegue", sender: self)
    }
    
    // MARK: - Add product
    
    func addProduct() -> Product {
        return self.addNewProduct(productName: self.searchText!.text!, sku: self.skuSelected)
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
        
        if sku != "" {
        	if let store = self.currentGooglePlace {
            	firebase.getLastPriceInStore(storeId: store.id, skuNumber: sku ) {(productComparer: ProductComparer?) in
                	if let price = productComparer {
                    	product?.unitaryPrice = price.unitaryPrice
                	}
            	}
        	}
        }
        
        firebase.addProductInShoppingList(shoppingList: self.listId!, product: product!)
        
        if self.isUserProduct {
            firebase.saveUserProduct(name: productName, sku: sku)
        }
        
        return product!
    }

    
    // MARK: - Functions
    
    func searchReturnAction() {
        
        if let text = self.searchText?.text!.trimmingCharacters(
            in: CharacterSet.whitespacesAndNewlines) {
            
            if (text == "") {
                self.searchText?.resignFirstResponder()
                return
            } else {
                self.searchText?.text = ""
            }
            
            self.searchText.text = text
            
            _ = self.addProduct()
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
