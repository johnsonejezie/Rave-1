//
//  RavePayConfig.swift
//  RaveMobile
//
//  Created by Olusegun Solaja on 19/07/2017.
//  Copyright © 2017 Olusegun Solaja. All rights reserved.
//

import UIKit

class RavePayConfig: NSObject {
    var publicKey:String?
    var secretKey:String?
    var isStaging:Bool = true
    var themeColor:UIColor = UIColor(hex: "#382E4B")
    var secondaryThemeColor:UIColor = UIColor(hex: "#E1E2E2")
    var buttonThemeColor:UIColor = UIColor(hex: "#00A384")

    
    class func sharedConfig() -> RavePayConfig {
        
        struct Static {
            static let kbManager = RavePayConfig()
        }
        
        return Static.kbManager
    }
    
    

}
