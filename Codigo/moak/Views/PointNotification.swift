//
//  PointNotification.swift
//  moak
//
//  Created by Dx on 29/07/17.
//  Copyright © 2017 moak. All rights reserved.
//

import UIKit
import Lottie

class PointNotification: UIView {

	
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        let crownAnimation = AnimationView.init(name: "crown")
		
		crownAnimation.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
		addSubview(crownAnimation)
		crownAnimation.play()
		crownAnimation.isHidden = true
    }
}
