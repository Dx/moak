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
import GooglePlaces

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
    var currentGooglePlace: MoakPlace?
    
    var locationManager = CLLocationManager()
    var lastLocation : CLLocation? = nil
    
    var screenWidth : CGFloat = 0.0
    var screenHeight : CGFloat = 0.0
    
    var listController: ListsViewController? = nil
    
    var descriptions: [String] = []
	
	private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "es-MX"))
	private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
	private var recognitionTask: SFSpeechRecognitionTask?
	private let audioEngine = AVAudioEngine()
	
    // MARK: - View methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.searchText.autocapitalizationType = .words
        
        self.listId = self.defaults.string(forKey: defaultKeys.listId)!

        let tap = UITapGestureRecognizer(target: self, action: #selector(self.viewTapped))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name:UIResponder.keyboardWillShowNotification, object: self.view.window)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name:UIResponder.keyboardWillHideNotification, object: self.view.window)
        
        
        self.checkDictationAuthorization()
        
        self.configureTable()
        
        self.searchText.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
        
        self.startActivity(on: false)
        
        speechRecognizer?.delegate = self
        
        addDictationButtonOnKeyboard()
		
		let nc = NotificationCenter.default
		
		let historyPoint = HistoryPoint(id: "0", reason: "Entró a product description", date: Date(), points: 25, userId: "")
		nc.post(name:Notification.Name(rawValue:"LocalNotifications"),
		        object: nil,
		        userInfo: ["message":historyPoint, "date":Date()])
    }
    
    func checkDictationAuthorization() {
        switch SFSpeechRecognizer.authorizationStatus() {
            
        case SFSpeechRecognizerAuthorizationStatus.notDetermined:
            let alert = UIAlertController(title: "Me das permiso?", message: "Moak necesita acceder al reconocimiento de voz para que puedas dictarle. Me autorizas?", preferredStyle: UIAlertController.Style.alert)
            
            alert.addAction(UIAlertAction(title: "No", style: .default, handler: { action in
                switch action.style{
                case .default:
                    print("default")
                    
                case .cancel:
                    print("cancel")
                    
                case .destructive:
                    print("destructive")
                @unknown default:
                    print("error")
                }
            }))
            
            alert.addAction(UIAlertAction(title: "Sí", style: .default, handler: { action in
                switch action.style{
                case .default:
                    print("default")
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
                        @unknown default:
                            fatalError()
                        }
                    }
                    
                case .cancel:
                    print("cancel")
                    
                case .destructive:
                    print("destructive")
                @unknown default:
                    print("error")
                }
            }))
            
            self.present(alert, animated: true, completion: nil)
            
        case SFSpeechRecognizerAuthorizationStatus.authorized:
            print("Autorizado para dictar")
        default:
            let alert = UIAlertController(title: "Me das permiso?", message: "Moak necesita acceder a tu posición para poder detectar si estás cerca de una tienda y mostrarte los mejores precios. Me autorizas?", preferredStyle: UIAlertController.Style.alert)
            
                alert.addAction(UIAlertAction(title: "No", style: .default, handler: { action in
                switch action.style{
                case .default:
                    print("default")
                    
                case .cancel:
                    print("cancel")
                    
                case .destructive:
                    print("destructive")
                @unknown default:
                    print("error")
                }
            }))
            
            alert.addAction(UIAlertAction(title: "Sí", style: .default, handler: { action in
                switch action.style{
                case .default:
                    print("default")
                    self.locationManager.requestAlwaysAuthorization()
                    
                    self.locationManager.startUpdatingLocation()
                    if CLLocationManager.authorizationStatus() != CLAuthorizationStatus.notDetermined {
                        if let appSettings = NSURL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.openURL(appSettings as URL)
                        }
                    }
                    
                case .cancel:
                    print("cancel")
                    
                case .destructive:
                    print("destructive")
                @unknown default:
                    print("error")
                }
            }))
            
            self.present(alert, animated: true, completion: {
                if SFSpeechRecognizer.authorizationStatus() == SFSpeechRecognizerAuthorizationStatus.authorized {
                    self.enableDictation = true
                } else {
                    self.enableDictation = false
                }
                self.addDictationButtonOnKeyboard()
            })
        }

    }
    
    override func viewDidAppear(_ animated: Bool) {
        if SFSpeechRecognizer.authorizationStatus() != SFSpeechRecognizerAuthorizationStatus.authorized {
            checkDictationAuthorization()
        }
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
                questionViewController.storeId = googlePlace.id!
            }
            
            self.defaults.set("Description", forKey: defaultKeys.CaptureMode)
        default :
            print ("Ups")
        }
    }
    
    // MARK: - Methods
    
    func addDictationButtonOnKeyboard() {
        self.searchText.inputAccessoryView = nil
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: 50))
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        
        let dictation: UIBarButtonItem = UIBarButtonItem(title: "Dictar", style: UIBarButtonItem.Style.done, target: self, action: #selector(AddProductDescriptionController.startDictation))
        
        dictation.tintColor = .red
        dictation.isEnabled = self.enableDictation
        
        let cancel: UIBarButtonItem = UIBarButtonItem(title: "Cancelar", style: UIBarButtonItem.Style.done, target: self, action: #selector(AddProductDescriptionController.cancel))
        
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
    
    @objc func cancel() {
        self.parent?.dismiss(animated: true, completion: nil)
    }
    
    func addStopDictationButtonOnKeyboard() {
        self.searchText.inputAccessoryView = nil
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: 50))
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let dictation: UIBarButtonItem = UIBarButtonItem(title: "Detener", style: UIBarButtonItem.Style.done, target: self, action: #selector(AddProductDescriptionController.stopRecording))
        
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
    
    @objc func startDictation() {
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
    
    @objc func stopRecording() {
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
            try audioSession.setCategory(AVAudioSession.Category(rawValue: convertFromAVAudioSessionCategory(AVAudioSession.Category.record)))
            try audioSession.setMode(AVAudioSession.Mode.measurement)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        
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
    
    @objc func keyboardWillHide(_ sender: Notification) {
        listBottomMargin.constant = 50
    }
    
	@objc func keyboardWillShow(_ sender: Notification) {
        listBottomMargin.constant = 270
    }
    
    func addProductToList() {
        self.selectedProduct = self.addProduct()
        
    }
    
    func searchProducts(_ name: String) {
        self.products = []
        
        if name.count > 0 {
            
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
        let userId = defaults.string(forKey: defaultKeys.userId)!
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
    
	@objc func viewTapped() {
        self.searchText?.resignFirstResponder()
    }
    
    override var canBecomeFirstResponder : Bool {
        return true
    }

    // MARK: - UITextFieldDelegate
    
    @objc func textFieldDidChange(_ textField: UITextField) {
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
                firebase.getLastPriceInStore(storeId: store.id!, skuNumber: sku ) {(productComparer: ProductComparer?) in
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

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVAudioSessionCategory(_ input: AVAudioSession.Category) -> String {
	return input.rawValue
}
