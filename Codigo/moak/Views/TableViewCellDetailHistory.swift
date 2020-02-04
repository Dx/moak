//
//  TableViewCell.swift
//  ClearStyle
//
//  Created by Audrey M Tam on 29/07/2014.
//  Copyright (c) 2014 Ray Wenderlich. All rights reserved.
//

import UIKit
import QuartzCore

// A protocol that the TableViewCell uses to inform its delegate of state change
protocol TableViewCellDetailHistoryDelegate {
    // indicates that the given item has been deleted
    func toDoItemDeleted(_ todoItem: Product)
    func toDoItemChecked(_ todoItem: Product)
    // Indicates that the edit process has begun for the given cell
    //    func cellDidBeginEditing(editingCell: TableViewCell)
    //    // Indicates that the edit process has committed for the given cell
    //    func cellDidEndEditing(editingCell: TableViewCell)
    //    func cellDidPriceEndEditing(editingCell: TableViewCell)
}

class TableViewCellDetailHistory: UITableViewCell, UITextFieldDelegate {
    
    let gradientLayer = CAGradientLayer()
    var originalCenter = CGPoint()
    var deleteOnDragRelease = false, completeOnDragRelease = false
    var tickLabel: UILabel, crossLabel: UILabel
    var productIsSelected = false
    let label: StrikeThroughText
    let priceText: UITextField
    
    var itemCompleteLayer = CALayer()
    // The object that acts as delegate for this cell.
    var delegate: TableViewCellDelegate?
    // The item that this cell renders.
    var toDoItem: Product? {
        didSet {
            if toDoItem!.unitaryPrice != 0 && toDoItem!.checked {
                let formatter = NumberFormatter()
                formatter.numberStyle = .currency
                let number = NSNumber(value:(toDoItem!.totalPrice))
                let stringPrice = formatter.string(from: number)
                priceText.text = "\(stringPrice!)"
            } else {
                priceText.text = ""
            }            
            
            if toDoItem!.quantity == 1 {
                label.text = "\(toDoItem!.productName)"
            } else {
                if toDoItem!.quantity.truncatingRemainder(dividingBy: 1) == 0 {
                    label.text = "\(Int(toDoItem!.quantity)) \(toDoItem!.productName)"
                } else {
                    label.text = "\(toDoItem!.quantity) \(toDoItem!.productName)"
                }
            }
            
            //label.strikeThrough =
            itemCompleteLayer.isHidden = !self.productIsSelected
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        
        //Create the textView for price
        priceText = UITextField()
        priceText.textColor = UIColor.black
        priceText.font = UIFont.boldSystemFont(ofSize: 15)
        priceText.backgroundColor = UIColor.clear
        priceText.textAlignment = .right
        priceText.keyboardType = .decimalPad
        priceText.isEnabled = false
        
        // create a label that renders the to-do item text
        label = StrikeThroughText(frame: CGRect.null)
        label.textColor = UIColor.black
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.backgroundColor = UIColor.clear
        label.keyboardType = .default
        label.keyboardAppearance = .light
        label.isEnabled = false
        
        // utility method for creating the contextual cues
        func createCueLabel() -> UILabel {
            let label = UILabel(frame: CGRect.null)
            label.textColor = UIColor.white
            label.font = UIFont.boldSystemFont(ofSize: 32.0)
            label.backgroundColor = UIColor.clear
            return label
        }
        
        // tick and cross labels for context cues
        tickLabel = createCueLabel()
        tickLabel.text = "\u{2713}"
        tickLabel.textAlignment = .right
        crossLabel = createCueLabel()
        crossLabel.text = "\u{2717}"
        crossLabel.textAlignment = .left
        
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        label.delegate = self
        priceText.delegate = self
        self.addDoneButtonOnKeyboard()
        label.contentVerticalAlignment = .center
        
        addSubview(label)
        addSubview(tickLabel)
        addSubview(crossLabel)
        addSubview(priceText)
        // remove the default blue highlight for selected cells
        selectionStyle = .none
        
        // gradient layer for cell
        gradientLayer.frame = bounds
        let color1 = UIColor(white: 1.0, alpha: 0.2).cgColor as CGColor
        let color2 = UIColor(white: 1.0, alpha: 0.1).cgColor as CGColor
        let color3 = UIColor.clear.cgColor as CGColor
        let color4 = UIColor(white: 0.0, alpha: 0.1).cgColor as CGColor
        gradientLayer.colors = [color1, color2, color3, color4]
        gradientLayer.locations = [0.0, 0.01, 0.95, 1.0]
        layer.insertSublayer(gradientLayer, at: 0)
        
        // add a layer that renders a green background when an item is complete
        itemCompleteLayer = CALayer(layer: layer)
        itemCompleteLayer.backgroundColor = UIColor(red: 0, green: 0.611, blue: 0.655, alpha: 0.65).cgColor
        itemCompleteLayer.isHidden = true
        layer.insertSublayer(itemCompleteLayer, at: 0)
        
        // add a pan recognizer
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(TableViewCell.handlePan(_:)))
        recognizer.delegate = self
        addGestureRecognizer(recognizer)
    }
    
