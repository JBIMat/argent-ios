//
//  LoginViewController.swift
//  argent-ios
//
//  Created by Sinan Ulkuatam on 2/9/16.
//  Copyright © 2016 Sinan Ulkuatam. All rights reserved.
//

import UIKit
import QuartzCore
import Alamofire
import SwiftyJSON
import TextFieldEffects
import UIColor_Hex_Swift
import TransitionTreasury
import TransitionAnimation
import OnePasswordExtension
import Crashlytics
import WatchConnectivity

class LoginViewController: UIViewController, UITextFieldDelegate, WCSessionDelegate  {
    
    var window: UIWindow?

    @IBOutlet weak var closeButton: UIButton!
    
    @IBOutlet weak var loginBox: UIView!
    
    @IBOutlet weak var loginButton: UIButton!
    
    let onePasswordButton = UIImageView()

    let imageView = UIImageView()
    
    weak var modalDelegate: ModalViewControllerDelegate?

    private let activityIndicator:UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)

    override func viewDidAppear(animated: Bool) {
        NSUserDefaults.standardUserDefaults().setBool(false,forKey:"userLoggedIn");
        NSUserDefaults.standardUserDefaults().synchronize();
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }
    
    func configureView() {
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(LoginViewController.keyboardWillAppear(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(LoginViewController.keyboardWillDisappear(_:)), name: UIKeyboardWillHideNotification, object: nil)
        
        loginButton.layer.cornerRadius = 3
        loginButton.layer.masksToBounds = true
        loginButton.backgroundColor = UIColor.pastelBlue().colorWithAlphaComponent(0.5)
        loginButton.setTitleColor(UIColor.whiteColor().colorWithAlphaComponent(0.3), forState: .Normal)
        loginButton.addTarget(LoginBoxTableViewController(), action: #selector(LoginBoxTableViewController.login(_:)), forControlEvents: .TouchUpInside)
        
        self.view.backgroundColor = UIColor.globalBackground()
        let screen = UIScreen.mainScreen().bounds
        let screenWidth = screen.size.width
        let screenHeight = screen.size.height
        
        // Set background image
        let backgroundView: UIImageView = UIImageView(image: UIImage(named: "BackgroundBlueDark"))
        backgroundView.contentMode = UIViewContentMode.ScaleToFill
        backgroundView.frame = self.view.bounds
        //        self.view!.addSubview(backgroundView)
        //        self.view.sendSubviewToBack(backgroundView)
        
        self.view.backgroundColor = UIColor.whiteColor()
        
        let signInLabel = UILabel()
        signInLabel.adjustAttributedString("SIGN IN", spacing: 2, fontName: "SFUIText-Regular", fontSize: 13, fontColor: UIColor.darkBlue().colorWithAlphaComponent(0.75))
        signInLabel.textAlignment = .Center
        signInLabel.frame = CGRect(x: 0, y: 0, width: screenWidth, height: 60)
        signInLabel.frame.origin.y = 200 // 12% down from the top
//        addSubviewWithFade(signInLabel, parentView: self, duration: 0.3)
        
        activityIndicator.center = self.view.center
        activityIndicator.startAnimating()
        activityIndicator.hidesWhenStopped = true
        self.view.addSubview(activityIndicator)
        activityIndicator.stopAnimating()
        
        NSUserDefaults.standardUserDefaults().setValue("", forKey: "userAccessToken")
        NSUserDefaults.standardUserDefaults().synchronize()
        
        UITextField.appearance().keyboardAppearance = .Light
        
        // Add action to close button to return to auth view
        closeButton.addTarget(self, action: #selector(LoginViewController.goToAuth(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        closeButton.addTarget(self, action: #selector(LoginViewController.goToAuth(_:)), forControlEvents: UIControlEvents.TouchUpOutside)
        
        onePasswordButton.frame = CGRect(x: 0, y: screenHeight-140, width: screenWidth, height: 40)
        onePasswordButton.image = UIImage(named: "onepassword-button-dark")
        onePasswordButton.contentMode = .ScaleAspectFit
        onePasswordButton.userInteractionEnabled = true
        self.view.addSubview(onePasswordButton)
        self.view.bringSubviewToFront(onePasswordButton)
        
        // Set up OnePassword
        if OnePasswordExtension.sharedExtension().isAppExtensionAvailable() {
            let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.useOnePassword(_:)))
            self.onePasswordButton.addGestureRecognizer(tap)
        } else {
            let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.checkOnePasswordExists(_:)))
            self.onePasswordButton.addGestureRecognizer(tap)
        }
        
        let resetPasswordButton = UIButton()
        resetPasswordButton.frame = CGRect(x: 0, y: screenHeight-60, width: screenWidth, height: 40)
        let str0 = NSAttributedString(string: "Forgot Password?", attributes: [
            NSFontAttributeName: UIFont(name: "SFUIText-Regular", size: 12)!,
                NSForegroundColorAttributeName:UIColor.pastelBlue()
            ])
        let str1 = NSAttributedString(string: "Forgot Password?", attributes: [
            NSFontAttributeName: UIFont(name: "SFUIText-Regular", size: 12)!,
            NSForegroundColorAttributeName:UIColor.pastelBlue().colorWithAlphaComponent(0.5)
            ])
        resetPasswordButton.setAttributedTitle(str0, forState: .Normal)
        resetPasswordButton.setAttributedTitle(str1, forState: .Highlighted)
        resetPasswordButton.addTarget(self, action: #selector(LoginViewController.goToReset(_:)), forControlEvents: .TouchUpInside)
        self.view.addSubview(resetPasswordButton)
        self.view.bringSubviewToFront(resetPasswordButton)
        
        // Login box, set height of container to match embedded tableview
        let containerFrame: CGRect = self.loginBox.frame
        loginBox.frame = containerFrame
        loginBox.layer.cornerRadius = 3
        loginBox.layer.borderColor =  UIColor.paleBlue().colorWithAlphaComponent(0.5).CGColor
        loginBox.layer.borderWidth = 1
        loginBox.layer.masksToBounds = true
        
        // Border radius on uiview
        view.layer.cornerRadius = 0
        view.layer.masksToBounds = true
        
        // Do any additional setup after loading the view.
        
        //Looks for single or multiple taps.
        let keyboardTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(LoginViewController.dismissKeyboard))
        view.addGestureRecognizer(keyboardTap)
        
        let image = UIImage(named: "LogoOutlineDark")
        imageView.image = image
        imageView.layer.masksToBounds = true
        imageView.tag = 42312
        imageView.frame = CGRect(x: 0, y: 0, width: 70, height: 70)
        imageView.frame.origin.y = screenHeight*0.15 // 12% down from the top
        imageView.frame.origin.x = (self.view.bounds.size.width - imageView.frame.size.width) / 2.0 // centered left to right.
        addSubviewWithFade(imageView, parentView: self, duration: 0.3)
        
        if self.view.layer.frame.height <= 480.0 {
            imageView.removeFromSuperview()
        }
    }

    func goToReset(sender: AnyObject) {
        performSegueWithIdentifier("resetPasswordView", sender: sender)
    }
    
    // Set the ID in the storyboard in order to enable transition!
    func goToAuth(sender:AnyObject!)
    {
        // Normally identifiers are started with capital letters, exception being authViewController, make sure UIStoryboard name is Auth, not Main
        let viewController:AuthViewController = UIStoryboard(name: "Auth", bundle: nil).instantiateViewControllerWithIdentifier("authViewController") as! AuthViewController
        viewController.modalTransitionStyle = .CoverVertical
        self.presentViewController(viewController, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Changing Status Bar
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .Default
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }
    
}

