//
//  HomeViewController.swift
//  argent-ios
//
//  Created by Sinan Ulkuatam on 2/9/16.
//  Copyright © 2016 Sinan Ulkuatam. All rights reserved.
//

import UIKit
import SnapKit
import Alamofire
import SwiftyJSON
import Stripe
import DGRunkeeperSwitch
import BEMSimpleLineGraph
import UICountingLabel
import DGElasticPullToRefresh
import Gecco
import DZNEmptyDataSet

var userAccessToken = NSUserDefaults.standardUserDefaults().valueForKey("userAccessToken")

class HomeViewController: UIViewController, BEMSimpleLineGraphDelegate, BEMSimpleLineGraphDataSource, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate  {

    private var window: UIWindow?

    private var dateFormatter = NSDateFormatter()

    private var accountHistoryArray:Array<History>?
    
    private var balance:Balance = Balance(pending: 0, available: 0)
    
    private var tableView:UITableView = UITableView()
    
    private var arrayOfValues: Array<AnyObject> = []

    private var arrayOfDates: Array<AnyObject> = []
    
    private var user = User(id: "", username: "", email: "", first_name: "", last_name: "", picture: "", phone: "", plaid_access_token: "")
    
    private let lblAccountPending:UICountingLabel = UICountingLabel()

    private let lblAccountAvailable:UICountingLabel = UICountingLabel()

    private let lblAvailableDescription:UILabel = UILabel()

    private let lblPendingDescription:UILabel = UILabel()
    
