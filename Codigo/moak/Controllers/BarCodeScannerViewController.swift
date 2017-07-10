//
//  BarCodeScannerViewController.swift
//  moak
//
//  Created by Dx on 20/06/16.
//  Copyright © 2016 moak. All rights reserved.
//

import AVFoundation
import UIKit
import CoreLocation

class BarCodeScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate, CLLocationManagerDelegate {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var detailController : DetailViewController?
    var isShopping: Bool = false
    var selectedProduct : Product?
    var locationManager = CLLocationManager()
    var lastLocation : CLLocation? = nil
    var currentGooglePlace: GooglePlaceResult?
    var inputText: UITextField!
    
    var listId: String? = ""
    
    let defaults = UserDefaults.standard
    
    // MARK: - View methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkingForPermission()
        settingVideoCapture()
        settingButtons()
        if self.defaults.string(forKey: "listId") != nil {
        	self.listId = self.defaults.string(forKey: "listId")!
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if (captureSession?.isRunning == false) {
            captureSession.startRunning();
        }
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (captureSession?.isRunning == true) {
            captureSession.stopRunning();
        }
        
        //self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "addProductQuestionSegue":
            let questionViewController = segue.destination as! AddToListQuestionViewController
            questionViewController.selectedProduct = self.selectedProduct
            questionViewController.shoppingListId = self.listId!
            let backItem = UIBarButtonItem()
            backItem.title = "Atrás"
            navigationItem.backBarButtonItem = backItem
            if let googlePlace = self.currentGooglePlace {
                questionViewController.storeId = googlePlace.id
            }
            
            self.defaults.set("BarCode", forKey: "CaptureMode")
        case "showTutorial":
            let tutorial = segue.destination as! TutorialViewController
            tutorial.requiredScreen = "BarCode"
        default:
            print("No hay un segue aquí")
        }
    }
    
    // MARK: - Methods
    
    func checkingForPermission() {
        let cameraMediaType = AVMediaTypeVideo
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(forMediaType: cameraMediaType)
        
        switch cameraAuthorizationStatus {
        case .denied: break
        case .authorized: break
        case .restricted: break
            
        case .notDetermined:
            // Prompting user for the permission to use the camera.
            AVCaptureDevice.requestAccess(forMediaType: cameraMediaType) { granted in
                if granted {
                    print("Granted access to \(cameraMediaType)")
                } else {
                    print("Denied access to \(cameraMediaType)")
                }
            }
        }
    }
    
    func settingVideoCapture() {
        view.backgroundColor = UIColor.black
        captureSession = AVCaptureSession()
        
        let videoCaptureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            failed();
            return;
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypePDF417Code]
        } else {
            failed()
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession);
        previewLayer.frame = view.layer.bounds;
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        view.layer.addSublayer(previewLayer);
        
        captureSession.startRunning();
    }
    
    func settingButtons() {
        let titleLabel = UILabel(frame: CGRect(x:self.view.frame.size.width / 2 - 125, y: 76, width: 250, height: 30))
        titleLabel.layer.cornerRadius = 17
        titleLabel.backgroundColor = .black
        titleLabel.layer.cornerRadius = 15
        titleLabel.textColor = .white
        titleLabel.text = "Captura un código de barra"
        titleLabel.textAlignment = .center
        
        view.addSubview(titleLabel)
        
        let buttonFlash = UIButton(frame: CGRect(x: 20, y: self.view.frame.size.height - 100, width: 100, height: 50))
        buttonFlash.backgroundColor = .red
        buttonFlash.layer.cornerRadius = 17
        buttonFlash.setTitleColor(.white, for: UIControlState())
        buttonFlash.setTitle("Flash", for: UIControlState())
        buttonFlash.addTarget(self, action: #selector(self.toggleFlash), for: .touchUpInside)
        
        view.addSubview(buttonFlash)
        
        let buttonCancel = UIButton(frame: CGRect(x: self.view.frame.size.width - 120, y: self.view.frame.size.height - 100, width: 100, height: 50))
        buttonCancel.backgroundColor = .white
        buttonCancel.layer.cornerRadius = 17
        buttonCancel.setTitleColor(.black, for: UIControlState())
        buttonCancel.setTitle("Cancelar", for: UIControlState())
        buttonCancel.addTarget(self, action: #selector(self.cancel), for: .touchUpInside)
        view.addSubview(buttonCancel)
        
        let pageControl = UIPageControl(frame: CGRect(x: self.view.frame.size.width / 2 - 18, y: 42, width: 40, height: 20))
        pageControl.currentPage = 0
        pageControl.currentPageIndicatorTintColor = UIColor.red
        pageControl.numberOfPages = 3
        pageControl.tintColor = UIColor.lightGray
        view.addSubview(pageControl)
        
        let tutorialButton = UIButton.init(type: .infoDark)
        tutorialButton.frame = CGRect(x: self.view.frame.size.width - 38, y: 42, width: 20, height: 20)
        tutorialButton.tintColor = .red
        tutorialButton.addTarget(self, action: #selector(self.showTutorial), for: .touchUpInside)
        
        view.addSubview(tutorialButton)
    }
    
    func showTutorial() {
        performSegue(withIdentifier: "showTutorial", sender: self)
    }
    
    func cancel() {
        captureSession.stopRunning()
        self.parent?.dismiss(animated: true, completion: nil)
    }
    
    func toggleFlash() {
        let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        if (device?.hasTorch)! {
            do {
                try device?.lockForConfiguration()
                if (device?.torchMode == AVCaptureTorchMode.on) {
                    device?.torchMode = AVCaptureTorchMode.off
                } else {
                    do {
                        try device?.setTorchModeOnWithLevel(1.0)
                    } catch {
                        print(error)
                    }
                }
                device?.unlockForConfiguration()
            } catch {
                print(error)
            }
        }
    }
    
    func failed() {
        let ac = UIAlertController(title: "Código de barras no soportado", message: "Tu dispositivo no soporta lector de barras. Utiliza un dispositivo con cámara", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(ac, animated: true, completion: nil)
        captureSession = nil
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        captureSession.stopRunning()
        
        if let metadataObject = metadataObjects.first {
            let readableObject = metadataObject as! AVMetadataMachineReadableCodeObject;
            
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            foundCode(readableObject.stringValue);
        }
    }
    
    func foundCode(_ code: String) {
        print(code)
        
        
        if self.selectedProduct != nil && self.selectedProduct!.productSKU.substring(from: 0, to: 0) == "m" {
            let firebase = FirebaseClient()
        	firebase.setSpecificSkuToGenericSku(specificSku: code, genericSku: self.selectedProduct!.productSKU)
        }
        
        self.barcodeFound(code: code) { (product: Product ) in

            self.selectedProduct = product
            
            if self.detailController != nil {
                
                self.detailController!.selectedProduct = self.selectedProduct
                
                DispatchQueue.main.async {
                	self.dismiss(animated: true, completion: nil)
                }
            } else {
            	
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "addProductQuestionSegue", sender: self)
                }
            }
        }
    }
    
    func barcodeFound(code: String, completion: @escaping (_ product: Product) -> Void) {
        
        let firebase = FirebaseClient()
        if self.selectedProduct != nil {
        	firebase.deleteProduct(shoppingList: self.selectedProduct!.shoppingList, productId: self.selectedProduct!.productId)
        }
        
        let searchClient = SearchClient()
        searchClient.findDescriptionSKUAndMoakSKUs(code) { (result: String?) in
            if result != nil {
                let product = self.addNewProduct(productName: result!, skuName: result!, sku: code)
                completion(product)
            } else {
                print("No encontró sku \(code) en search: intentará en firebase")
                
                firebase.getProductSKU(sku: code, completion: {(name: String) in
                    if name != "" {
                        print("Sí encontró sku \(code) en firebase")
                        let product = self.addNewProduct(productName: name, skuName: name, sku: code)
                        completion(product)
                    } else {
                        self.showAlertForProduct({(productName: String?) in
                            if let name = productName {
                                let product = self.addNewProduct(productName: name, sku: code)
                                firebase.setProductSKU(productName: name, sku: code)
                                
                                completion(product)
                            }
                        })
                    }
                })
            }
        }
    }
    
    func showAlertForProduct(_ completion:@escaping (String?) -> ()) {
        let alertController = UIAlertController(title: "No se encontró el código de barras", message: "Captura el nombre del producto", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) {
            UIAlertAction in
            
            self.inputText.autocapitalizationType = .words
            
            if self.inputText != nil {
                completion(self.inputText!.text)
            }
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
            self.inputText = textField!
            self.inputText.autocapitalizationType = .words
            self.inputText!.text = ""
        }
    }
    
    // MARK: - Add product
    
    func addNewProduct(productName: String, sku: String) -> Product {
        let product = self.addNewProduct(productName: productName, skuName: "", sku: sku)
        return product
    }
    
    func addNewProduct(productName: String, skuName: String, sku: String) -> Product {
        var product : Product?
        let firebase = FirebaseClient()
        var list = ""
        
        if self.listId != nil {
            list = self.listId!
        } else {
            if self.detailController != nil && self.detailController!.shoppingList != nil {
                list = self.detailController!.shoppingList!
            }
        }
        
        if let location = self.lastLocation {
            product = Product(productName: productName, productSKUName: skuName, productSKU: sku, lat: location.coordinate.latitude, lng: location.coordinate.longitude, order: 0, shoppingList: list)
        } else {
            product = Product(productName: productName, productSKUName: skuName, productSKU: sku, lat: 0, lng: 0, order: 0, shoppingList: list)
        }
        
        if let store = self.currentGooglePlace {
            firebase.getLastPriceInStore(storeId: store.id, skuNumber: sku ) {(productComparer: ProductComparer?) in
                if let price = productComparer {
                    product?.unitaryPrice = price.unitaryPrice
                    
                    firebase.updateProductPrice(shoppingList: list, purchaseId: (product?.productId)!, buyThreePayTwo: false, unitaryPrice: price.unitaryPrice, totalPrice: price.unitaryPrice)
                }
            }
        }
        
        firebase.addProductInShoppingList(shoppingList: list, product: product!)
        
        return product!
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
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return .portrait
    }
}
