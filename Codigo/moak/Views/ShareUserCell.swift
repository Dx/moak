//
//  ShareUserCell.swift
//  moak
//
//  Created by Dx on 06/09/16.
//  Copyright © 2016 Dx. All rights reserved.
//

import UIKit

protocol ShareUserCellDelegate {
    func changeSharing(userId: String, share: Bool)
}

class ShareUserCell: UITableViewCell {

    @IBOutlet weak var pictureView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var shareSwitch: UISwitch!
    var idUser = ""
    var delegate: ShareUserCellDelegate?
    
    @IBAction func changeSharing(_ sender: AnyObject) {
        if delegate != nil {
            delegate!.changeSharing(userId: self.idUser, share: self.shareSwitch.isOn)
        }
    }
}