    let kLabelLeftMargin: CGFloat = 15.0
    let kUICuesMargin: CGFloat = 10.0, kUICuesWidth: CGFloat = 50.0
    let kPriceLeftMargin: CGFloat = 80.0
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // ensure the gradient layer occupies the full bounds
        gradientLayer.frame = bounds
        itemCompleteLayer.frame = bounds
        label.frame = CGRect(x: kLabelLeftMargin, y: 0,
                             width: bounds.size.width - kLabelLeftMargin - kPriceLeftMargin, height: bounds.size.height)
        tickLabel.frame = CGRect(x: -kUICuesWidth - kUICuesMargin, y: 0,
                                 width: kUICuesWidth, height: bounds.size.height)
        crossLabel.frame = CGRect(x: bounds.size.width + kUICuesMargin, y: 0,
                                  width: kUICuesWidth, height: bounds.size.height)
        priceText.frame = CGRect(x: bounds.size.width - kPriceLeftMargin, y: 0,
                                 width: kPriceLeftMargin - kLabelLeftMargin, height: bounds.size.height)
    }
    
    //MARK: - Done button keyboard
    func addDoneButtonOnKeyboard() {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: bounds.size.width, height: 50))
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.done, target: self, action: #selector(priceText.endEditing(_:)))
        
        var items: [UIBarButtonItem]? = [UIBarButtonItem]()
        items?.append(flexSpace)
        items?.append(done)
        
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        priceText.inputAccessoryView=doneToolbar
    }
    
    //MARK: - horizontal pan gesture methods
    func handlePan(_ recognizer: UIPanGestureRecognizer) {
        // 1
        if recognizer.state == .began {
            // when the gesture begins, record the current center location
            originalCenter = center
        }
        // 2
        if recognizer.state == .changed {
            let translation = recognizer.translation(in: self)
            center = CGPoint(x: originalCenter.x + translation.x, y: originalCenter.y)
            // has the user dragged the item far enough to initiate a delete/complete?
            deleteOnDragRelease = frame.origin.x < -frame.size.width / 2.0
            completeOnDragRelease = frame.origin.x > frame.size.width / 2.0
            // fade the contextual clues
            let cueAlpha = fabs(frame.origin.x) / (frame.size.width / 2.0)
            tickLabel.alpha = cueAlpha
            crossLabel.alpha = cueAlpha
            // indicate when the user has pulled the item far enough to invoke the given action
            tickLabel.textColor = completeOnDragRelease ? UIColor.green : UIColor.white
            crossLabel.textColor = deleteOnDragRelease ? UIColor.red : UIColor.white
        }
        // 3
        if recognizer.state == .ended {
            let originalFrame = CGRect(x: 0, y: frame.origin.y,
                                       width: bounds.size.width, height: bounds.size.height)
            if deleteOnDragRelease {
                if delegate != nil && toDoItem != nil {
                    // notify the delegate that this item should be deleted
                    delegate!.toDoItemDeleted(toDoItem!)
                }
            } else if completeOnDragRelease {
                if toDoItem != nil {
                    if delegate != nil && toDoItem != nil {
                        // notify the delegate that this item should be deleted
                        delegate!.toDoItemChecked(toDoItem!)
                    }
                    
                }
                // label.strikeThrough = true
                itemCompleteLayer.isHidden = false
                UIView.animate(withDuration: 0.2, animations: {self.frame = originalFrame})
            } else {
                UIView.animate(withDuration: 0.2, animations: {self.frame = originalFrame})
            }
        }
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
            let translation = panGestureRecognizer.translation(in: superview!)
            if fabs(translation.x) > fabs(translation.y) {
                return true
            }
            return false
        }
        return false
    }
    
    // MARK: - UITextFieldDelegate Delegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // close the keyboard on Enter
        textField.resignFirstResponder()
        return false
    }
}
