//
//  StrikeThroughText.swift
//  ClearStyle
//
//  Created by Audrey M Tam on 29/07/2014.
//  Copyright (c) 2014 Ray Wenderlich. All rights reserved.
//

import UIKit
import QuartzCore

// A UILabel subclass that can optionally have a strikethrough.
class StrikeThroughText: UITextField {

    let strikeThroughLayer: CALayer
    
    let kStrikeOutThickness: CGFloat = 2.0
    
    // A Boolean value that determines whether the label should have a strikethrough.
    var strikeThrough : Bool {
        didSet {
            strikeThroughLayer.isHidden = !strikeThrough
            if strikeThrough {
                resizeStrikeThrough()
            }
        }
    }
    
    // MARK: - Init methods
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    override init(frame: CGRect) {
        strikeThroughLayer = CALayer()
        strikeThroughLayer.backgroundColor = UIColor.black.cgColor
        strikeThroughLayer.isHidden = true
        strikeThrough = false
        
        super.init(frame: frame)
        layer.addSublayer(strikeThroughLayer)
    }
    
    // MARK: - Methods
    
    override func layoutSubviews() {
        super.layoutSubviews()
        resizeStrikeThrough()
    }
    

    func resizeStrikeThrough() {
        if let text = text {
			if let textSize = text.size(withAttributes: [NSAttributedString.Key.font:font!]) as CGSize? {
                strikeThroughLayer.frame = CGRect(x: 0, y: bounds.size.height/2,
                    width: textSize.width, height: kStrikeOutThickness)
            }
        }
    }
}
