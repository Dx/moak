//
//  MagicListCell.swift
//  moak
//
//  Created by Dx on 30/05/17.
//  Copyright © 2017 moak. All rights reserved.
//

import UIKit

class MagicListCell: UITableViewCell {
    
    @IBOutlet weak var productName: UILabel!
    
    @IBOutlet weak var lastShopped: UILabel!
    @IBOutlet weak var nextShopped: UILabel!
    
    @IBOutlet weak var averageDays: UILabel!
    @IBOutlet weak var lastPrice: UILabel!
    
    @IBOutlet weak var progressBar: UIProgressView!

    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        self.progressBar.transform = self.progressBar.transform.scaledBy(x: 1, y: 2)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }

}