extension LoginViewController {
    // one password
    
    func checkOnePasswordExists(sender: AnyObject) {
        if OnePasswordExtension.sharedExtension().isAppExtensionAvailable() == false {
            let alertController = UIAlertController(title: "1Password is not installed", message: "Get 1Password from the App Store", preferredStyle: UIAlertControllerStyle.Alert)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
            alertController.addAction(cancelAction)
            
            let OKAction = UIAlertAction(title: "Get 1Password", style: .Default) { (action) in UIApplication.sharedApplication().openURL(NSURL(string: "https://itunes.apple.com/app/1password-password-manager/id568903335")!)
            }
            
            alertController.addAction(OKAction)
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    func useOnePassword(sender: AnyObject) {
        OnePasswordExtension.sharedExtension().findLoginForURLString("https://www.argentapp.com", forViewController: self, sender: sender, completion: { (loginDictionary, error) -> Void in
            if loginDictionary == nil {
                if error!.code != Int(AppExtensionErrorCodeCancelledByUser) {
                    print("Error invoking 1Password App Extension for find login: \(error)")
                    Answers.logLoginWithMethod("1Password",
                        success: false,
                        customAttributes: [
                            "error": error!
                        ])
                }
                return
            }
            
            Answers.logLoginWithMethod("1Password",
                success: true,
                customAttributes: [
                    "user": (loginDictionary?[AppExtensionUsernameKey])!
                ])
            
            let username = loginDictionary?[AppExtensionUsernameKey] as? String
            let password = loginDictionary?[AppExtensionPasswordKey] as? String
            
            self.activityIndicator.center = self.view.center
            self.activityIndicator.bounds.origin.y = 150
            self.activityIndicator.startAnimating()
            self.activityIndicator.hidesWhenStopped = true
            self.view.addSubview(self.activityIndicator)
            
            Auth.login(username!, username: username!, password: password!) { (token, grant, username, err) in
                if(grant == true && token != "") {
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.hidden = true
                    
                    // Performs segue to home, repeats in LoginBoxTableViewController. @todo: DRY
                    self.performSegueWithIdentifier("homeView", sender: self)
                    
                    // Sets access token on login, otherwise will log out
                    userAccessToken = token
                    
                    Answers.logLoginWithMethod("Default",
                        success: true,
                        customAttributes: [
                            "user": username
                        ])
                    
                    // Send access token and Stripe key to Apple Watch
                    if WCSession.isSupported() { //makes sure it's not an iPad or iPod
                        let watchSession = WCSession.defaultSession()
                        watchSession.delegate = self
                        watchSession.activateSession()
                        if watchSession.paired && watchSession.watchAppInstalled {
                            do {
                                try watchSession.updateApplicationContext(
                                    [
                                        "token": token
                                    ]
                                )
                                print("setting watch data")
                            } catch let error as NSError {
                                print(error.description)
                            }
                        }
                    }
                } else {
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.hidden = true
                    Answers.logLoginWithMethod("Default",
                        success: false,
                        customAttributes: [
                            "error": "Error using default login method"
                        ])
                    self.displayAlertMessage("Error logging in")
                }
            }
        })
    }
}

extension LoginViewController {
    func displayDefaultErrorAlertMessage(alertMessage:String) {
        let alertView: UIAlertController = UIAlertController(title: "Error", message: alertMessage, preferredStyle: .Alert)
        alertView.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
        self.presentViewController(alertView, animated: true, completion: nil)
    }
    
    func displayAlertMessage(alertMessage:String) {
        let alertView: UIAlertController = UIAlertController(title: "Error", message: alertMessage, preferredStyle: .Alert)
        alertView.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
        self.presentViewController(alertView, animated: true, completion: nil)
    }
    
    func displayErrorAlertMessage(alertMessage:String) {
        let alertView: UIAlertController = UIAlertController(title: "Error", message: alertMessage, preferredStyle: .Alert)
        alertView.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
        self.presentViewController(alertView, animated: true, completion: nil)
    }
}

class HTTPManager: Alamofire.Manager {
    static let sharedManager: HTTPManager = {
        //let configuration = Timberjack.defaultSessionConfiguration()
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.HTTPAdditionalHeaders = Alamofire.Manager.defaultHTTPHeaders
        let serverTrustPolicies: [String: ServerTrustPolicy] = [
            "192.168.1.182:": .DisableEvaluation
        ]
        var policy: ServerTrustPolicy = ServerTrustPolicy.DisableEvaluation
        let manager = HTTPManager(configuration: configuration,serverTrustPolicyManager: ServerTrustPolicyManager(policies: serverTrustPolicies))
        return manager
    }()
}

extension LoginViewController {
    func textFieldDidChange(textField: UITextField) {
        if textField.text?.characters.count > 0 {
            loginButton.userInteractionEnabled = true
            loginButton.setBackgroundColor(UIColor.pastelBlue(), forState: .Normal)
            loginButton.setBackgroundColor(UIColor.pastelBlue().darkerColor(), forState: .Highlighted)
            loginButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        } else {
            loginButton.userInteractionEnabled = false
            loginButton.setBackgroundColor(UIColor.pastelBlue().colorWithAlphaComponent(0.3), forState: .Normal)
            loginButton.setBackgroundColor(UIColor.pastelBlue().colorWithAlphaComponent(0.3), forState: .Highlighted)
            loginButton.setTitleColor(UIColor.whiteColor().colorWithAlphaComponent(0.5), forState: .Normal)
        }
    }
}

extension LoginViewController {
    
    //Calls this function when the tap is recognized.
    func dismissKeyboard() {
        loginButton.userInteractionEnabled = false
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        loginButton.setBackgroundColor(UIColor.pastelBlue().colorWithAlphaComponent(0.3), forState: .Normal)
        loginButton.setBackgroundColor(UIColor.pastelBlue().colorWithAlphaComponent(0.3), forState: .Highlighted)
        loginButton.setTitleColor(UIColor.whiteColor().colorWithAlphaComponent(0.5), forState: .Normal)
        
        view.endEditing(true)
    }
    
    func keyboardWillAppear(notification: NSNotification){
        loginButton.userInteractionEnabled = true
        loginButton.setBackgroundColor(UIColor.pastelBlue(), forState: .Normal)
        loginButton.setBackgroundColor(UIColor.pastelBlue().darkerColor(), forState: .Highlighted)
        loginButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
    }
    
    func keyboardWillDisappear(notification: NSNotification){
        loginButton.userInteractionEnabled = false
        loginButton.setBackgroundColor(UIColor.pastelBlue().colorWithAlphaComponent(0.3), forState: .Normal)
        loginButton.setBackgroundColor(UIColor.pastelBlue().colorWithAlphaComponent(0.3), forState: .Highlighted)
        loginButton.setTitleColor(UIColor.whiteColor().colorWithAlphaComponent(0.5), forState: .Normal)
    }
}