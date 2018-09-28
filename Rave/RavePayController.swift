//
//  RavePayController.swift
//  RaveMobile
//
//  Created by Olusegun Solaja on 18/07/2017.
//  Copyright © 2017 Olusegun Solaja. All rights reserved.
//

import UIKit
//import IQKeyboardManagerSwift
import KVNProgress
import SwiftValidator
import BSErrorMessageView
import PopupDialog
import CreditCardValidator

protocol RavePayControllerDelegate:class {
    func ravePayDidCancel(_ ravePayController:RavePayController)
    func ravePay(_ ravePayController:RavePayController, didSucceedPaymentWithResult result:[String:AnyObject])
    func ravePay(_ ravePayController:RavePayController, didFailPaymentWithResult result:[String:AnyObject])
}

public enum PaymentMethods: String {
    case card = "CARD", account = "ACCOUNT", paypal = "PAYPAL", mpesa = "MPESA" , mobileMoney = "MOBILE MONEY"
}

public enum PaymentRoute: String {
    case card = "card", existingCard = "existing_card", bank = "bank", paypal = "paypal",mpesa = "mpesa", mobileMoney = "mobileMoney"
}

class RavePayController: UIViewController,RavePayWebControllerDelegate,OTPControllerDelegate,UIPickerViewDelegate,UIPickerViewDataSource,UITextFieldDelegate,ValidationDelegate{
    weak var delegate:RavePayControllerDelegate?
    var manager:RavePayManager!
    @IBOutlet var carView: UIView!
    @IBOutlet var pinView: UIView!
    @IBOutlet var bankView: UIView!
    @IBOutlet var paypalView: UIView!
    @IBOutlet var mpesaContainer: UIView!
    @IBOutlet weak var mpesaBusinessNumber: UILabel!
    
    @IBOutlet var mobileMoneyContainer: UIView!
    @IBOutlet weak var mobileMoneyPhoneNumber: VSTextField!
    
    @IBOutlet weak var mobileMoneyPayButton: UIButton!
    @IBOutlet weak var mpesaPhoneNumber: VSTextField!
    @IBOutlet weak var mpesaPayButton: UIButton!
    @IBOutlet weak var mpesaAccountNumber: UILabel!
    @IBOutlet var billingAddressView: UIView!
    @IBOutlet weak var billingAddress: VSTextField!
    @IBOutlet weak var billingAddressCity: VSTextField!
    @IBOutlet weak var billingAddressState: VSTextField!
    
    @IBOutlet weak var billingAddressCountry: VSTextField!
    @IBOutlet weak var zipCode: VSTextField!
    
    @IBOutlet weak var billingAddressContinueButton: UIButton!
    @IBOutlet var billingCodeView: UIView!
    @IBOutlet weak var billingCodeTextField: UITextField!
    @IBOutlet weak var billingButton: UIButton!
    @IBOutlet weak var dobTextField: UITextField!
    
    @IBOutlet weak var payPalButton: UIButton!
    @IBOutlet weak var pinTextField: UITextField!
    @IBOutlet weak var cardNumber: VSTextField!
    @IBOutlet weak var cardPayButton: UIButton!
    @IBOutlet weak var bankPayButton: UIButton!
    @IBOutlet weak var savedCardsButton: UIButton!
    @IBOutlet weak var pinButton: UIButton!
    @IBOutlet weak var saveCardSwitch: UISwitch!
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var cvv: VSTextField!
    @IBOutlet weak var expiry: VSTextField!
    
    @IBOutlet weak var amountTextField: VSTextField!
    @IBOutlet weak var accountAmountTextField: UITextField!
    @IBOutlet weak var accountBank: UITextField!
    @IBOutlet weak var accountNumber: UITextField!
    @IBOutlet weak var phoneNUmber: UITextField!
    let creditCardValidator = CreditCardValidator()
    @IBOutlet weak var savedCardConstants: NSLayoutConstraint!
    var cardIcon:UIButton!
    var cardIcV:UIView!
    var bankPicker:UIPickerView!
    var banks:[Bank]? = [] {
        didSet{
            bankPicker.reloadAllComponents()
        }
    }
    var blacklistBanks:[String]?
    var isCardSaved = true
    var selectedBank:Bank?
    var selectedCard:[String:String]? = [:] {
        didSet{
            cardSavedTable.reloadData()
        }
    }
    let identifier = Bundle(identifier: "flutterwave.Rave")
    @IBOutlet weak var containerHeight: NSLayoutConstraint!
    @IBOutlet weak var cardSavedDoneButton: UIButton!
    
    @IBOutlet weak var cardSavedTable: UITableView!
    @IBOutlet weak var cardSavedBar: UIView!
    var bodyParam:Dictionary<String,Any>?
    var merchantTransRef:String? = "RaveMobileiOS"
    var email:String? = "segun.solaja@gmail.com"
    var amount:String? = "500"
    var paymentPlan:Int?
    var currencyCode:String = "NGN"
    var country:String!
    var narration:String?
    var saveCardsAllow = false
    
    
    let validator = Validator()
    var isInCardMode = true
    var isPinMode = false
    var isMpesaMode = false
    var isMobileMoneyMode = false
    var isBillingCodeMode = false
    var isBillingAddressMode = false
    var segcontrol:CustomSegementControl!
    var paymentRoute:PaymentRoute!
    var selectedIndex:Int!
    var paymentMethods:[PaymentMethods] = [.card,.account,.paypal]
    var supportedPaymentMethods:[PaymentMethods] = []
    var meta:[[String:String]]?
    var subAccounts:[SubAccount]?
    var cardList:[[String:String]]? {
        didSet{
            cardSavedTable.reloadData()
        }
    }
    
    @IBOutlet var savedCardPopup: UIView!
    
