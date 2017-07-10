//
//  AddProductController.swift
//  moak
//
//  Created by Dx on 23/11/16.
//  Copyright © 2016 moak. All rights reserved.
//

import UIKit
import AVFoundation
import CoreLocation
import Speech

class AddProductController: UIViewController, AVCaptureMetadataOutputObjectsDelegate, CLLocationManagerDelegate, SFSpeechRecognizerDelegate {

    @IBOutlet weak var productText: UITextField!
    @IBOutlet weak var barcodeButton: UIButton!
    @IBOutlet weak var voiceButton: UIButton!
    @IBOutlet weak var inputText: UITextField!
    @IBOutlet weak var nextButton: UIBarButtonItem!
    @IBOutlet weak var similarTable: UITableView!
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "es-MX"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    
    var locationManager = CLLocationManager()
    
    var selectedProduct : Product!
    
    var lastLocation : CLLocation? = nil
    
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    var modeList: String = "l"
    var listId: String?
    var currentGooglePlace: GooglePlaceResult?
    
    // MARK: - View Methods
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return .portrait
    }
    
    @IBAction func nextClick(_ sender: Any) {
        
        if modeList == "l" {
            
            if inputText.text != "Te escucho..." && inputText.text != "" {
                _ = addNewProduct(productName: inputText.text!)
            }
            
            self.navigationController!.popToViewController(self.navigationController!.viewControllers[1], animated: true)
        } else {
        	performSegue(withIdentifier: "priceQuantitySegue", sender: self)
        }
    }
    
    @IBAction func showBarCodeCamera(_ sender: Any) {
        
        settingVideoCapture()
        
//        if (captureSession?.isRunning == false) {
//            captureSession.startRunning()
//        } else {
//            captureSession.stopRunning()
//        }
    }
    
    @IBAction func dictateClick(_ sender: Any) {
        startRecording()
    }
    
    // MARK: - Voice recognition
    
    func stopRecording() {
        audioEngine.stop()
        
        if self.inputText?.text == "Te escucho..." {
            self.inputText?.text = ""
        }
        
        recognitionRequest?.endAudio()
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
                
                self.inputText.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
                self.voiceButton.isEnabled = true
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.voiceButton.isEnabled = true
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
        
        self.inputText?.text = "Te escucho..."
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            self.voiceButton.isEnabled = true
        } else {
            self.voiceButton.isEnabled = false
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
    
    // MARK: - Bar code
    
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
        previewLayer.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 200)
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        view.layer.addSublayer(previewLayer);
        
        captureSession.startRunning();
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        captureSession.stopRunning()
        
        if let metadataObject = metadataObjects.first {
            let readableObject = metadataObject as! AVMetadataMachineReadableCodeObject
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            foundCode(readableObject.stringValue)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "priceQuantitySegue":
            let detailViewController = segue.destination as! DetailViewController
            detailViewController.selectedProduct = self.selectedProduct
            detailViewController.shoppingList = self.listId!
            let backItem = UIBarButtonItem()
            backItem.title = "Atrás"
            navigationItem.backBarButtonItem = backItem
            if let googlePlace = self.currentGooglePlace {
                detailViewController.storeId = googlePlace.id
            }
        default:
            print("No hay un segue aquí")
        }
    }
    
    func foundCode(_ code: String) {
        print(code)
        
        self.barcodeFound(code: code) { (product: Product ) in
            if self.modeList != "l" {
                self.selectedProduct = product
                self.performSegue(withIdentifier: "priceQuantitySegue", sender: self)
            }
        }
    }
    
    func barcodeFound(code: String, completion: @escaping (_ product: Product) -> Void) {
        
        let searchClient = SearchClient()
        searchClient.retrieveDescription(code, completion: {(result: String?, error: String?) in
            if error == nil {
                let product = self.addNewProduct(productName: result!, skuName: result!, sku: code)
                completion(product)
            } else {
                print("No encontró sku \(code) en search: \(error!) intentará en firebase")
                let firebase = FirebaseClient()
                
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
        )
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
    
    func failed() {
        let ac = UIAlertController(title: "Código de barras no soportado", message: "Tu dispositivo no soporta lector de barras. Utiliza un dispositivo con cámara", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(ac, animated: true, completion: nil)
        captureSession = nil
    }
    
    // MARK: - Add product
    
    func addNewProduct(productName: String) -> Product {
        let product = self.addNewProduct(productName: productName, skuName: "", sku: "")
        
        return product
    }
    
    func addNewProduct(productName: String, sku: String) -> Product {
        let product = self.addNewProduct(productName: productName, skuName: "", sku: sku)
        return product
    }
    
    func addNewProduct(productName: String, skuName: String, sku: String) -> Product {
        let product : Product?
        let firebase = FirebaseClient()
        if let location = self.lastLocation {
            
            product = Product(productName: productName, productSKUName: skuName, productSKU: sku, lat: location.coordinate.latitude, lng: location.coordinate.longitude, order: 0, shoppingList: self.listId!)
            firebase.addProductInShoppingList(shoppingList: self.listId!, product: product!)
        } else {
            product = Product(productName: productName, productSKUName: skuName, productSKU: sku, lat: 0, lng: 0, order: 0, shoppingList: self.listId!)
            firebase.addProductInShoppingList(shoppingList: self.listId!, product: product!)
        }
        
        return product!
    }
    

    
}