    private let activityIndicator:UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)

    private let balanceSwitch = DGRunkeeperSwitch(leftTitle: "Pending", rightTitle: "Available")

    private let navBar: UINavigationBar = UINavigationBar(frame: CGRect(x: 0, y: 15, width: UIScreen.mainScreen().bounds.size.width, height: 50))

    private let graph: BEMSimpleLineGraphView = BEMSimpleLineGraphView(frame: CGRectMake(0, 90, UIScreen.mainScreen().bounds.size.width, 200))
        
    @IBAction func indexChanged(sender: DGRunkeeperSwitch) {
        if(sender.selectedIndex == 0) {
            lblAccountAvailable.removeFromSuperview()
            lblAvailableDescription.removeFromSuperview()
            
            self.addSubviewWithBounce(lblAccountPending)
            self.addSubviewWithBounce(lblPendingDescription)
        }
        if(sender.selectedIndex == 1) {
            lblAccountPending.removeFromSuperview()
            lblPendingDescription.removeFromSuperview()

            self.addSubviewWithBounce(lblAccountAvailable)
            self.addSubviewWithBounce(lblAvailableDescription)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Import TransitionTreasury in AppDelegate
    lazy var gesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(HomeViewController.swipeTransition(_:)))
        return gesture
    }()
    
    func swipeTransition(sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .Began :
            if sender.translationInView(sender.view).x < 0 {
                tabBarController?.tr_selected(1, gesture: sender)
            }
        default : break
        }
    }
    
    // VIEW DID LOAD
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addGestureRecognizer(gesture)

        definesPresentationContext = true

        configureView()
        
        loadData()
    }
    
    // VIEW DID APPEAR
    override func viewDidAppear(animated: Bool) {
        self.view.addSubview(balanceSwitch)
        self.view.bringSubviewToFront(balanceSwitch)
        UITextField.appearance().keyboardAppearance = .Light
        UIStatusBarStyle.LightContent
    }
    
    func presentTutorial(sender: AnyObject) {
        let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("TutorialHomeViewController") as! TutorialHomeViewController
        viewController.alpha = 0.5
        presentViewController(viewController, animated: true, completion: nil)
    }
    
    override func viewDidDisappear(animated: Bool) {
        balanceSwitch.removeFromSuperview()
    }
    
    func dateRangeSegmentControl(segment: UISegmentedControl) {
        if segment.selectedSegmentIndex == 0 {
            History.getHistoryArrays({ (_1d, _2w, _1m, _3m, _6m, _1y, _5y, err) in
                self.arrayOfValues = _1d!
                self.graph.reloadGraph()
            })
        }
        else if segment.selectedSegmentIndex == 1 {
            History.getHistoryArrays({ (_1d, _2w, _1m, _3m, _6m, _1y, _5y, err) in
                self.arrayOfValues = _1m!
                self.graph.reloadGraph()
            })
        }
        else if segment.selectedSegmentIndex == 2 {
            History.getHistoryArrays({ (_1d, _2w, _1m, _3m, _6m, _1y, _5y, err) in
                self.arrayOfValues = _3m!
                self.graph.reloadGraph()
            })
        }
        else if segment.selectedSegmentIndex == 3 {
            History.getHistoryArrays({ (_1d, _2w, _1m, _3m, _6m, _1y, _5y, err) in
                self.arrayOfValues = _6m!
                self.graph.reloadGraph()
            })
        }
        else if segment.selectedSegmentIndex == 4 {
            History.getHistoryArrays({ (_1d, _2w, _1m, _3m, _6m, _1y, _5y, err) in
                self.arrayOfValues = _1y!
                self.graph.reloadGraph()
            })
        }
    }
    
    //Changing Status Bar
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    func loadData() {
        
        // IMPORTANT: load new access token on home load, otherwise the old token will be requested to the server
        userAccessToken = NSUserDefaults.standardUserDefaults().valueForKey("userAccessToken")
        
        activityIndicator.center = tableView.center
        activityIndicator.startAnimating()
        activityIndicator.hidesWhenStopped = true
        self.view.addSubview(activityIndicator)
        
        if((userAccessToken) != nil) {
            // Get stripe data
            loadStripe({ (balance, err) in
                
                let pendingBalance = balance.pending
                let availableBalance = balance.available
                
                NSNotificationCenter.defaultCenter().postNotificationName("balance", object: nil, userInfo: ["available_bal":availableBalance,"pending_bal":pendingBalance])

                let formatter = NSNumberFormatter()
                formatter.numberStyle = .CurrencyStyle
                formatter.locale = NSLocale.currentLocale() // This is the default
                
                if(pendingBalance != 0 && availableBalance != 0) {
                    self.lblAccountPending.countFrom(CGFloat(pendingBalance)/100-600, to: CGFloat(pendingBalance)/100)
                    self.lblAccountPending.textColor = UIColor.slateBlue()
                    self.lblAccountPending.format = "%.2f"
                    self.lblAccountPending.animationDuration = 0.5
                    self.lblAccountPending.method = UILabelCountingMethod.EaseInOut
                    self.lblAccountPending.completionBlock = {
                        let pendingBalanceNum = formatter.stringFromNumber(pendingBalance/100)
                        self.lblAccountPending.text = pendingBalanceNum
                    }
    
                    self.lblAccountAvailable.countFrom((CGFloat(Float(availableBalance))/100)-100, to: CGFloat(Float(availableBalance))/100)
                    self.lblAccountAvailable.textColor = UIColor.slateBlue()
                    self.lblAccountAvailable.format = "%.2f"
                    self.lblAccountAvailable.animationDuration = 1.0
                    self.lblAccountAvailable.method = UILabelCountingMethod.EaseInOut
                    self.lblAccountAvailable.completionBlock = {
                        let availableBalanceNum = formatter.stringFromNumber(availableBalance/100)
                        self.lblAccountAvailable.text = availableBalanceNum
                    }
                }
            })
            
            // Get user account history
            loadAccountHistory { (historyArr, error) in
                if error != nil {
                    print(error)
                }
                // sets up the empty data set view after load if no data is present
                self.tableView.emptyDataSetSource = self
                self.tableView.emptyDataSetDelegate = self
                self.tableView.tableFooterView = UIView()
                self.activityIndicator.stopAnimating()

            }
            
            History.getHistoryArrays({ (_1d, _2w, _1m, _3m, _6m, _1y, _5y, err) in
                self.arrayOfValues = _3m!
                self.graph.reloadGraph()
            })
            
            // Get user profile
            User.getProfile({ (user, error) in
                
                let userImageView: UIImageView = UIImageView(frame: CGRectMake(20, 40, 40, 40))
                userImageView.autoresizingMask = [.FlexibleLeftMargin, .FlexibleRightMargin]
                userImageView.backgroundColor = UIColor.groupTableViewBackgroundColor()
                userImageView.layer.cornerRadius = userImageView.frame.size.height/2
                userImageView.layer.masksToBounds = true
                userImageView.clipsToBounds = true
                userImageView.layer.borderWidth = 0
                userImageView.layer.borderColor = UIColor(rgba: "#fffa").CGColor
                
                if user!.picture != "" {
                    Timeout(0.3) {
                        let img = UIImage(data: NSData(contentsOfURL: NSURL(string: (user!.picture))!)!)!
                        userImageView.image = img
                        self.addSubviewWithBounce(userImageView)
                    }
                } else {
                    Timeout(0.3) {
                        let img = UIImage(named: "PersonThumb")
                        userImageView.image = img
                        self.addSubviewWithBounce(userImageView)
                    }
                }
                
                if(error != nil) {
                    print(error)
                    // check if user logged in, if not send to login
                    print("user not logged in x")
                    self.logout()
                }
            })

        } else {
            // check if user logged in, if not send to login
            print("user not logged in y")
            self.logout()
        }
    }

    func configureView() {
        
        let screen = UIScreen.mainScreen().bounds
        let screenWidth = screen.size.width
        let screenHeight = screen.size.height
        
        let img: UIImage = UIImage(named: "Logo")!
        let logoImageView: UIImageView = UIImageView(frame: CGRectMake(20, 31, 40, 40))
        logoImageView.autoresizingMask = [.FlexibleLeftMargin, .FlexibleRightMargin]
        logoImageView.backgroundColor = UIColor.groupTableViewBackgroundColor()
        logoImageView.layer.cornerRadius = logoImageView.frame.size.height/2
        logoImageView.layer.masksToBounds = true
        logoImageView.clipsToBounds = true
        logoImageView.image = img
        logoImageView.layer.borderWidth = 2
        logoImageView.layer.borderColor = UIColor(rgba: "#fffa").CGColor
        // self.view.addSubview(logoImageView)
        
        // Blurview
        let bg: UIImageView = UIImageView(frame: CGRectMake(0, 0, screenWidth, screenHeight))
        bg.contentMode = .ScaleAspectFill
        bg.autoresizingMask = [.FlexibleLeftMargin, .FlexibleRightMargin]
        bg.layer.masksToBounds = true
        bg.clipsToBounds = true
        bg.backgroundColor = UIColor.offWhite()
        self.view.addSubview(bg)
        self.view.sendSubviewToBack(bg)

        graph.dataSource = self
        graph.frame = CGRect(x: 0, y: 110, width: screenWidth, height: 150)
        graph.colorTop = UIColor.clearColor()
        graph.colorBottom = UIColor.offWhite()
        graph.colorLine = UIColor.brandGreen()
        graph.colorPoint = UIColor.brandGreen()
        graph.colorBackgroundPopUplabel = UIColor.whiteColor()
        graph.delegate = self
        graph.widthLine = 2
        graph.displayDotsWhileAnimating = true
        graph.enablePopUpReport = true
        graph.noDataLabelColor = UIColor.mediumBlue()
        graph.enableTouchReport = true
        graph.enableBezierCurve = true
        graph.colorTouchInputLine = UIColor.lightBlue()
        graph.layer.masksToBounds = true
        self.view!.addSubview(graph)
        
        let dateRangeSegment: UISegmentedControl = UISegmentedControl(items: ["1D", "1M", "3M", "6M", "1Y"])
        dateRangeSegment.frame = CGRect(x: 15.0, y: 230.0, width: view.bounds.width - 30.0, height: 30.0)
        //        var y_co: CGFloat = self.view.frame.size.height - 100.0
        //        dateRangeSegment.frame = CGRectMake(10, y_co, width-20, 50.0)
        dateRangeSegment.selectedSegmentIndex = 2
        dateRangeSegment.removeBorders()
        dateRangeSegment.addTarget(self, action: #selector(HomeViewController.dateRangeSegmentControl(_:)), forControlEvents: .ValueChanged)
        self.view!.addSubview(dateRangeSegment)
        
        navBar.barTintColor = UIColor.clearColor()
        navBar.translucent = true
        navBar.tintColor = UIColor.mediumBlue()
        navBar.backgroundColor = UIColor.clearColor()
        navBar.shadowImage = UIImage()
        navBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        navBar.titleTextAttributes = [
            NSForegroundColorAttributeName : UIColor.whiteColor(),
            NSFontAttributeName : UIFont(name: "Avenir-Light", size: 18)!
        ]
        self.view.addSubview(navBar)
        self.view.sendSubviewToBack(navBar)
        let navItem = UINavigationItem(title: "")
        navBar.setItems([navItem], animated: true)
        
        balanceSwitch.backgroundColor = UIColor.clearColor()
        balanceSwitch.selectedBackgroundColor = UIColor.mediumBlue().colorWithAlphaComponent(0.5)
        balanceSwitch.titleColor = UIColor.mediumBlue()
        balanceSwitch.selectedTitleColor = UIColor.whiteColor()
        balanceSwitch.titleFont = UIFont.systemFontOfSize(12)
        balanceSwitch.frame = CGRect(x: view.bounds.width - 185.0, y: 40, width: 180, height: 35.0)
        //autoresizing so it stays at top right (flexible left and flexible bottom margin)
        balanceSwitch.autoresizingMask = [.FlexibleLeftMargin, .FlexibleRightMargin]
        balanceSwitch.bringSubviewToFront(balanceSwitch)
        balanceSwitch.addTarget(self, action: #selector(HomeViewController.indexChanged(_:)), forControlEvents: .ValueChanged)
        
        let headerView: UIView = UIView(frame: CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 40))
        headerView.backgroundColor = UIColor.clearColor()
        let headerViewTitle: UILabel = UILabel()
        headerViewTitle.frame = CGRect(x: 18, y: 15, width: screenWidth, height: 30)
        headerViewTitle.text = "Transaction History"
        headerViewTitle.font = UIFont(name: "Avenir-Light", size: 16)
        headerViewTitle.textAlignment = .Left
        headerViewTitle.textColor = UIColor.mediumBlue()
        headerView.addSubview(headerViewTitle)
        
        let tutorialButton:UIButton = UIButton()
        tutorialButton.frame = CGRect(x: screenWidth-40, y: 19, width: 22, height: 22)
        tutorialButton.setImage(UIImage(named: "ic_question"), forState: .Normal)
        tutorialButton.setTitle("Tuts", forState: .Normal)
        tutorialButton.setTitleColor(UIColor.redColor(), forState: .Normal)
        tutorialButton.addTarget(self, action: #selector(HomeViewController.presentTutorial(_:)), forControlEvents: .TouchUpInside)
        tutorialButton.addTarget(self, action: #selector(HomeViewController.presentTutorial(_:)), forControlEvents: .TouchUpOutside)
        headerView.addSubview(tutorialButton)
        headerView.bringSubviewToFront(tutorialButton)
        
        tableView.frame = CGRect(x: 0, y: 270, width: screenWidth, height: screenHeight-315)
        tableView.tableHeaderView = headerView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.showsVerticalScrollIndicator = false
        self.view.addSubview(tableView)
        
        lblAccountAvailable.tintColor = UIColor.darkBlue()
        lblAccountAvailable.frame = CGRectMake(20, 81, 200, 40)
        let str0 = NSAttributedString(string: "$0.00", attributes:
            [
                NSFontAttributeName: UIFont(name: "Avenir-Book", size: 18)!,
                NSForegroundColorAttributeName:UIColor.slateBlue()
            ])
        lblAccountAvailable.attributedText = str0
        
        lblAccountPending.tintColor = UIColor.darkBlue()
        lblAccountPending.frame = CGRectMake(20, 81, 200, 40)
        let str1 = NSAttributedString(string: "$0.00", attributes:
            [
                NSFontAttributeName: UIFont(name: "Avenir-Book", size: 18)!,
                NSForegroundColorAttributeName:UIColor.slateBlue()
            ])
        lblAccountPending.attributedText = str1
        self.addSubviewWithBounce(lblAccountPending)
        
        lblAvailableDescription.frame = CGRectMake(20, 106, 200, 40)
        let str2 = NSAttributedString(string: "Available Balance", attributes:
            [
                NSFontAttributeName: UIFont.systemFontOfSize(12),
                NSForegroundColorAttributeName:UIColor.slateBlue().colorWithAlphaComponent(0.5)
            ])
        lblAvailableDescription.attributedText = str2
        // add available label initially
        
        lblPendingDescription.frame = CGRectMake(20, 106, 200, 40)
        let str3 = NSAttributedString(string: "Pending Balance", attributes:
            [
                NSFontAttributeName: UIFont.systemFontOfSize(12),
                NSForegroundColorAttributeName:UIColor.slateBlue().colorWithAlphaComponent(0.5)
            ])
        lblPendingDescription.attributedText = str3
        self.addSubviewWithBounce(lblPendingDescription)
        
        let loadingView = DGElasticPullToRefreshLoadingViewCircle()
        loadingView.tintColor = UIColor.slateBlue().colorWithAlphaComponent(0.5)
        tableView.dg_addPullToRefreshWithActionHandler({ [weak self] () -> Void in
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(1.5 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
                    self?.tableView.dg_stopLoading()
                    self?.loadAccountHistory({ (_: [History]?, NSError) in
                })
            })
            }, loadingView: loadingView)
        tableView.dg_setPullToRefreshFillColor(graph.colorBottom)
        tableView.dg_setPullToRefreshBackgroundColor(tableView.backgroundColor!)
        
        // Transparent navigation bar
        // self.navigationController?.navigationBar.barTintColor = UIColor(rgba: "#1a8ef5")
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.translucent = true
        self.navigationController?.navigationBar.titleTextAttributes = [
            NSForegroundColorAttributeName : UIColor.mediumBlue(),
            NSFontAttributeName : UIFont(name: "Avenir-Light", size: 18.0)!
        ]

    }
    
    func loadAccountHistory(completionHandler: ([History]?, NSError?) -> ()) {
        History.getAccountHistory({ (transactions, error) in
            if error != nil {
                let alert = UIAlertController(title: "Error", message: "Could not load history \(error?.localizedDescription)", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            }
            self.accountHistoryArray = transactions
            completionHandler(transactions!, error)
            self.tableView.reloadData()
        })
    }
    
    func loadStripe(completionHandler: (Balance, NSError?) -> ()) {
        // Set account balance label
        
        Balance.getStripeBalance({ (balance, error) in
            if error != nil {
                let alert = UIAlertController(title: "Error", message: "Could not load history \(error?.localizedDescription)", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            }
            self.balance = balance!
            completionHandler(balance!, error)
        })
    }

    // LOGOUT
    func logout() {
        NSUserDefaults.standardUserDefaults().setValue("", forKey: "userAccessToken")
        NSUserDefaults.standardUserDefaults().synchronize();
        
        // go to login view
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let loginVC = sb.instantiateViewControllerWithIdentifier("LoginViewController")
        loginVC.modalTransitionStyle = .CrossDissolve
        let root = UIApplication.sharedApplication().keyWindow?.rootViewController
        root!.presentViewController(loginVC, animated: true, completion: { () -> Void in
        })
    }
    
    // Animation
    
    func addSubviewWithBounce(view: UIView) {
        view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.001, 0.001)
        self.view.addSubview(view)
        UIView.animateWithDuration(0.3 / 1.5, animations: {() -> Void in
            view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.0, 1.0)
            }, completion: {(finished: Bool) -> Void in
                UIView.animateWithDuration(0.3 / 2, animations: {() -> Void in
                    }, completion: {(finished: Bool) -> Void in
                        UIView.animateWithDuration(0.3 / 2, animations: {() -> Void in
                            view.transform = CGAffineTransformIdentity
                        })
                })
        })
    }
    
    // MARK: BEM Graph Delegate Methods
    func numberOfPointsInLineGraph(graph: BEMSimpleLineGraphView) -> Int {
        return Int(self.arrayOfValues.count)
        
    }
    
    func lineGraph(graph: BEMSimpleLineGraphView, valueForPointAtIndex index: Int) -> CGFloat {
        return CGFloat(self.arrayOfValues[index] as! NSNumber)
    }
    
    func numberOfGapsBetweenLabelsOnLineGraph(graph: BEMSimpleLineGraphView) -> Int {
        return 2
    }
    
    // MARK: TableView Delegate
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.accountHistoryArray?.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        self.tableView.registerNib(UINib(nibName: "HistoryCustomCell", bundle: nil), forCellReuseIdentifier: "idCellCustomHistory")

        let cell = self.tableView.dequeueReusableCellWithIdentifier("idCellCustomHistory") as! HistoryCustomCell

        let item = self.accountHistoryArray?[indexPath.row]
        cell.selectionStyle = UITableViewCellSelectionStyle.None
        cell.lblAmount?.text = ""
        cell.lblDate?.text = ""
        if let amount = item?.amount {
            if Double(amount)!/100 < 0 {
                // cell.lblCreditDebit?.text = "Debit"
                cell.img.image = UIImage(named: "ic_arrow_down")
                cell.lblAmount?.textColor = UIColor.brandRed()
            } else {
                // cell.lblCreditDebit?.text = "Credit"
                cell.img.image = UIImage(named: "ic_arrow_up")
                cell.lblAmount?.textColor = UIColor.brandGreen()
            }
            let formatter = NSNumberFormatter()
            formatter.numberStyle = .CurrencyStyle
            // formatter.locale = NSLocale.currentLocale() // This is the default
            let amt = formatter.stringFromNumber(Float(amount)!/100)
            cell.lblAmount?.text = amt!
        }
        if let date = item?.created
        {
            if(!date.isEmpty || date != "") {
                let converted_date = NSDate(timeIntervalSince1970: Double(date)!)
                dateFormatter.dateStyle = .ShortStyle
                dateFormatter.dateFormat = "MMM dd"
                let formatted_date = dateFormatter.stringFromDate(converted_date)
                cell.lblDate?.layer.cornerRadius = 10
                cell.lblDate?.layer.borderColor = UIColor.lightGrayColor().colorWithAlphaComponent(0.5).CGColor
                cell.lblDate?.layer.borderWidth = 1
                cell.lblDate?.text = String(formatted_date) //+ " / uid " + uid
            } else {
                
            }
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // self.performSegueWithIdentifier("historyDetailView", sender: self)
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 80.0
    }
    
    // Scrollview

    func scrollViewDidScroll(scrollView: UIScrollView) {
//        var rect: CGRect = self.view.frame
//        rect.origin.y = -scrollView.contentOffset.y
//        self.view.frame = rect
    }
    
    // Delegate: DZNEmptyDataSet
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "Transactions"
        let attrs = [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)]
        return NSAttributedString(string: str, attributes: attrs)
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "No transactions have occurred yet."
        let attrs = [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleBody)]
        return NSAttributedString(string: str, attributes: attrs)
    }
    
    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: "IconEmptyMoneyBag")
    }
    
    func buttonTitleForEmptyDataSet(scrollView: UIScrollView!, forState state: UIControlState) -> NSAttributedString! {
        let str = "Create your first billing plan"
        let attrs = [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleCallout)]
        return NSAttributedString(string: str, attributes: attrs)
    }
    
    func emptyDataSetDidTapButton(scrollView: UIScrollView!) {
        let viewController:UIViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("RecurringBillingViewController") as! RecurringBillingViewController
        self.presentViewController(viewController, animated: true, completion: nil)
    }
}