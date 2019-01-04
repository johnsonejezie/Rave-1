//
//  Constants.swift
//  RaveMobile
//
//  Created by Segun Solaja on 10/5/15.
//  Copyright © 2015 Segun Solaja. All rights reserved.
//

import UIKit
import Alamofire

class Constants: NSObject {
    
    class func baseURL () -> String{
        // return "http://flw-pms-dev.eu-west-1.elasticbeanstalk.com"
        //return "https://ravesandboxapi.flutterwave.com"
        return "https://ravesandbox.azurewebsites.net"
    }
    class func liveBaseURL() -> String{
        //return "https://api.ravepay.co"
        return "https://raveapi.azurewebsites.net"
    }
    
    static let ghsMobileNetworks = [("MTN","Please Dial *170#, click on Pay and wait for instructions on the next screen",
                                     """
                                        Complete payment process
                                        1. Dial *170#
                                        2. Choose option: 7) Wallet
                                        3. Choose option: 3) My Approvals
                                        4. Enter your MOMO pin to retrieve your pending approval list
                                        5. Choose a pending transaction
                                        6. Choose option 1 to approve
                                        7. Tap button to continue)
                                        """),
                                    ("TIGO","Please Dial *501*5#, click on Pay and wait for instructions on the next screen",
                                     """
                                        Complete payment process
                                        1. Dial *501*5# to approve your transaction.
                                        2. Select the transaction to approve and click on send.
                                        3. Select YES to confirm your payment.
                                        """),
                                    ("VODAFONE","Please Dial *110# and follow the instructions to generate your transaction voucher.",
                                     """
                                        Complete payment process
                                        1. Dial  *110# to generate your transaction voucher.
                                        2. Select option) 6 to generate the voucher.
                                        3. Enter your PIN in next prompt.
                                        4. Input the voucher generated in the payment modal
                                        """),
                                    ("AIRTEL","","")]
    
    
    class func isConnectedToInternet() ->Bool {
        return NetworkReachabilityManager()!.isReachable
    }
    
    
    class func relativeURL()->Dictionary<String,String>{
        return [
            "CHARGE_CARD" :"/flwv3-pug/getpaidx/api/charge",
            "VALIDATE_CARD_OTP" :"/flwv3-pug/getpaidx/api/validatecharge",
            "VALIDATE_ACCOUNT_OTP":"/flwv3-pug/getpaidx/api/validate",
            "BANK_LIST":"/flwv3-pug/getpaidx/api/flwpbf-banks.js?json=1",
            "CHARGE_WITH_TOKEN":"/flwv3-pug/getpaidx/api/tokenized/charge",
            "QUERY_TRANSACTION":"/flwv3-pug/getpaidx/api/verify",
            "QUERY_TRANSACTION_V2":"/flwv3-pug/getpaidx/api/v2/verify",
            "SAVED_CARDS_LOOKUP":"/v2/gpx/users/lookup",
            "FEE":"/flwv3-pug/getpaidx/api/fee"
        ]
    }
    
    
    class func headerConstants(_ headerParam:Dictionary<String,String>)->Dictionary<String,String> {
        
        return  headerParam
        
    }
    
    
    
}
