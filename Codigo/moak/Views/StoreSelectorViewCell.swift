//
//  StoreSelectorViewCell.swift
//  moak
//
//  Created by Dx on 19/11/16.
//  Copyright © 2016 moak. All rights reserved.
//

import UIKit

class StoreSelectorViewCell: UITableViewCell {
    
    @IBOutlet weak var storeName: UILabel!
    @IBOutlet weak var storeAddress: UILabel!
    @IBOutlet weak var storeDistance: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}
