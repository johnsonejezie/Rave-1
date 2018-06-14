//
//  WebViewController.swift
//  SaveUP
//
//  Created by Segun Solaja on 5/31/17.
//  Copyright © 2017 Segun Solaja. All rights reserved.
//

import UIKit
import WebKit
import Shimmer
protocol RavePayWebControllerDelegate:class {
    func ravePay(_ webController:WebViewController, didSucceedPaymentWithResult result:[String:AnyObject])
    func ravePay(_ webController:WebViewController, didFailPaymentWithResult result:[String:AnyObject])
}

class WebViewController: UIViewController,WKNavigationDelegate,WKUIDelegate {
    weak var delegate:RavePayWebControllerDelegate?
    var email:String?
    lazy var webView:WKWebView = {
        let web = WKWebView()
        web.uiDelegate = self
        web.navigationDelegate = self
        web.translatesAutoresizingMaskIntoConstraints = false
        return web
    }()
    
    let loadingView:UIView = {
        let load = UIView()
        load.isHidden = true
        load.backgroundColor =  RavePayConfig.sharedConfig().themeColor
        load.translatesAutoresizingMaskIntoConstraints = false
        return  load
    }()
    
    let shimmerView:FBShimmeringView = {
        let shimmer = FBShimmeringView()
        shimmer.translatesAutoresizingMaskIntoConstraints = false
        return  shimmer
    }()
    
    var url:String?
    var flwRef:String?
    var isCard:Bool! = true
    var saveCard = false
    var cardNumber:String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(webView)
        self.view.addSubview(loadingView)
        loadingView.addSubview(shimmerView)
        setupConstraints()
        
        let loadingLabel = UILabel(frame: shimmerView.bounds)
        loadingLabel.textAlignment = .center
        loadingLabel.text = "Processing..."
        loadingLabel.font = UIFont.systemFont(ofSize: 24)
        loadingLabel.textColor = .white
        shimmerView.contentView = loadingLabel
        
        if let _URL = url{
            let ur = _URL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            if let _d = ur{
                let _url = URL(string: _d)
                if let theURL = _url {
                    let request = URLRequest(url: theURL)
                    webView.load(request)
                    webView.allowsBackForwardNavigationGestures = true
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.title = "Web"
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor : UIColor.white]
        self.navigationController?.navigationBar.barTintColor =  RavePayConfig.sharedConfig().themeColor
        self.navigationController?.navigationBar.tintColor = .white
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(),for: .default)
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
    }
    
    
    
    func popView(){
        _ = self.navigationController?.dismiss(animated: true, completion: nil)
    }
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        loadingView.isHidden = false
        shimmerView.isShimmering = true
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // let urlStr : NSString = url!.addingPercentEscapes(using: String.Encoding(rawValue: String.Encoding.utf8.rawValue))! as NSString
        print("doneLoading")
        print(webView.url!.absoluteString)
        if (webView.url!.absoluteString.contains("/complete") || webView.url!.absoluteString.contains("submitting_mock_form")){
            print("success page")
            self.queryTransaction()
        }else{
            loadingView.isHidden = true
            shimmerView.isShimmering = false
            
        }
        
    }
    
    func queryTransaction(){
        
        if let secret = RavePayConfig.sharedConfig().secretKey ,let  ref = flwRef{
            let param = ["SECKEY":secret,"flw_ref":ref]
            RavePayService.queryTransaction(param, resultCallback: { (result) in
                if let  status = result?["status"] as? String{
                    if (status == "success"){
                        if let data = result?["data"] as? [String:AnyObject] {
                            if let status = data["status"] as? String{
                                if status.contains("success"){
                                    DispatchQueue.main.async {
                                        self.loadingView.isHidden = true
                                        self.shimmerView.isShimmering = false
                                        print(result!)
                                        let callbackResult = ["status":"success","payload":result!] as [String : Any]
                                        if (self.saveCard){
                                            self.addOrUpdateCardToken(cardNumber: self.cardNumber!, data: result!,withFlwRef:ref )
                                        }
                                        self.delegate?.ravePay(self, didSucceedPaymentWithResult: callbackResult as [String : AnyObject])
                                        self.navigationController?.popViewController(animated: true)
                                        
                                    }
                                }else{
                                    if let meta = data["flwMeta"] as? [String:AnyObject]{
                                        if let message = meta["VBVRESPONSEMESSAGE"] as? String {
                                            showMessageDialog("Error", message: message, image: nil, axis: .horizontal, viewController: self, handler: {
                                                
                                            })
                                        }
                                    }
                                    
                                    
                                }
                            }
                            
                        }else{
                            DispatchQueue.main.async {
                                self.loadingView.isHidden = true
                                self.shimmerView.isShimmering = false
                                
                                let callbackResult = ["status":"error","payload":result!] as [String : Any]
                                self.delegate?.ravePay(self, didFailPaymentWithResult: callbackResult as [String : AnyObject])
                                self.navigationController?.popViewController(animated: true)
                                
                            }
                        }
                        
                    }else{
                        DispatchQueue.main.async {
                            self.loadingView.isHidden = true
                            self.shimmerView.isShimmering = false
                            
                            let callbackResult = ["status":"error","payload":result!] as [String : Any]
                            self.delegate?.ravePay(self, didFailPaymentWithResult: callbackResult as [String : AnyObject])
                            self.navigationController?.popViewController(animated: true)
                            
                        }
                    }
                }
            }, errorCallback: { (err) in
                if (err.containsIgnoringCase(find: "serialize") || err.containsIgnoringCase(find: "JSON")){
                    DispatchQueue.main.async {
                        self.delegate?.ravePay(self, didFailPaymentWithResult: ["error" : err as AnyObject])
                    }
                }else{
                    showMessageDialog("Error", message: err, image: nil, axis: .horizontal, viewController: self, handler: {
                        
                    })
                }
            })
        }
    }
    private func addOrUpdateCardToken(cardNumber:String,data:[String:AnyObject], withFlwRef ref:String){
        if let _data = data["data"] as? [String:AnyObject]{
            if let card = _data["card"] as? [String:AnyObject]{
                if let cards = card["card_tokens"] as? [[String:AnyObject]]{
                    let _cardToken = cards.last!
                    if let token = _cardToken["embedtoken"] as? String{
                        let first6 = cardNumber.substring(to: cardNumber.index(cardNumber.startIndex, offsetBy: 6))
                        let last4 = cardNumber.substring(from: cardNumber.index(cardNumber.endIndex, offsetBy: -4))
                        let cardDetails = ["card_token":token,"first6":first6,"last4":last4,"flwRef":ref]
                        if let cards  = UserDefaults.standard.object(forKey: "cards-\(email!)") as? [[String:String]]{
                            var theCards = cards
                            theCards = cards.filter({ (item) -> Bool in
                                let _first6 = item["first6"]!
                                return _first6 != first6
                            })
                            theCards.append(cardDetails)
                            UserDefaults.standard.set(theCards, forKey: "cards-\(email!)")
                            
                        }else{
                            UserDefaults.standard.set([cardDetails], forKey: "cards-\(email!)")
                            
                        }
                    }
                }
            }
        }
    }
    
    func setupConstraints(){
        webView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        webView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        webView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        shimmerView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        shimmerView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        shimmerView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        shimmerView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        
        loadingView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        loadingView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        loadingView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        loadingView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
}
