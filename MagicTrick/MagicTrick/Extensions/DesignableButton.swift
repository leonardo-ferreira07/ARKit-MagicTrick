//
//  DesignableButton.swift
//  MagicTrick
//
//  Created by Leonardo Vinicius Kaminski Ferreira on 07/12/17.
//  Copyright © 2017 Leonardo Vinicius Kaminski Ferreira. All rights reserved.
//

import UIKit

@IBDesignable
open class DesignableButton: UIButton {
    
    @IBInspectable open var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
            layer.masksToBounds = true
        }
    }
    
}

