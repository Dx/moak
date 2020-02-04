//
//  ListCellTableViewCell.swift
//  moak
//
//  Created by Dx on 30/09/16.
//  Copyright © 2016 Dx. All rights reserved.
//

import UIKit

class ListCell: UITableViewCell {

    @IBOutlet weak var quantity: UILabel!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var unitPrice: UILabel!
    @IBOutlet weak var totalPrice: UILabel!
    
    var capturedPrice = false
    var storeId = ""
    
    var toDoItem: Product? {
        didSet {
            
            setName()
            setChecked()
            
            if toDoItem!.unitaryPrice != 0 {
                capturedPrice = true
                self.setPrice()
            } else {
                capturedPrice = false
                if storeId != "" && toDoItem?.productSKU != "" {
                let firebase = FirebaseClient()
                    firebase.getLastPriceInStore(storeId: storeId, skuNumber: toDoItem!.productSKU) { (product: ProductComparer?) in
                        if let product = product {
                            self.toDoItem!.unitaryPrice = product.unitaryPrice
                            self.setPrice()
                        } else {
                            self.quantity.text = ""
                            self.totalPrice.text = ""
                            self.unitPrice.text = ""
                        }
                    }
                } else {
                    self.quantity.text = ""
                    self.totalPrice.text = ""
                    self.unitPrice.text = ""
                }
            }
        }
    }
    
    func setChecked() {
        if toDoItem!.checked {
            self.backgroundColor = UIColor(red: 0.811, green: 0.831, blue: 0.831, alpha: 1)
            
            let textRange = NSMakeRange(0, name.text!.count)
            let attributedText = NSMutableAttributedString(string: name.text!)
			attributedText.addAttribute(NSAttributedString.Key.strikethroughStyle , value: 2, range: textRange)
            // Add other attributes if needed
            self.name.attributedText = attributedText
        } else {
            self.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        }
    }
    
    func setName() {
        if name != nil {
            name.text = "\(toDoItem!.productName)"
        }
    }
    
    func setPrice() {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        let numberTotalPrice = NSNumber(value:toDoItem!.totalPrice)
        let stringTotalPrice = formatter.string(from: numberTotalPrice)!
        
        if totalPrice != nil {
            totalPrice.text = "\(stringTotalPrice)"
        }
        
        let numberUnitaryPrice = NSNumber(value:toDoItem!.unitaryPrice)
        let stringUnitaryPrice = formatter.string(from: numberUnitaryPrice)!
        
        if unitPrice != nil {
            unitPrice.text = "\(stringUnitaryPrice)"
        }
        
        let formatterQuantity = NumberFormatter()
        formatterQuantity.numberStyle = .decimal
        formatterQuantity.maximumFractionDigits = 3
        
        let quantityNumber = NSNumber(value:toDoItem!.quantity)
        let stringQuantity = formatterQuantity.string(from: quantityNumber)!
        
        if quantity != nil {
            quantity.text = "\(stringQuantity)"
        }
        
        if capturedPrice {
			let attrs = [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 15)]
            let boldString = NSMutableAttributedString(string:unitPrice.text!, attributes:attrs)
            self.unitPrice.attributedText = boldString
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