    private var overLayView:UIView!
    private var billingOverLayView:UIView!
    private var billingAddressOverLayView:UIView!
    private var savedCardOverLayView:UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        //        IQKeyboardManager.sharedManager().enable = false
        configureView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func  configureView(){
//        let count = supportedPaymentMethods.count
//        if count > 0 {
//            self.paymentMethods = supportedPaymentMethods
//        }
        self.paymentMethods = self.getPaymentMethodsForCurrency()
        self.paymentMethods.forEach({ (item) in
            print( item.rawValue)
        })
        
        cardList =  UserDefaults.standard.object(forKey: "cards-\(self.email!)") as? [[String:String]]
        
        cardSavedTable.delegate = self
        cardSavedTable.dataSource = self
        cardSavedTable.tableFooterView = UIView(frame: .zero)
        
        containerView.addSubview(carView)
        containerView.addSubview(bankView)
        containerView.addSubview(paypalView)
        containerView.addSubview(mpesaContainer)
         containerView.addSubview(mobileMoneyContainer)
        overLayView = UIView(frame:self.view.frame)
        overLayView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        overLayView.isHidden = true
        
        billingOverLayView = UIView(frame:self.view.frame)
        billingOverLayView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        billingOverLayView.isHidden = true
        
        billingAddressOverLayView = UIView(frame:self.view.frame)
        billingAddressOverLayView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        billingAddressOverLayView.isHidden = true
        
        let dp = UIDatePicker()
        dp.datePickerMode = .date
        dobTextField.inputView = dp
        dp.addTarget(self, action: #selector(dobPickerValueChanged), for: .valueChanged)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideOvelay))
        overLayView.addGestureRecognizer(tap)
        overLayView.isUserInteractionEnabled = true
        pinView.center = CGPoint(x: overLayView.center.x, y: overLayView.center.y - 100)
        pinView.layer.cornerRadius = 6
        
        self.view.addSubview(overLayView)
        
        overLayView.addSubview(pinView)
        
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(hideBillingOvelay))
        billingOverLayView.addGestureRecognizer(tap2)
        billingOverLayView.isUserInteractionEnabled = true
        billingCodeView.center = CGPoint(x: billingOverLayView.center.x, y: billingOverLayView.center.y - 100)
        billingCodeView.layer.cornerRadius = 6
        
        self.view.addSubview(billingOverLayView)
        
        let tap3 = UITapGestureRecognizer(target: self, action: #selector(hideBillingOvelay))
        billingAddressOverLayView.addGestureRecognizer(tap3)
        billingAddressOverLayView.isUserInteractionEnabled = true
        billingAddressView.center = CGPoint(x: billingAddressOverLayView.center.x, y: billingAddressOverLayView.center.y - 100)
        billingAddressView.layer.cornerRadius = 6
        
        self.view.addSubview(billingAddressOverLayView)
        billingAddressOverLayView.addSubview(billingAddressView)
        
        billingOverLayView.addSubview(billingCodeView)
        
        
        savedCardOverLayView =  UIView(frame:self.view.frame)
        savedCardOverLayView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        savedCardOverLayView.isHidden = true
        
        
        savedCardOverLayView.isUserInteractionEnabled = true
        savedCardOverLayView.addSubview(savedCardPopup)
        savedCardPopup.translatesAutoresizingMaskIntoConstraints = false
        setupCardPopup()
        cardSavedDoneButton.addTarget(self, action: #selector(doneButtonPressed), for: .touchUpInside)
        self.view.addSubview(savedCardOverLayView)
        
        bankView.isHidden = true
        cardSavedBar.backgroundColor = RavePayConfig.sharedConfig().themeColor
        cardPayButton.layer.cornerRadius =  cardPayButton.frame.height / 2
        cardPayButton.backgroundColor = RavePayConfig.sharedConfig().buttonThemeColor
        pinButton.layer.cornerRadius =  pinButton.frame.height / 2
        billingAddressContinueButton.layer.cornerRadius =  billingAddressContinueButton.frame.height / 2
        billingButton.layer.cornerRadius =  billingButton.frame.height / 2
        bankPayButton.layer.cornerRadius =  bankPayButton.frame.height / 2
        bankPayButton.backgroundColor = RavePayConfig.sharedConfig().buttonThemeColor
        savedCardsButton.layer.cornerRadius =  savedCardsButton.frame.height / 2
        savedCardsButton.layer.borderWidth = 0.5
        savedCardsButton.layer.borderColor =  RavePayConfig.sharedConfig().themeColor.cgColor
        savedCardsButton.setTitleColor( RavePayConfig.sharedConfig().themeColor, for: .normal)
        
        let amountIcon = UIButton(type: .system)
        amountIcon.tintColor =  RavePayConfig.sharedConfig().themeColor
        
        amountIcon.setImage(UIImage(named: "new_card", in: identifier ,compatibleWith: nil), for: .normal)
        amountIcon.frame = CGRect(x: 12, y: 5, width: 20, height: 15)
        let amountIcV = UIView(frame: CGRect(x: 0, y: 0, width: 45, height: 30))
        amountIcV.addSubview(amountIcon)
        styleTextField(amountTextField,leftView: amountIcV)
        
        let accountAmountIcon = UIButton(type: .system)
        accountAmountIcon.tintColor =  RavePayConfig.sharedConfig().themeColor
        accountAmountIcon.setImage(UIImage(named: "new_card", in: identifier ,compatibleWith: nil), for: .normal)
        accountAmountIcon.frame = CGRect(x: 12, y: 5, width: 20, height: 15)
        let accountAmountIcV = UIView(frame: CGRect(x: 0, y: 0, width: 45, height: 30))
        accountAmountIcV.addSubview(accountAmountIcon)
        styleTextField(accountAmountTextField,leftView: accountAmountIcV)
        
        
        let billingIcon = UIButton(type: .system)
        billingIcon.tintColor =  RavePayConfig.sharedConfig().themeColor
        billingIcon.setImage(UIImage(named: "calender", in: identifier ,compatibleWith: nil), for: .normal)
        billingIcon.frame = CGRect(x: 12, y: 5, width: 20, height: 20)
        let billingIcV = UIView(frame: CGRect(x: 0, y: 0, width: 45, height: 30))
        billingIcV.addSubview(billingIcon)
        
        styleTextField(billingCodeTextField,leftView: billingIcV)
        
        let pinIcon = UIButton(type: .system)
        pinIcon.tintColor =  RavePayConfig.sharedConfig().themeColor
        pinIcon.setImage(UIImage(named: "calender", in: identifier ,compatibleWith: nil), for: .normal)
        pinIcon.frame = CGRect(x: 12, y: 5, width: 20, height: 20)
        let pinIcV = UIView(frame: CGRect(x: 0, y: 0, width: 45, height: 30))
        pinIcV.addSubview(pinIcon)
        
        styleTextField(pinTextField,leftView: pinIcV)
        
        let billingAddressIcon = UIButton(type: .system)
        billingAddressIcon.tintColor =  RavePayConfig.sharedConfig().themeColor
        billingAddressIcon.setImage(UIImage(named: "new_card", in: identifier ,compatibleWith: nil), for: .normal)
        billingAddressIcon.frame = CGRect(x: 12, y: 5, width: 20, height: 20)
        let billingAddressIcV = UIView(frame: CGRect(x: 0, y: 0, width: 45, height: 30))
        billingAddressIcV.addSubview(billingAddressIcon)
        
        styleTextField(billingAddress,leftView: nil)
        
        let billingAddressCountryIcon = UIButton(type: .system)
        billingAddressCountryIcon.tintColor =  RavePayConfig.sharedConfig().themeColor
        billingAddressCountryIcon.setImage(UIImage(named: "new_card", in: identifier ,compatibleWith: nil), for: .normal)
        billingAddressCountryIcon.frame = CGRect(x: 12, y: 5, width: 20, height: 20)
        let billingAddressCountryIcV = UIView(frame: CGRect(x: 0, y: 0, width: 45, height: 30))
        billingAddressCountryIcV.addSubview(billingAddressCountryIcon)
        
        styleTextField(billingAddressCountry,leftView: nil)
        
        let billingAddressZipIcon = UIButton(type: .system)
        billingAddressZipIcon.tintColor =  RavePayConfig.sharedConfig().themeColor
        billingAddressZipIcon.setImage(UIImage(named: "", in: identifier ,compatibleWith: nil), for: .normal)
        billingAddressZipIcon.frame = CGRect(x: 12, y: 5, width: 20, height: 20)
        let billingAddressZipIcV = UIView(frame: CGRect(x: 0, y: 0, width: 45, height: 30))
        billingAddressZipIcV.addSubview(billingAddressZipIcon)
        
        styleTextField(zipCode,leftView: nil)
        
        let billingAddressStateIcon = UIButton(type: .system)
        billingAddressStateIcon.tintColor =  RavePayConfig.sharedConfig().themeColor
        billingAddressStateIcon.setImage(UIImage(named: "new_card", in: identifier ,compatibleWith: nil), for: .normal)
        billingAddressStateIcon.frame = CGRect(x: 12, y: 5, width: 20, height: 20)
        let billingAddressStateIcV = UIView(frame: CGRect(x: 0, y: 0, width: 45, height: 30))
        billingAddressStateIcV.addSubview(billingAddressStateIcon)
        
        styleTextField(billingAddressState,leftView:nil)
        
        let billingAddressCityIcon = UIButton(type: .system)
        billingAddressCityIcon.tintColor =  RavePayConfig.sharedConfig().themeColor
        billingAddressCityIcon.setImage(UIImage(named: "new_card", in: identifier ,compatibleWith: nil), for: .normal)
        billingAddressCityIcon.frame = CGRect(x: 12, y: 5, width: 20, height: 20)
        let billingAddressCityIcV = UIView(frame: CGRect(x: 0, y: 0, width: 45, height: 30))
        billingAddressCityIcV.addSubview(billingAddressCityIcon)
        
        styleTextField(billingAddressCity,leftView: nil)
        
        cardIcon = UIButton(type: .system)
        cardIcon.tintColor =  RavePayConfig.sharedConfig().themeColor
        cardIcon.setImage(UIImage(named: "new_card", in: identifier ,compatibleWith: nil), for: .normal)
        cardIcon.frame = CGRect(x: 12, y: 5, width: 20, height: 15)
        cardIcV = UIView(frame: CGRect(x: 0, y: 0, width: 45, height: 30))
        cardIcV.addSubview(cardIcon)
        styleTextField(cardNumber,leftView: cardIcV)
        cardNumber.setFormatting("xxxx xxxx xxxx xxxx xxxx", replacementChar: "x")
        cardNumber.addTarget(self, action: #selector(textFieldDidChange(textField:)), for: .editingChanged)
        
        let cvvIcon = UIButton(type: .system)
        cvvIcon.tintColor =  RavePayConfig.sharedConfig().themeColor
        cvvIcon.setImage(UIImage(named: "new_card", in: identifier ,compatibleWith: nil), for: .normal)
        cvvIcon.frame = CGRect(x: 12, y: 8, width: 20, height: 15)
        let cvvIcV = UIView(frame: CGRect(x: 0, y: 0, width: 45, height: 30))
        cvvIcV.addSubview(cvvIcon)
        styleTextField(cvv,leftView: cvvIcV)
        cvv.setFormatting("xxxx", replacementChar: "x")
        cvv.isSecureTextEntry = true
        
        let expIcon = UIButton(type: .system)
        expIcon.tintColor =  RavePayConfig.sharedConfig().themeColor
        expIcon.setImage(UIImage(named: "calender", in: identifier ,compatibleWith: nil), for: .normal)
        expIcon.frame = CGRect(x: 12, y: 5, width: 20, height: 20)
        let expIcV = UIView(frame: CGRect(x: 0, y: 0, width: 45, height: 30))
        expIcV.addSubview(expIcon)
        styleTextField(expiry,leftView: expIcV)
        expiry.placeholder = "MM/YY"
        expiry.setFormatting("xx/xx", replacementChar: "x")
        
        
        let bankIcon = UIButton(type: .system)
        bankIcon.tintColor =  RavePayConfig.sharedConfig().themeColor
        bankIcon.setImage(UIImage(named: "bank_icon", in: identifier ,compatibleWith: nil), for: .normal)
        bankIcon.frame = CGRect(x: 12, y: 5, width: 20, height: 20)
        let bankIcV = UIView(frame: CGRect(x: 0, y: 0, width: 45, height: 30))
        bankIcV.addSubview(bankIcon)
        styleTextField(accountBank,leftView: bankIcV)
        
        let dobIcon = UIButton(type: .system)
        dobIcon.tintColor =  RavePayConfig.sharedConfig().themeColor
        dobIcon.setImage(UIImage(named: "new_card", in: identifier ,compatibleWith: nil), for: .normal)
        dobIcon.frame = CGRect(x: 12, y: 5, width: 20, height: 15)
        let dobIcV = UIView(frame: CGRect(x: 0, y: 0, width: 45, height: 30))
        dobIcV.addSubview(dobIcon)
        styleTextField(dobTextField,leftView: dobIcV)
        
        bankPicker = UIPickerView()
        bankPicker.autoresizingMask  = [.flexibleWidth , .flexibleHeight]
        bankPicker.showsSelectionIndicator = true
        bankPicker.delegate = self
        bankPicker.dataSource = self
        bankPicker.tag = 12
        self.accountBank.delegate = self
        
        self.accountBank.inputView = bankPicker
        
        
        let accNumberIcon = UIButton(type: .system)
        accNumberIcon.tintColor =  RavePayConfig.sharedConfig().themeColor
        accNumberIcon.setImage(UIImage(named: "new_card", in: identifier ,compatibleWith: nil), for: .normal)
        accNumberIcon.frame = CGRect(x: 12, y: 5, width: 20, height: 15)
        let accNumberIcV = UIView(frame: CGRect(x: 0, y: 0, width: 45, height: 30))
        accNumberIcV.addSubview(accNumberIcon)
        styleTextField(accountNumber,leftView:accNumberIcV)
        accountNumber.delegate = self
        
        let phoneNumberIcon = UIButton(type: .system)
        phoneNumberIcon.tintColor =  RavePayConfig.sharedConfig().themeColor
        phoneNumberIcon.setImage(UIImage(named: "phone", in: identifier ,compatibleWith: nil), for: .normal)
        phoneNumberIcon.frame = CGRect(x: 12, y: 5, width: 20, height: 20)
        let phoneNumberIcV = UIView(frame: CGRect(x: 0, y: 0, width: 45, height: 30))
        phoneNumberIcV.addSubview(phoneNumberIcon)
        styleTextField(phoneNUmber,leftView:phoneNumberIcV)
        phoneNUmber.delegate = self
        
        
        let mpesaPhoneNumberIcon = UIButton(type: .system)
        mpesaPhoneNumberIcon.tintColor =  RavePayConfig.sharedConfig().themeColor
        mpesaPhoneNumberIcon.setImage(UIImage(named: "phone", in: identifier ,compatibleWith: nil), for: .normal)
        mpesaPhoneNumberIcon.frame = CGRect(x: 12, y: 5, width: 20, height: 20)
        let mpesaPhonephoneNumberIcV = UIView(frame: CGRect(x: 0, y: 0, width: 45, height: 30))
        mpesaPhonephoneNumberIcV.addSubview(mpesaPhoneNumberIcon)
        styleTextField(mpesaPhoneNumber,leftView:mpesaPhonephoneNumberIcV)
        
        
        let mobileMoneyPhoneNumberIcon = UIButton(type: .system)
        mobileMoneyPhoneNumberIcon.tintColor =  RavePayConfig.sharedConfig().themeColor
        mobileMoneyPhoneNumberIcon.setImage(UIImage(named: "phone", in: identifier ,compatibleWith: nil), for: .normal)
        mobileMoneyPhoneNumberIcon.frame = CGRect(x: 12, y: 5, width: 20, height: 20)
        let mobileMoneyPhonephoneNumberIcV = UIView(frame: CGRect(x: 0, y: 0, width: 45, height: 30))
        mobileMoneyPhonephoneNumberIcV.addSubview(mobileMoneyPhoneNumberIcon)
        styleTextField(mobileMoneyPhoneNumber,leftView:mobileMoneyPhonephoneNumberIcV)
        
        phoneNUmber.delegate = self
        
        containerView.layer.cornerRadius = 6
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor =  RavePayConfig.sharedConfig().secondaryThemeColor.cgColor
        //  IQKeyboardManager.sharedManager().enable = true
        
        let barButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissV))
        self.navigationItem.leftBarButtonItem = barButton
        
        
        cardPayButton.addTarget(self, action: #selector(cardPayButtonTapped), for: .touchUpInside)
        setPayButtonTitle(code: currencyCode, button: cardPayButton)
        bankPayButton.addTarget(self, action: #selector(bankPayButtonTapped), for: .touchUpInside)
        setPayButtonTitle(code: currencyCode, button: bankPayButton)
        
        payPalButton.layer.cornerRadius =  payPalButton.frame.height / 2
        payPalButton.layer.borderWidth = 0.5
        payPalButton.layer.borderColor =  RavePayConfig.sharedConfig().themeColor.cgColor
        payPalButton.backgroundColor = RavePayConfig.sharedConfig().buttonThemeColor
        payPalButton.addTarget(self, action: #selector(doPayPalButtonTapped), for: .touchUpInside)
        setPayButtonTitle(code: currencyCode, button: payPalButton)
        
        mpesaPayButton.layer.cornerRadius =  mpesaPayButton.frame.height / 2
        mpesaPayButton.layer.borderWidth = 0.5
        mpesaPayButton.layer.borderColor =  RavePayConfig.sharedConfig().themeColor.cgColor
        mpesaPayButton.backgroundColor = RavePayConfig.sharedConfig().buttonThemeColor
        mpesaPayButton.addTarget(self, action: #selector(mpesaPayButtonTapped), for: .touchUpInside)
        setPayButtonTitle(code: currencyCode, button: mpesaPayButton)
        
        mobileMoneyPayButton.layer.cornerRadius =  mobileMoneyPayButton.frame.height / 2
        mobileMoneyPayButton.layer.borderWidth = 0.5
        mobileMoneyPayButton.layer.borderColor =  RavePayConfig.sharedConfig().themeColor.cgColor
        mobileMoneyPayButton.backgroundColor = RavePayConfig.sharedConfig().buttonThemeColor
        mobileMoneyPayButton.addTarget(self, action: #selector(mobileMoneyPayButtonTapped), for: .touchUpInside)
        setPayButtonTitle(code: currencyCode, button: mobileMoneyPayButton)
        
        pinButton.addTarget(self, action: #selector(pinButtonTapped), for: .touchUpInside)
        pinButton.backgroundColor = RavePayConfig.sharedConfig().buttonThemeColor
        
        billingAddressContinueButton.addTarget(self, action: #selector(billingAddressButtonTapped), for: .touchUpInside)
        billingAddressContinueButton.backgroundColor = RavePayConfig.sharedConfig().buttonThemeColor
        
        billingButton.addTarget(self, action: #selector(billingButtonTapped), for: .touchUpInside)
        billingButton.backgroundColor = RavePayConfig.sharedConfig().buttonThemeColor
        
        //required fields
        validator.registerField(self.cardNumber, errorLabel: nil, rules: [RequiredRule(message:"Card number is required")])
        cardNumber.delegate = self
        validator.registerField(self.expiry, errorLabel: nil, rules: [RequiredRule(message:"Expiry is required")])
        expiry.delegate = self
        validator.registerField(self.cvv, errorLabel: nil, rules: [RequiredRule(message:"Cvv is required")])
        cvv.delegate = self
        pinTextField.delegate = self
        
        saveCardSwitch.onTintColor =  RavePayConfig.sharedConfig().themeColor
        if let count = cardList?.count{
            if(count > 0){
                isCardSaved = true
            }else{
                isCardSaved = false
            }
        }else{
            isCardSaved = false
        }
        determineCardContainerHeight()
        
        savedCardsButton.addTarget(self, action: #selector(showSavedCards), for: .touchUpInside)
        
        
    }
    
    func getPaymentMethodsForCurrency() -> [PaymentMethods]{
        switch (currencyCode) {
        case "NGN":
//            if supportedPaymentMethods.count > 0{
//                return supportedPaymentMethods.filter({ (item) -> Bool in
//                    return item == .mpesa
//                })
//            }else{
                return  [.card,.account]
            //
        //}
        case "KES":
            return  [.card,.mpesa]
        case "GHS":
            return  [.card,.mobileMoney]
        default:
            return  [.card,.account]
        }
    }
    
    @objc func dobPickerValueChanged(_ sender: UIDatePicker){
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "ddMMyyyy"
        let selectedDate: String = dateFormatter.string(from: sender.date)
        self.dobTextField.text = selectedDate
    }
    
    @objc private func setupCardPopup(){
        savedCardPopup.leftAnchor.constraint(equalTo: savedCardOverLayView.leftAnchor).isActive = true
        savedCardPopup.rightAnchor.constraint(equalTo: savedCardOverLayView.rightAnchor).isActive = true
        savedCardPopup.bottomAnchor.constraint(equalTo: savedCardOverLayView.bottomAnchor).isActive = true
        savedCardPopup.heightAnchor.constraint(equalToConstant: 300).isActive = true
    }
    
    private func setPayButtonTitle(code:String, button:UIButton){
        button.setTitle("PAY \(amount!.toCountryCurrency(code:  self.currencyCode))", for: .normal)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavBar()
        getBanks()
    }
    @objc func hideOvelay(){
        self.overLayView.isHidden = true
        isPinMode = false
        validator.unregisterField(pinTextField)
    }
    @objc func hideBillingOvelay(){
        self.billingOverLayView.isHidden = true
        isBillingCodeMode = false
        validator.unregisterField(billingCodeTextField)
    }
    @objc func hideBillingAddressOvelay(){
        self.billingAddressOverLayView.isHidden = true
        isBillingAddressMode = false
        validator.unregisterField(billingAddressCountry)
        validator.unregisterField(billingAddressState)
        validator.unregisterField(billingAddress)
        validator.unregisterField(zipCode)
        validator.unregisterField(billingAddressCity)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        carView.frame = containerView.bounds
        bankView.frame = containerView.bounds
        paypalView.frame = containerView.bounds
        mpesaContainer.frame = containerView.bounds
        mobileMoneyContainer.frame = containerView.bounds
    }
    @objc func doneButtonPressed(){
        self.hideCardOvelay()
        if let ref  = selectedCard?["flwRef"]{
            KVNProgress.show(withStatus: "Processing...")
            self.queryTransaction(flwRef: ref)
        }
    }
    func hideCardOvelay(){
        self.savedCardOverLayView.isHidden = true
    }
    
    @objc func dismissV(){
        delegate?.ravePayDidCancel(self)
        NotificationCenter.default.post(name: NSNotification.Name("cancelled"), object: nil)
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    private func setupNavBar(){
        self.navigationController?.navigationBar.barTintColor =  RavePayConfig.sharedConfig().themeColor
        self.navigationController?.navigationBar.tintColor = .white
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(),for: .default)
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
        self.navigationItem.titleView = getTitleView()
    }
    
    private func getTitleView() -> CustomSegementControl{
        segcontrol = CustomSegementControl(frame: CGRect(x: 0, y: 0, width: 250, height: 40))
        let options = paymentMethods.map({ (item) -> String in
            return item.rawValue
        })
        segcontrol.buttonTitles = options.joined(separator: ",")
        //segcontrol.buttonTitles = "CARD,ACCOUNT"
        segcontrol.addTarget(self, action:#selector(segmentedControlTapped), for: .valueChanged)
        segcontrol.bgColor = UIColor.white.withAlphaComponent(0.7)
        let button = segcontrol.buttons[selectedIndex]
        segcontrol.buttonTapped(button)
        segcontrol.clipsToBounds = true
        return segcontrol
    }
    
    @objc func segmentedControlTapped(_ sender : CustomSegementControl){
        self.view.endEditing(true)
        self.selectedIndex = sender.selectedIndex
        let paymentOption = self.paymentMethods[sender.selectedIndex]
        switch paymentOption {
        case .card:
            carView.isHidden = false
            bankView.isHidden = true
            paypalView.isHidden = true
            mpesaContainer.isHidden = true
            mobileMoneyContainer.isHidden = true
            if(amount == .none){
                amountTextField.isHidden = false
                containerHeight.constant = 415
                validator.registerField(self.amountTextField, errorLabel: nil, rules: [RequiredRule(message:"Amount  is required")])
                validator.unregisterField(accountAmountTextField)
            }else{
                validator.unregisterField(accountAmountTextField)
                validator.unregisterField(amountTextField)
                amountTextField.isHidden = true
                containerHeight.constant = 356
            }
            isInCardMode = true
            isMobileMoneyMode = false
            isMpesaMode = false
            validator.registerField(self.cardNumber, errorLabel: nil, rules: [RequiredRule(message:"Card number is required")])
            validator.registerField(self.expiry, errorLabel: nil, rules: [RequiredRule(message:"Expiry is required")])
            validator.registerField(self.cvv, errorLabel: nil, rules: [RequiredRule(message:"Cvv is required")])
            validator.unregisterField(phoneNUmber)
            validator.unregisterField(accountBank)
            validator.unregisterField(accountNumber)
            validator.unregisterField(mpesaPhoneNumber)
            validator.unregisterField(mobileMoneyPhoneNumber)
            
            
        case .account :
            isInCardMode = false
            isMpesaMode = false
            isMobileMoneyMode = false
            carView.isHidden = true
            bankView.isHidden = false
            paypalView.isHidden = true
            mpesaContainer.isHidden = true
            mobileMoneyContainer.isHidden = true
            //containerHeight.constant = 233
            if(amount == .none){
                validator.registerField(self.accountAmountTextField, errorLabel: nil, rules: [RequiredRule(message:"Amount  is required")])
                validator.unregisterField(amountTextField)
                validator.unregisterField(mpesaPhoneNumber)
                accountAmountTextField.isHidden = false
                containerHeight.constant = 370
            }else{
                accountAmountTextField.isHidden = true
                containerHeight.constant = 311
                validator.unregisterField(accountAmountTextField)
                validator.unregisterField(amountTextField)
                 validator.unregisterField(mpesaPhoneNumber)
            }
            
            validator.registerField(self.phoneNUmber, errorLabel: nil, rules: [RequiredRule(message:"Phone number is required")])
            validator.registerField(self.expiry, errorLabel: nil, rules: [RequiredRule(message:"Enter expiration")])
            validator.registerField(self.accountBank, errorLabel: nil, rules: [RequiredRule(message:"Bank account is required")])
            validator.unregisterField(cardNumber)
            validator.unregisterField(expiry)
            validator.unregisterField(cvv)
            validator.unregisterField(pinTextField)
            validator.unregisterField(mpesaPhoneNumber)
            validator.unregisterField(mobileMoneyPhoneNumber)
            
        case .paypal:
            carView.isHidden = true
            bankView.isHidden = true
            paypalView.isHidden = false
            mpesaContainer.isHidden = true
            mobileMoneyContainer.isHidden = true
            containerHeight.constant = 128
        case .mpesa:
             isInCardMode = false
            isMpesaMode = true
              isMobileMoneyMode = false
            validator.registerField(self.mpesaPhoneNumber, errorLabel: nil, rules: [RequiredRule(message:"Phone number is required")])
            validator.unregisterField(cardNumber)
            validator.unregisterField(expiry)
            validator.unregisterField(cvv)
            validator.unregisterField(accountAmountTextField)
            validator.unregisterField(amountTextField)
            validator.unregisterField(pinTextField)
            validator.unregisterField(phoneNUmber)
            validator.unregisterField(accountBank)
            validator.unregisterField(accountNumber)
             validator.unregisterField(mobileMoneyPhoneNumber)
            carView.isHidden = true
            bankView.isHidden = true
            paypalView.isHidden = true
            mpesaContainer.isHidden = false
             mobileMoneyContainer.isHidden = true
            containerHeight.constant =  204
        case .mobileMoney:
            isInCardMode = false
            isMpesaMode = false
            isMobileMoneyMode = true
            validator.registerField(self.mobileMoneyPhoneNumber, errorLabel: nil, rules: [RequiredRule(message:"Phone number is required")])
            validator.unregisterField(mpesaPhoneNumber)
            validator.unregisterField(cardNumber)
            validator.unregisterField(expiry)
            validator.unregisterField(cvv)
            validator.unregisterField(accountAmountTextField)
            validator.unregisterField(amountTextField)
            validator.unregisterField(pinTextField)
            validator.unregisterField(phoneNUmber)
            validator.unregisterField(accountBank)
            validator.unregisterField(accountNumber)
            carView.isHidden = true
            bankView.isHidden = true
            paypalView.isHidden = true
            mpesaContainer.isHidden = true
            mobileMoneyContainer.isHidden = false
            containerHeight.constant =  204
        default:
            break
        }
    }
    
    func determineCardContainerHeight(){
        if (isCardSaved){
            
            savedCardsButton.isHidden = false
            savedCardConstants.constant = 50
            if(amount == .none || amount! == "0"){
                amountTextField.isHidden = false
                containerHeight.constant = 415
            }else{
                amountTextField.isHidden = true
                containerHeight.constant = 356
            }
        }else{
            savedCardsButton.isHidden = true
            savedCardConstants.constant = 0
            if(amount == .none || amount! == "0"){
                amountTextField.isHidden = false
                containerHeight.constant = 365
            }else{
                amountTextField.isHidden = true
                containerHeight.constant = 306
            }
        }
    }
    @objc func cardPayButtonTapped(){
        validator.validate(self)
    }
    func validationSuccessful() {
        // submit the form
        if(isPinMode){
            self.hideOvelay()
            self.dopinButtonTapped()
        }else if(isBillingCodeMode){
            self.hideBillingOvelay()
            self.doBillingButtonTapped()
        }
        else if(isBillingAddressMode){
            self.hideBillingAddressOvelay()
            self.doBillingAddressButtonTapped()
        }
        else if(isMpesaMode){
            self.doMpesaButtonTapped()
        }
        else if(isMobileMoneyMode){
            self.doMobileMoneyButtonTapped()
        }
        else{
            if(isInCardMode){
                self.doCardPayButtonTapped()
            }else{
                self.dobankPayButtonTapped()
            }
        }
        
        
    }
    @objc func mpesaPayButtonTapped(){
        validator.validate(self)
    }
    @objc func mobileMoneyPayButtonTapped(){
        validator.validate(self)
    }
    
    func validationFailed(_ errors:[(Validatable ,ValidationError)]) {
        // turn the fields to red
        for (field, error) in errors {
            if let field = field as? UITextField {
                field.bs_setupErrorMessageView(withMessage: error.errorMessage)
                field.bs_showError()
            }
            error.errorLabel?.text = error.errorMessage
            error.errorLabel?.textColor = UIColor(hex: "#FB4F3B")
            error.errorLabel?.isHidden = false
        }
    }
    
    
    func doCardPayButtonTapped(){
        // showOTPScreen()
        self.view.endEditing(true)
        paymentRoute = .card
        self.getFee()
        
    }
    @objc func doPayPalButtonTapped(){
        // showOTPScreen()
        self.view.endEditing(true)
        paymentRoute = .paypal
        self.getFee()
        
    }
    @objc func doMpesaButtonTapped(){
        // showOTPScreen()
        self.view.endEditing(true)
        paymentRoute = .mpesa
        self.getFee()
    }
    @objc func doMobileMoneyButtonTapped(){
        // showOTPScreen()
        self.view.endEditing(true)
        paymentRoute = .mobileMoney
        self.getFee()
    }
    
    private func cardPayAction(){
        if let pubkey = RavePayConfig.sharedConfig().publicKey{
            
            let first2 = expiry.text!.substring(to: expiry.text!.index(expiry.text!.startIndex, offsetBy: 2))
            let last2 = expiry.text!.substring(from: expiry.text!.index(expiry.text!.endIndex, offsetBy: -2))
            var param:[String:Any] = ["PBFPubKey":pubkey ,
                                      "cardno":cardNumber.text!,
                                      "cvv":cvv.text!,
                                      "amount":amount!,
                                      "expiryyear":last2,
                                      "expirymonth": first2,
                                      "email": email!,
                                      "currency": currencyCode,
                                      "country":country!,
                                      "IP": getIFAddresses().first!,
                                      "txRef": merchantTransRef!,
                                      "device_fingerprint": (UIDevice.current.identifierForVendor?.uuidString)!]
            if let narrate = narration{
                param.merge(["narration":narrate])
            }
            if let meta = meta{
                param.merge(["meta":meta])
            }
            if let subAccounts = subAccounts{
              let subAccountDict =  subAccounts.map { (subAccount) -> [String:String] in
                    var dict = ["id":subAccount.id]
                    if let ratio = subAccount.ratio{
                        dict.merge(["transaction_split_ratio":"\(ratio)"])
                    }
                    if let chargeType = subAccount.charge_type{
                        switch chargeType{
                            case .flat :
                            dict.merge(["transaction_charge_type":"flat"])
                            if let charge = subAccount.charge{
                                 dict.merge(["transaction_charge":"\(charge)"])
                            }
                            case .percentage:
                            dict.merge(["transaction_charge_type":"percentage"])
                            if let charge = subAccount.charge{
                                dict.merge(["transaction_charge":"\((charge / 100))"])
                            }
                        }
                    }
                
                    return dict
                }
                param.merge(["subaccounts":subAccountDict])
            }
            if let plan = paymentPlan {
                param.merge(["payment_plan":"\(plan)"])
            }
            
            let jsonString  = param.jsonStringify()
            let secret = getEncryptionKey(RavePayConfig.sharedConfig().secretKey!)
            let data =  TripleDES.encrypt(string: jsonString, key:secret)
            let base64String = data?.base64EncodedString()
            
            bodyParam = param
            let reqbody = [
                "PBFPubKey": pubkey,
                "client": base64String!, // Encrypted $data payload here.
                "alg": "3DES-24"
            ]
            self.chargeCard(reqbody: reqbody)
            
        }
    }
    
    func doPayWithCardToken(token:String){
        // "firstname":"Kola",
        // "lastname":"Oyekole",
        paymentRoute = .existingCard
        self.getFee(token)
    }
    
    private func cardTokenPayAction(_ token:String){
        KVNProgress.show(withStatus: "Processing..")
        amount = amount != .none ? (amount! != "0" ? amount : amountTextField.text) : amountTextField.text
        if let secKey = RavePayConfig.sharedConfig().secretKey{
            var param:[String:Any] = ["currency":currencyCode,
                                      "SECKEY":secKey,
                                      "token":token,
                                      "country":country!,
                                      "amount":amount!,
                                      "email":email!,
                                      "IP": getIFAddresses().first!,
                                      "txRef":merchantTransRef!]
            if let narrate = narration{
                param.merge(["narration":narrate])
            }
            if let meta = meta{
                param.merge(["meta":meta])
            }
            if let subAccounts = subAccounts{
                let subAccountDict =  subAccounts.map { (subAccount) -> [String:String] in
                    var dict = ["id":subAccount.id]
                    if let ratio = subAccount.ratio{
                        dict.merge(["transaction_split_ratio":"\(ratio)"])
                    }
                    if let chargeType = subAccount.charge_type{
                        switch chargeType{
                        case .flat :
                            dict.merge(["transaction_charge_type":"flat"])
                            if let charge = subAccount.charge{
                                dict.merge(["transaction_charge":"\(charge)"])
                            }
                        case .percentage:
                            dict.merge(["transaction_charge_type":"percentage"])
                            if let charge = subAccount.charge{
                                dict.merge(["transaction_charge":"\((charge / 100))"])
                            }
                        }
                    }
                    
                    return dict
                }
                param.merge(["subaccounts":subAccountDict])
            }
            RavePayService.chargeWithToken(param, resultCallback: { (res) in
                if let status = res?["status"] as? String{
                    if status == "success"{
                        let result = res?["data"] as? Dictionary<String,AnyObject>
                        if let suggestedAuth = result?["suggested_auth"] as? String{
                            KVNProgress.dismiss()
                            self.determineSuggestedAuthModelUsed(string: suggestedAuth,data:result!)
                            
                        }else{
                            if let chargeResponse = result?["chargeResponseCode"] as? String{
                                switch chargeResponse{
                                case "00":
                                    let callbackResult = ["status":"success","payload":res!] as [String : Any]
                                    KVNProgress.showSuccess(completion: {
                                        self.delegate?.ravePay(self, didSucceedPaymentWithResult: callbackResult as [String : AnyObject])
                                        self.dismissV()
                                    })
                                    
                                    break
                                case "02":
                                    KVNProgress.dismiss()
                                    let authModelUsed = result?["authModelUsed"] as? String
                                    self.determineAuthModelUsed(auth: authModelUsed, data: result!)
                                    self.dismissV()
                                default:
                                    break
                                }
                            }
                            
                            
                        }
                    }else{
                        if let message = res?["message"] as? String{
                            KVNProgress.dismiss()
                            showMessageDialog("Error", message: message, image: nil, axis: .horizontal, viewController: self, handler: {
                                
                            })
                            
                        }
                    }
                }
                
            }, errorCallback: { (err) in
                KVNProgress.dismiss()
                if (err.containsIgnoringCase(find: "serialize") || err.containsIgnoringCase(find: "JSON")){
                    DispatchQueue.main.async {
                        self.delegate?.ravePay(self, didFailPaymentWithResult: ["error" : err as AnyObject])
                    }
                }else{
                    showMessageDialog("Error", message: err, image: nil, axis: .horizontal, viewController: self, handler: {
                        
                    })
                }
                print(err)
            })
        }
        
    }
    
    @objc func showSavedCards(){
        savedCardOverLayView.isHidden = false
    }
    
    @objc func bankPayButtonTapped(){
        validator.validate(self)
    }
    
    func dobankPayButtonTapped(){
        self.view.endEditing(true)
        paymentRoute = .bank
        self.getFee()
    }
    
    private func paypalAction(){
        amount = amount != .none ? (amount! != "0" ? amount : accountAmountTextField.text) : accountAmountTextField.text
        if let pubkey = RavePayConfig.sharedConfig().publicKey{
            var param:[String:Any] = [
                "PBFPubKey": pubkey,
                "is_paypal": "true",
                "payment_type":"paypal",
                "amount": amount!,
                "email": email!,
                "narration":"paypal",
                "phonenumber":"",
                "currency": currencyCode,
                "country":country!,
                "meta":"",
                "IP": getIFAddresses().first!,
                "txRef": merchantTransRef!,
                "device_fingerprint": (UIDevice.current.identifierForVendor?.uuidString)!
            ]
            if let meta = meta{
                param.merge(["meta":meta])
            }
            if let subAccounts = subAccounts{
                let subAccountDict =  subAccounts.map { (subAccount) -> [String:String] in
                    var dict = ["id":subAccount.id]
                    if let ratio = subAccount.ratio{
                        dict.merge(["transaction_split_ratio":"\(ratio)"])
                    }
                    if let chargeType = subAccount.charge_type{
                        switch chargeType{
                        case .flat :
                            dict.merge(["transaction_charge_type":"flat"])
                            if let charge = subAccount.charge{
                                dict.merge(["transaction_charge":"\(charge)"])
                            }
                        case .percentage:
                            dict.merge(["transaction_charge_type":"percentage"])
                            if let charge = subAccount.charge{
                                dict.merge(["transaction_charge":"\((charge / 100))"])
                            }
                        }
                    }
                    
                    return dict
                }
                param.merge(["subaccounts":subAccountDict])
            }
            let jsonString  = param.jsonStringify()
            let secret = getEncryptionKey(RavePayConfig.sharedConfig().secretKey!)
            let data =  TripleDES.encrypt(string: jsonString, key:secret)
            let base64String = data?.base64EncodedString()
            
            let reqbody = [
                "PBFPubKey": pubkey,
                "client": base64String!, // Encrypted $data payload here.
                "alg": "3DES-24"
            ]
            self.charge(reqbody: reqbody)
            
        }
    }
    
    private func mpesaAction(){
        amount = amount != .none ? (amount! != "0" ? amount : accountAmountTextField.text) : accountAmountTextField.text
        if let pubkey = RavePayConfig.sharedConfig().publicKey{
            var param:[String:Any] = [
                "PBFPubKey": pubkey,
                "amount": amount!,
                "email": email!,
                "is_mpesa":"1",
                "is_mpesa_lipa":"1",
                "phonenumber":self.mpesaPhoneNumber.text!,
                "currency": currencyCode,
                "payment_type": "mpesa",
                "country":country!,
                "meta":"",
                "IP": getIFAddresses().first!,
                "txRef": merchantTransRef!,
                "device_fingerprint": (UIDevice.current.identifierForVendor?.uuidString)!
            ]
            if let meta = meta{
                param.merge(["meta":meta])
            }
            if let subAccounts = subAccounts{
                let subAccountDict =  subAccounts.map { (subAccount) -> [String:String] in
                    var dict = ["id":subAccount.id]
                    if let ratio = subAccount.ratio{
                        dict.merge(["transaction_split_ratio":"\(ratio)"])
                    }
                    if let chargeType = subAccount.charge_type{
                        switch chargeType{
                        case .flat :
                            dict.merge(["transaction_charge_type":"flat"])
                            if let charge = subAccount.charge{
                                dict.merge(["transaction_charge":"\(charge)"])
                            }
                        case .percentage:
                            dict.merge(["transaction_charge_type":"percentage"])
                            if let charge = subAccount.charge{
                                dict.merge(["transaction_charge":"\((charge / 100))"])
                            }
                        }
                    }
                    
                    return dict
                }
                param.merge(["subaccounts":subAccountDict])
            }
            let jsonString  = param.jsonStringify()
            let secret = getEncryptionKey(RavePayConfig.sharedConfig().secretKey!)
            let data =  TripleDES.encrypt(string: jsonString, key:secret)
            let base64String = data?.base64EncodedString()
            
            let reqbody = [
                "PBFPubKey": pubkey,
                "client": base64String!, // Encrypted $data payload here.
                "alg": "3DES-24"
            ]
            self.charge(reqbody: reqbody)
            
        }
    }
    
    private func mobileMoneyGhAction(){
        amount = amount != .none ? (amount! != "0" ? amount : accountAmountTextField.text) : accountAmountTextField.text
        if let pubkey = RavePayConfig.sharedConfig().publicKey{
            var param:[String:Any] = [
                "PBFPubKey": pubkey,
                "amount": amount!,
                "email": email!,
                "is_mobile_money_gh":"1",
                "phonenumber":self.mobileMoneyPhoneNumber.text!,
                "currency": currencyCode,
                "payment_type": "mobilemoneygh",
                "country":country!,
                "meta":"",
                "IP": getIFAddresses().first!,
                "txRef": merchantTransRef!,
                "device_fingerprint": (UIDevice.current.identifierForVendor?.uuidString)!
            ]
            if let meta = meta{
                param.merge(["meta":meta])
            }
            if let subAccounts = subAccounts{
                let subAccountDict =  subAccounts.map { (subAccount) -> [String:String] in
                    var dict = ["id":subAccount.id]
                    if let ratio = subAccount.ratio{
                        dict.merge(["transaction_split_ratio":"\(ratio)"])
                    }
                    if let chargeType = subAccount.charge_type{
                        switch chargeType{
                        case .flat :
                            dict.merge(["transaction_charge_type":"flat"])
                            if let charge = subAccount.charge{
                                dict.merge(["transaction_charge":"\(charge)"])
                            }
                        case .percentage:
                            dict.merge(["transaction_charge_type":"percentage"])
                            if let charge = subAccount.charge{
                                dict.merge(["transaction_charge":"\((charge / 100))"])
                            }
                        }
                    }
                    
                    return dict
                }
                param.merge(["subaccounts":subAccountDict])
            }
            let jsonString  = param.jsonStringify()
            let secret = getEncryptionKey(RavePayConfig.sharedConfig().secretKey!)
            let data =  TripleDES.encrypt(string: jsonString, key:secret)
            let base64String = data?.base64EncodedString()
            
            let reqbody = [
                "PBFPubKey": pubkey,
                "client": base64String!, // Encrypted $data payload here.
                "alg": "3DES-24"
            ]
            self.charge(reqbody: reqbody)
            
        }
    }
    
    private func bankPayAction(){
        amount = amount != .none ? (amount! != "0" ? amount : accountAmountTextField.text) : accountAmountTextField.text
        if let pubkey = RavePayConfig.sharedConfig().publicKey{
            let isInternetBanking = (selectedBank?.isInternetBanking)! == true ? 1 : 0
            let _accountNumber = accountNumber.text! == "" ? "0000" : accountNumber.text!
            var param:[String:Any] = [
                "PBFPubKey": pubkey,
                "accountnumber": _accountNumber,
                "accountbank": (selectedBank?.bankCode)!,
                "amount": amount!,
                "email": email!,
                "payment_type":"account",
                "phonenumber":self.phoneNUmber.text!,
                "currency": currencyCode,
                "country":country!,
                "IP": getIFAddresses().first!,
                "txRef": merchantTransRef!,
                "device_fingerprint": (UIDevice.current.identifierForVendor?.uuidString)!
            ]
            if(isInternetBanking == 1){
                param.merge(["is_internet_banking":"\(isInternetBanking)"])
            }
            if let meta = meta{
                param.merge(["meta":meta])
            }
            if let subAccounts = subAccounts{
                let subAccountDict =  subAccounts.map { (subAccount) -> [String:String] in
                    var dict = ["id":subAccount.id]
                    if let ratio = subAccount.ratio{
                        dict.merge(["transaction_split_ratio":"\(ratio)"])
                    }
                    if let chargeType = subAccount.charge_type{
                        switch chargeType{
                        case .flat :
                            dict.merge(["transaction_charge_type":"flat"])
                            if let charge = subAccount.charge{
                                dict.merge(["transaction_charge":"\(charge)"])
                            }
                        case .percentage:
                            dict.merge(["transaction_charge_type":"percentage"])
                            if let charge = subAccount.charge{
                                dict.merge(["transaction_charge":"\((charge / 100))"])
                            }
                        }
                    }
                    
                    return dict
                }
                param.merge(["subaccounts":subAccountDict])
            }
            if let narrate = narration{
                param.merge(["narration":narrate])
            }
            if let passcode = self.dobTextField.text , passcode != "" {
                param.merge(["passcode":passcode])
            }
            
            let jsonString  = param.jsonStringify()
            let secret = getEncryptionKey(RavePayConfig.sharedConfig().secretKey!)
            let data =  TripleDES.encrypt(string: jsonString, key:secret)
            let base64String = data?.base64EncodedString()
            
            let reqbody = [
                "PBFPubKey": pubkey,
                "client": base64String!, // Encrypted $data payload here.
                "alg": "3DES-24"
            ]
            self.chargeAccount(reqbody: reqbody)
        }
        
    }
    
    func getFee(_ token:String = ""){
        KVNProgress.show(withStatus: "Processing..")
        amount = amount != .none ? (amount! != "0" ? amount : amountTextField.text) : amountTextField.text
        if let pubkey = RavePayConfig.sharedConfig().publicKey{
            var param:[String:String] = [:]
            switch(self.paymentRoute){
            case .card?:
                let first6 = cardNumber.text!.substring(to: cardNumber.text!.index(cardNumber.text!.startIndex, offsetBy: 6))
                param = [
                    "PBFPubKey": pubkey,
                    "amount": amount!,
                    "currency": currencyCode,
                    "card6": first6]
            case .existingCard?:
                let first6  = selectedCard?["first6"]
                param = [
                    "PBFPubKey": pubkey,
                    "amount": amount!,
                    "currency": currencyCode,
                    "card6": first6!]
                
            case .bank?:
                param = [
                    "PBFPubKey": pubkey,
                    "amount": amount!,
                    "currency": currencyCode,
                    "ptype": "2"]
                
            case .paypal?:
                param = [
                    "PBFPubKey": pubkey,
                    "amount": amount!,
                    "currency": currencyCode,
                    "ptype": "paypal"]
            case .mpesa?:
                param = [
                    "PBFPubKey": pubkey,
                    "amount": amount!,
                    "currency": currencyCode,
                    "ptype": "3"]
            case .mobileMoney?:
                param = [
                    "PBFPubKey": pubkey,
                    "amount": amount!,
                    "currency": currencyCode,
                    "ptype": "2"]
            default:
                break
            }
            
            RavePayService.getFee(param, resultCallback: { (result) in
                KVNProgress.dismiss(completion: {
                    
                    let data = result?["data"] as? [String:AnyObject]
                    if let _fee =  data?["fee"] as? Double{
                        
                        let fee = "\(_fee)"
                        let chargeAmount = data?["charge_amount"] as? String
                        DispatchQueue.main.async {
                            let popup = PopupDialog(title: "Confirm", message: "You will be charged a transaction fee of \(fee.toCountryCurrency(code:  self.currencyCode)), Total amount to be charged will be \(chargeAmount!.toCountryCurrency(code: self.currencyCode)). Do you wish to continue?")
                            let cancel = CancelButton(title: "Cancel") {
                                
                            }
                            let proceed = DefaultButton(title: "Proceed") {
                                switch(self.paymentRoute){
                                case .card?:
                                    self.cardPayAction()
                                case .existingCard?:
                                    self.cardTokenPayAction(token)
                                case .bank?:
                                    self.bankPayAction()
                                case .paypal?:
                                    self.paypalAction()
                                case .mpesa?:
                                    self.mpesaAction()
                                case .mobileMoney?:
                                    self.mobileMoneyGhAction()
                                default:
                                    break
                                }
                            }
                            popup.addButtons([cancel,proceed])
                            popup.buttonAlignment = .horizontal
                            self.present(popup, animated: true, completion: nil)
                        }
                    }else{
                        if let err = result?["message"] as? String{
                            showMessageDialog("Error", message: err, image: nil, axis: .horizontal, viewController: self, handler: {
                                
                            })
                        }
                    }
                })
            }, errorCallback: { (err) in
                KVNProgress.dismiss()
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
    
    func charge(reqbody:[String:String])
    {
        KVNProgress.show(withStatus: "Processing..")
        RavePayService.charge(reqbody, resultCallback: { (res) in
            if let status = res?["status"] as? String{
                if status == "success"{
                    let result = res?["data"] as? Dictionary<String,AnyObject>
                    
                    if let chargeResponse = result?["chargeResponseCode"] as? String{
                        switch chargeResponse{
                        case "00":
                            let callbackResult = ["status":"success","payload":res!] as [String : Any]
                            KVNProgress.showSuccess(completion: {
                                self.delegate?.ravePay(self, didSucceedPaymentWithResult: callbackResult as [String : AnyObject])
                                self.navigationController?.dismiss(animated: true, completion: nil)
                                
                            })
                            break
                        case "02":
                             KVNProgress.dismiss()
                            if let type =  result?["paymentType"] as? String {
                                if (type.containsIgnoringCase(find: "mpesa") || type.containsIgnoringCase(find: "mobilemoneygh")) {
                                    if let status =  result?["status"] as? String{
                                        if (status.containsIgnoringCase(find: "pending")){
                                            KVNProgress.dismiss()
                                            showMessageDialog("Transaction Processing", message: "A push notification has been sent to your phone, please complete the transaction by entering your pin.\n Please do not close this page until transaction is completed", image: nil, axis: .horizontal, viewController: self, handler: {
                                                if let txRef = result?["txRef"] as? String{
                                                    self.queryMpesaTransaction(txRef: txRef)
                                                }
                                            })
                                            
                                        }
                                    }
                                }
                            }
                        default:
                            break
                        }
                    }
                }else{
                    if let message = res?["message"] as? String{
                        KVNProgress.dismiss()
                        showMessageDialog("Error", message: message, image: nil, axis: .horizontal, viewController: self, handler: {
                            
                        })
                        
                    }
                }
            }
            
            
        }, errorCallback: { (err) in
            KVNProgress.dismiss()
            if (err.containsIgnoringCase(find: "serialize") || err.containsIgnoringCase(find: "JSON")){
                DispatchQueue.main.async {
                    self.delegate?.ravePay(self, didFailPaymentWithResult: ["error" : err as AnyObject])
                }
            }else{
                showMessageDialog("Error", message: err, image: nil, axis: .horizontal, viewController: self, handler: {
                    
                })
            }
            
            print(err)
        })
    }
    
    func chargeAccount(reqbody:[String:String])
    {
        KVNProgress.show(withStatus: "Processing..")
        RavePayService.charge(reqbody, resultCallback: { (res) in
            if let status = res?["status"] as? String{
                if status == "success"{
                    let result = res?["data"] as? Dictionary<String,AnyObject>
                    
                    if let chargeResponse = result?["chargeResponseCode"] as? String{
                        switch chargeResponse{
                        case "00":
                            let callbackResult = ["status":"success","payload":res!] as [String : Any]
                            
                            KVNProgress.showSuccess(completion: {
                                self.delegate?.ravePay(self, didSucceedPaymentWithResult: callbackResult as [String : AnyObject])
                                self.navigationController?.dismiss(animated: true, completion: nil)
                                
                            })
                            
                            break
                        case "02":
                            KVNProgress.dismiss()
                            self.determineBankAuthModelUsed(data: result!)
                        default:
                            break
                        }
                    }
                }else{
                    if let message = res?["message"] as? String{
                        KVNProgress.dismiss()
                        showMessageDialog("Error", message: message, image: nil, axis: .horizontal, viewController: self, handler: {
                            
                        })
                        
                    }
                }
            }
            
            
        }, errorCallback: { (err) in
            KVNProgress.dismiss()
            if (err.containsIgnoringCase(find: "serialize") || err.containsIgnoringCase(find: "JSON")){
                DispatchQueue.main.async {
                    self.delegate?.ravePay(self, didFailPaymentWithResult: ["error" : err as AnyObject])
                }
            }else{
                showMessageDialog("Error", message: err, image: nil, axis: .horizontal, viewController: self, handler: {
                    
                })
            }
            
            print(err)
        })
    }
    
    func chargeCard(reqbody:[String:String])
    {
        KVNProgress.show(withStatus: "Processing..")
        RavePayService.charge(reqbody, resultCallback: {
            (res) in
            if let status = res?["status"] as? String{
                if status == "success"{
                    let result = res?["data"] as? Dictionary<String,AnyObject>
                    if let suggestedAuth = result?["suggested_auth"] as? String{
                        KVNProgress.dismiss()
                        self.determineSuggestedAuthModelUsed(string: suggestedAuth,data:result!)
                        
                    }else{
                        if let chargeResponse = result?["chargeResponseCode"] as? String{
                            switch chargeResponse{
                            case "00":
                                let callbackResult = ["status":"success","payload":res!] as [String : Any]
                                
                                KVNProgress.showSuccess(completion: {
                                    self.delegate?.ravePay(self, didSucceedPaymentWithResult: callbackResult as [String : AnyObject])
                                    self.navigationController?.dismiss(animated: true, completion: nil)
                                    
                                })
                                break
                            case "02":
                                KVNProgress.dismiss()
                                let authModelUsed = result?["authModelUsed"] as? String
                                self.determineAuthModelUsed(auth: authModelUsed, data: result!)
                            default:
                                break
                            }
                        }
                        
                    }
                }else{
                    if let message = res?["message"] as? String{
                        KVNProgress.dismiss()
                        showMessageDialog("Error", message: message, image: nil, axis: .horizontal, viewController: self, handler: {
                            
                        })
                        
                    }
                }
            }
        }, errorCallback: { (err) in
            KVNProgress.dismiss()
            if (err.containsIgnoringCase(find: "serialize") || err.containsIgnoringCase(find: "JSON")){
                DispatchQueue.main.async {
                    self.delegate?.ravePay(self, didFailPaymentWithResult: ["error" : err as AnyObject])
                }
            }else{
                showMessageDialog("Error", message: err, image: nil, axis: .horizontal, viewController: self, handler: {
                    
                })
            }
            
            print(err)
        })
    }
    
    
    
    
    
    
    
    private func determineSuggestedAuthModelUsed(string:String, data:[String:AnyObject]){
        let flwTransactionRef = data["flwRef"] as? String
        switch string {
        case "PIN":
            self.showPin()
        case "GTB_OTP":
            self.showPin()
        case "AVS_VBVSECURECODE":
            self.showBillingView()
        case "NOAUTH_INTERNATIONAL":
            self.showBillingAddressView()
        case "VBVSECURECODE":
            if let authURL = data["authurl"] as? String {
                self.showWebView(url: authURL,ref:flwTransactionRef!)
            }
        default:
            break
        }
    }
    func queryTransaction(flwRef:String?){
        if let secret = RavePayConfig.sharedConfig().secretKey ,let  ref = flwRef{
            let param = ["SECKEY":secret,"flw_ref":ref]
            RavePayService.queryTransaction(param, resultCallback: { (result) in
                if let  status = result?["status"] as? String{
                    if (status == "success"){
                        DispatchQueue.main.async {
                            print(result!)
                            let token = self.getToken(result: result!)
                            if let tk = token{
                                self.doPayWithCardToken(token: tk)
                            }else{
                                DispatchQueue.main.async {
                                    KVNProgress.dismiss()
                                    showMessageDialog("Error", message: "Could not acquire your card token for processing", image: nil, axis: .horizontal, viewController: self, handler: {
                                        
                                    })
                                    
                                }
                                
                            }
                        }
                    }else{
                        DispatchQueue.main.async {
                            KVNProgress.dismiss()
                            showMessageDialog("Error", message: "Something went wrong please try again.", image: nil, axis: .horizontal, viewController: self, handler: {
                                
                            })
                            
                        }
                    }
                }
            }, errorCallback: { (err) in
                
                print(err)
                KVNProgress.dismiss()
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
    func queryMpesaTransaction(txRef:String?){
        if let secret = RavePayConfig.sharedConfig().secretKey ,let  ref = txRef{
            let param = ["SECKEY":secret,"txref":ref]
            RavePayService.queryMpesaTransaction(param, resultCallback: { (result) in
        //        print(result)
                if let  status = result?["status"] as? String{
                    if (status == "success"){
                        if let data = result?["data"] as? [String:AnyObject]{
                       // if let meta = data["flwMeta"] as? [String:AnyObject]{
                            if let chargeCode = data["chargecode"] as?  String{
                                switch chargeCode{
                                case "00":
                                    DispatchQueue.main.async {
                                        let callbackResult = ["status":"success","payload":result!] as [String : Any]
                                        self.delegate?.ravePay(self, didSucceedPaymentWithResult: callbackResult as [String : AnyObject])
                                        self.navigationController?.dismiss(animated: true, completion: nil)
                                    }
                                default:
                                    self.queryMpesaTransaction(txRef: ref)
                                }
                            }else{
                                 self.queryMpesaTransaction(txRef: ref)
                            }
                            
                        //    }
                        }
                    }else{
                        DispatchQueue.main.async {
                            KVNProgress.dismiss()
                            showMessageDialog("Error", message: "Something went wrong please try again.", image: nil, axis: .horizontal, viewController: self, handler: {
                                
                            })
                            
                        }
                    }
                }
            }, errorCallback: { (err) in
                
                print(err)
                KVNProgress.dismiss()
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
    private func getToken(result:[String:AnyObject])->String?{
        var token:String?
        if let _data = result["data"] as? [String:AnyObject]{
            if let card = _data["card"] as? [String:AnyObject]{
                if let cards = card["card_tokens"] as? [[String:AnyObject]]{
                    let _cardToken = cards.last!
                    if let _token = _cardToken["embedtoken"] as? String{
                        token = _token
                    }
                }
            }
        }
        return token
    }
    
    private func addOrUpdateCardToken(cardNumber:String,data:[String:AnyObject]){
        if let chargeToken = data["chargeToken"] as? [String:AnyObject]{
            if let token = chargeToken["embed_token"] as? String{
                let first6 = cardNumber.substring(to: cardNumber.index(cardNumber.startIndex, offsetBy: 6))
                let last4 = cardNumber.substring(from: cardNumber.index(cardNumber.endIndex, offsetBy: -4))
                let cardDetails = ["card_token":token,"first6":first6,"last4":last4]
                if let cards  = UserDefaults.standard.object(forKey: "cards-\(email!)") as? [[String:String]]{
                    var theCards = cards
                    theCards = cards.filter({ (item) -> Bool in
                        let _first6 = item["first6"]!
                        return _first6 != first6
                    })
                    theCards.append(cardDetails)
                    UserDefaults.standard.set(theCards, forKey: "cards-\(email!)")
                    cardList = theCards
                    
                }else{
                    UserDefaults.standard.set([cardDetails], forKey: "cards-\(email!)")
                    cardList = [cardDetails]
                    
                }
            }
        }
        // }
    }
    private func updateExistingCardToken(selectedCard:[String:String]?,data:[String:AnyObject]){
        if let _selectedCard = selectedCard{
            if let _data = data["data"] as? [String:AnyObject]{
                if let chargeToken = _data["chargeToken"] as? [String:AnyObject]{
                    if let token = chargeToken["embed_token"] as? String{
                        if let cards  = UserDefaults.standard.object(forKey: "cards-\(email!)") as? [[String:String]]{
                            let cardDetails = ["card_token":token,"first6":_selectedCard["first6"]!,"last4":_selectedCard["last4"]!]
                            var theCards = cards
                            theCards = cards.filter({ (item) -> Bool in
                                let _first6 = item["first6"]!
                                let selectedFirst6 = _selectedCard["first6"]
                                return _first6 != selectedFirst6
                            })
                            theCards.append(cardDetails)
                            UserDefaults.standard.set(theCards, forKey: "cards-\(email!)")
                            cardList = theCards
                            
                        }
                    }
                }
            }
        }
    }
    
    private func determineBankAuthModelUsed(data:[String:AnyObject]){
        let flwTransactionRef = data["flwRef"] as? String
        //chargeResponseMessage
        var _instruction:String? = "Pending OTP Validation"
        if let instruction = data["validateInstruction"] as? String{
            _instruction = instruction
        }else{
            if let instruction = data["validateInstructions"] as? [String:AnyObject]{
                if let  _inst =  instruction["instruction"] as? String{
                    if _inst != ""{
                        _instruction = _inst
                    }
                }
            }
        }
        if let _ = selectedBank{
            //if (selectedBank!.isInternetBanking! == false){
                if let authURL = data["authurl"] as? String, authURL != "NO-URL", authURL != "N/A"{
                    self.showWebView(url: authURL, ref:flwTransactionRef!, isCard: false)
                }else{
                    if let flwRef = flwTransactionRef{
                        self.hideOvelay()
                        self.showOTPScreen(flwRef,isCard: false, message: _instruction)
                    }
                }
//            }else{
//                if let authURL = data["authurl"] as? String{
//                    self.showWebView(url: authURL, ref:flwTransactionRef!, isCard: false)
//                }
//            }
        }
    }
    
    private func determineAuthModelUsed(auth:String?, data:[String:AnyObject]){
        let flwTransactionRef = data["flwRef"] as? String
        //let chargeMessage = data["validateInstruction"] as? String
        var _instruction:String? =  data["chargeResponseMessage"] as? String
        if let instruction = data["validateInstruction"] as? String{
            _instruction = instruction
        }else{
            if let instruction = data["validateInstructions"] as? [String:AnyObject]{
                if let  _inst =  instruction["instruction"] as? String{
                    if _inst != ""{
                        _instruction = _inst
                    }
                }
            }
        }
        if (saveCardSwitch.isOn){
            addOrUpdateCardToken(cardNumber: cardNumber.text!, data: data)
        }
        
        if let authURL = data["authurl"] as? String, authURL != "NO-URL", authURL != "N/A" {
            self.showWebView(url: authURL, ref:flwTransactionRef!, isCard: false)
        }else{
            if let flwRef = flwTransactionRef{
                self.hideOvelay()
                self.showOTPScreen(flwRef, isCard: true, message: _instruction)
               
            }
        }
        
    }
    
    private func showWebView(url:String?, ref:String = "", isCard:Bool = true){
        let webController = WebViewController()
        webController.url = url
        webController.flwRef = ref
        webController.isCard = isCard
        webController.cardNumber = self.cardNumber.text!
        webController.saveCard = self.saveCardSwitch.isOn
        webController.delegate = self
        webController.email = email
        self.navigationItem.title = ""
        self.navigationController?.pushViewController(webController, animated: true)
    }
    
    private func showBillingView(){
        billingCodeTextField.text = ""
        billingOverLayView.isHidden = false
        isBillingCodeMode = true
        validator.registerField(self.billingCodeTextField, errorLabel: nil, rules: [RequiredRule(message:"Billing code is required")])
    }
    
    private func showBillingAddressView(){
        billingAddressCountry.text = ""
        billingAddressState.text = ""
        billingAddressCity.text = ""
        billingAddress.text = ""
        zipCode.text = ""
        billingAddressOverLayView.isHidden = false
        isBillingAddressMode = true
        validator.registerField(self.billingAddressCountry, errorLabel: nil, rules: [RequiredRule(message:"Country is required")])
         validator.registerField(self.billingAddressState, errorLabel: nil, rules: [RequiredRule(message:"State is required")])
         validator.registerField(self.billingAddressCity, errorLabel: nil, rules: [RequiredRule(message:"City is required")])
         validator.registerField(self.billingAddress, errorLabel: nil, rules: [RequiredRule(message:"Address is required")])
         validator.registerField(self.zipCode, errorLabel: nil, rules: [RequiredRule(message:"Code is required")])
    }
    
    @objc private func billingAddressButtonTapped(){
        validator.validate(self)
    }
    @objc private func billingButtonTapped(){
        validator.validate(self)
    }
    
    private func showPin(){
        pinTextField.text = ""
        overLayView.isHidden = false
        isPinMode = true
        validator.registerField(self.pinTextField, errorLabel: nil, rules: [RequiredRule(message:"Pin is required")])
    }
    @objc private func pinButtonTapped(){
        validator.validate(self)
    }
    
    @objc private func dopinButtonTapped(){
        guard let pin = self.pinTextField.text else {return}
        bodyParam?.merge(["suggested_auth":"PIN","pin":pin])
        let jsonString  = bodyParam!.jsonStringify()
        let secret = getEncryptionKey(RavePayConfig.sharedConfig().secretKey!)
        let data =  TripleDES.encrypt(string: jsonString, key:secret)
        let base64String = data?.base64EncodedString()
        
        let reqbody = [
            "PBFPubKey": RavePayConfig.sharedConfig().publicKey!,
            "client": base64String!,
            "alg": "3DES-24"
        ]
        self.chargeCard(reqbody: reqbody)
    }
    @objc private func doBillingButtonTapped(){
        guard let zip = self.billingCodeTextField.text else {return}
        bodyParam?.merge(["suggested_auth":"AVS_VBVSECURECODE","billingzip":zip])
        let jsonString  = bodyParam!.jsonStringify()
        let secret = getEncryptionKey(RavePayConfig.sharedConfig().secretKey!)
        let data =  TripleDES.encrypt(string: jsonString, key:secret)
        let base64String = data?.base64EncodedString()
        
        let reqbody = [
            "PBFPubKey": RavePayConfig.sharedConfig().publicKey!,
            "client": base64String!,
            "alg": "3DES-24"
        ]
        self.chargeCard(reqbody: reqbody)
    }
    
    @objc private func doBillingAddressButtonTapped(){
        guard let zip = self.zipCode.text, let city = self.billingAddressCity.text,
        let address = self.billingAddress.text, let country = self.billingAddressCountry.text , let state = self.billingAddressState.text else {return}
        bodyParam?.merge(["suggested_auth":"NOAUTH_INTERNATIONAL","billingzip":zip,"billingcity":city,
                          "billingaddress":address,"billingstate":state, "billingcountry":country])
        let jsonString  = bodyParam!.jsonStringify()
        let secret = getEncryptionKey(RavePayConfig.sharedConfig().secretKey!)
        let data =  TripleDES.encrypt(string: jsonString, key:secret)
        let base64String = data?.base64EncodedString()
        
        let reqbody = [
            "PBFPubKey": RavePayConfig.sharedConfig().publicKey!,
            "client": base64String!,
            "alg": "3DES-24"
        ]
        self.chargeCard(reqbody: reqbody)
    }
    
    
    private func showOTPScreen(_ ref:String, isCard:Bool = true , message:String? = "Enter the OTP code below"){
        //let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let storyboard = UIStoryboard(name: "Rave", bundle: identifier)
        let otp = storyboard.instantiateViewController(withIdentifier: "otp") as! OTPController
        otp.isCardValidation = isCard
        otp.transactionReference = ref
        otp.cardNumber = self.cardNumber.text!
        otp.saveCard = self.saveCardSwitch.isOn
        otp.otpChargeMessage = message
        
        otp.email = email
        otp.delegate = self
        self.navigationItem.title = ""
        self.navigationController?.pushViewController(otp, animated: true)
    }
    
    private func getBanks(){
        RavePayService.getBanks(resultCallback: { (_banks) in
            DispatchQueue.main.async {
                if let count = self.blacklistBanks?.count{
                    if count > 0 {
                        self.blacklistBanks?.forEach({ (name) in
                            self.banks = _banks?.filter({ (bank) -> Bool in
                                return !(bank.name?.containsIgnoringCase(find: name))!
                            })
                        })
                        self.banks = self.banks?.sorted(by: { (first, second) -> Bool in
                            return first.name!.localizedCaseInsensitiveCompare(second.name!) == .orderedAscending
                        })
                    }else{
                        self.banks = _banks?.sorted(by: { (first, second) -> Bool in
                            return first.name!.localizedCaseInsensitiveCompare(second.name!) == .orderedAscending
                        })
                    }
                }else{
                    self.banks = _banks?.sorted(by: { (first, second) -> Bool in
                        return first.name!.localizedCaseInsensitiveCompare(second.name!) == .orderedAscending
                    })
                }
            }
            
        }) { (err) in
            print(err)
        }
    }
    
    func ravePay(_ webController: WebViewController, didFailPaymentWithResult result: [String : AnyObject]) {
        DispatchQueue.main.async {
            self.delegate?.ravePay(self, didFailPaymentWithResult: result)
            self.navigationController?.dismiss(animated: true, completion: nil)
        }
    }
    func ravePay(_ webController: WebViewController, didSucceedPaymentWithResult result: [String : AnyObject]) {
        delegate?.ravePay(self, didSucceedPaymentWithResult: result)
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    func raveOTP(_ webController: OTPController, didFailPaymentWithResult result: [String : AnyObject]) {
        DispatchQueue.main.async {
            self.delegate?.ravePay(self, didFailPaymentWithResult: result)
            self.navigationController?.dismiss(animated: true, completion: nil)
        }
    }
    func raveOTP(_ webController: OTPController, didSucceedPaymentWithResult result: [String : AnyObject]) {
        delegate?.ravePay(self, didSucceedPaymentWithResult: result)
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.bs_hideError()
        if textField == accountBank{
            if let count = self.banks?.count{
                if count != 0 {
                    bankPicker.selectRow(0, inComponent: 0, animated: true)
                    self.pickerView(bankPicker, didSelectRow: 0, inComponent: 0)
                }
            }
        }
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
    @objc func textFieldDidChange(textField: UITextField) {
        if let type = creditCardValidator.type(from: textField.text!){
            print(type.name)
            //let image = self.getCardImage(scheme: type.name.lowercased())
            cardIcon = UIButton(type: .custom)
            //cardIcon.tintColor =
            cardIcon.setImage(UIImage(named: type.name.lowercased(), in: identifier ,compatibleWith: nil), for: .normal)
        }else{
            print("Couldnt determing type")
            cardIcon = UIButton(type: .system)
            cardIcon.tintColor =  RavePayConfig.sharedConfig().themeColor
            cardIcon.setImage(UIImage(named: "new_card", in: identifier ,compatibleWith: nil), for: .normal)
        }
        cardIcV.removeFromSuperview()
        cardIcon.frame = CGRect(x: 12, y: 5, width: 20, height: 15)
        cardIcV = UIView(frame: CGRect(x: 0, y: 0, width: 45, height: 30))
        cardIcV.addSubview(cardIcon)
        styleTextField(cardNumber,leftView: cardIcV)
    }
    
    func getCardImage(scheme:String) ->String{
        switch scheme{
        case "visa":         return "visa"
        case "mastercard":   return "mastercard"
        case "amex":         return "amex"
        case "diners":       return "diner"
        case "discover":     return "discover"
        case "jcb":          return "jcb"
        case "verve":          return "verve"
        default:            return "nothing"
        }
        
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if let count = self.banks?.count{
            return count
        }else{
            return 0
        }
        
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.banks?[row].name
        
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if let count = self.banks?.count,  count > 0{
            selectedBank = self.banks?[row]
            if let internetBanking = selectedBank?.isInternetBanking{
                if(internetBanking == true){
                    phoneNUmber.isHidden = false
                    accountNumber.isHidden = true
                    containerHeight.constant = 233
                    validator.unregisterField(accountNumber)
                }else{
                    phoneNUmber.isHidden = false
                    accountNumber.isHidden = false
                    containerHeight.constant = 311
                    validator.registerField(self.accountNumber, errorLabel: nil, rules: [RequiredRule(message:"Account number is required")])
                    
                }
            }
            
            
            self.accountBank.text = self.banks?[row].name
            if let bank = self.accountBank.text{
                if bank.containsIgnoringCase(find: "zenith"){
                    self.dobTextField.isHidden = false
                    containerHeight.constant = 419
                }else{
                    self.dobTextField.isHidden = true
                    containerHeight.constant = 311
                }
            }
        }
    }
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    
}

extension RavePayController: UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let count = cardList?.count{
            return count
        }else{
            return 0
        }
    }
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath:IndexPath) {
        if(indexPath.section == 0){
            selectedCard = cardList?[indexPath.row]
            if (editingStyle == UITableViewCellEditingStyle.delete) {
                let cards = self.cardList?.filter({ (item) -> Bool in
                    return item["card_token"] != selectedCard!["card_token"]
                })
                UserDefaults.standard.set(cards, forKey: "cards-\(self.email!)")
                self.cardList?.remove(at: indexPath.row)
                cardSavedTable.reloadData()
                if (cardList!.count == 0){
                    UserDefaults.standard.removeObject(forKey: "cards-\(self.email!)")
                    self.hideCardOvelay()
                    isCardSaved = false
                    
                    determineCardContainerHeight()
                    
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = cardSavedTable.dequeueReusableCell(withIdentifier: "cardCell")! as UITableViewCell
        cell.accessoryType = .none
        let card = cardList?[indexPath.row]
        let first6 = card?["first6"]
        let last4 = card?["last4"]
        cell.textLabel?.text = "\(first6!)-xx-xxxx-\(last4!)"
        if let _ = selectedCard{
            let toks = card!["card_token"]
            let selectedToks = selectedCard!["card_token"]
            if(toks == selectedToks){
                cell.accessoryType = .checkmark
            }else{
                cell.accessoryType = .none
            }
        }
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedCard = cardList?[indexPath.row]
        
    }
}
