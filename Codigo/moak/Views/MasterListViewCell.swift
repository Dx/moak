//
//  MasterListViewCell.swift
//  moak
//
//  Created by Dx on 02/02/17.
//  Copyright © 2017 moak. All rights reserved.
//

import UIKit

protocol MasterListCellDelegate {
    func shoppingListToEdit(_ shoppingListId: String)
}

class MasterListViewCell: UITableViewCell {
    
    @IBOutlet weak var listNameLabel: UILabel!
    
    var shoppingListId = ""
    var delegate: MasterListCellDelegate?
    
    @IBAction func infoClicked(_ sender: Any) {
        if delegate != nil && shoppingListId != "" {
            delegate!.shoppingListToEdit(shoppingListId)
        }
    }
}
