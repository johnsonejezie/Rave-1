//
//  RavePayManager.swift
//  RaveMobile
//
//  Created by Olusegun Solaja on 19/07/2017.
//  Copyright © 2017 Olusegun Solaja. All rights reserved.
//

import UIKit

protocol RavePaymentManagerDelegate:class {
    func ravePaymentManagerDidCancel(_ ravePaymentManager:RavePayManager)
    func ravePaymentManager(_ ravePaymentManager:RavePayManager, didSucceedPaymentWithResult result:[String:AnyObject])
    func ravePaymentManager(_ ravePaymentManager:RavePayManager, didFailPaymentWithResult result:[String:AnyObject])
}

class RavePayManager: UIViewController,RavePayControllerDelegate {
    weak var delegate:RavePaymentManagerDelegate?
    var email:String?
    var transcationRef:String?
    var amount:String?
    var country:String = "NG"
    var currencyCode:String = "NGN"
    var narration:String?
    var savedCardsAllow = true
    
    
   
   
    
    func show(withController controller:UIViewController){
        guard let email = email else {
            fatalError("Email address is missing")
        }
        guard let transcationRef = transcationRef else {
            fatalError("transactionRef is missing")
        }
       
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let _controller = storyboard.instantiateViewController(withIdentifier: "raveNav") as! UINavigationController
        let raveController = _controller.childViewControllers[0] as! RavePayController
        raveController.email = email
        raveController.merchantTransRef = transcationRef
        raveController.amount = amount
        raveController.country = country
        raveController.delegate = self
        raveController.manager = self
        raveController.saveCardsAllow = savedCardsAllow
        raveController.currencyCode = currencyCode
        controller.present(_controller, animated: true, completion: nil)
    }
    
    func ravePay(_ ravePayController: RavePayController, didFailPaymentWithResult result: [String : AnyObject]) {
        self.delegate?.ravePaymentManager(self, didFailPaymentWithResult: result)
    }
    func ravePayDidCancel(_ ravePayController: RavePayController) {
        self.delegate?.ravePaymentManagerDidCancel(self)
    }
    func ravePay(_ ravePayController: RavePayController, didSucceedPaymentWithResult result: [String : AnyObject]) {
        self.delegate?.ravePaymentManager(self, didSucceedPaymentWithResult: result)
    }
    
}
