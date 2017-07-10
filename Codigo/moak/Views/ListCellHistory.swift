//
//  ListCellHistoryTableViewCell.swift
//  moak
//
//  Created by Dx on 30/10/16.
//  Copyright © 2016 moak. All rights reserved.
//

import UIKit

class ListCellHistory: UITableViewCell {

    @IBOutlet weak var quantity: UILabel!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var unitPrice: UILabel!
    @IBOutlet weak var totalPrice: UILabel!
    
    var toDoItem: Product? {
        didSet {
            if toDoItem!.unitaryPrice != 0 && toDoItem!.checked {
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
                
            } else {
                quantity.text = ""
                totalPrice.text = ""
                unitPrice.text = ""
            }
            
            if name != nil {
                name.text = "\(toDoItem!.productName)"
            }
            
            if toDoItem!.checked {
                self.backgroundColor = UIColor(red: 0.811, green: 0.831, blue: 0.831, alpha: 1)
            } else {
                self.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
