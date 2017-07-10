//
//  AddProductsVoiceController.swift
//  moak
//
//  Created by Dx on 03/10/16.
//  Copyright © 2016 moak. All rights reserved.
//

import UIKit
import Speech

class AddProductsVoiceController: UIViewController, SFSpeechRecognizerDelegate {

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "es-MX"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    var listController: ListsViewController?
    
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!
    
    @IBOutlet weak var startMic: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        startMic.isEnabled = false
        addButton.isEnabled = false
        
        speechRecognizer?.delegate = self
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            var isButtonEnabled = false
            
            switch authStatus {
            case .authorized:
                isButtonEnabled = true
                
            case .denied:
                isButtonEnabled = false
                print("User denied access to speech recognition")
                
            case .restricted:
                isButtonEnabled = false
                print("Speech recognition restricted on this device")
                
            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
            }
            
            OperationQueue.main.addOperation() {
                self.startMic.isEnabled = isButtonEnabled
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func beginClick(_ sender: AnyObject) {
        if audioEngine.isRunning {
            self.stopRecording()
        } else {
            startRecording()
            startMic.setTitle("Stop Recording", for: .normal)
        }
    }
    
    @IBAction func clickCancel(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func addClick(_ sender: AnyObject) {
        if audioEngine.isRunning {
            self.stopRecording()
        }
        
        if resultLabel.text != "" {
            
            let words = self.resultLabel.text?.components(separatedBy: ",")
            
            for word in words! {
                self.listController?.addNewProduct(productName: word.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        startMic.isEnabled = false
        startMic.setTitle("Start Recording", for: .normal)
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
                
                self.resultLabel.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
                self.addButton.isEnabled = true
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.startMic.isEnabled = true
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
        
        resultLabel.text = "Te escucho..."
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            startMic.isEnabled = true
        } else {
            startMic.isEnabled = false
        }
    }
}
