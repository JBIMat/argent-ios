//
//  ProfileMenuViewController.swift
//  paykloud-ios
//
//  Created by Sinan Ulkuatam on 3/19/16.
//  Copyright © 2016 Sinan Ulkuatam. All rights reserved.
//

import Foundation
import SafariServices

class ProfileMenuViewController: UITableViewController {
    
    @IBOutlet weak var shareCell: UITableViewCell!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add action to share cell to return to activity menu
        shareCell.targetForAction("share:", withSender: self)
        
        print("loaded profile menu")
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("selected cell \(indexPath.row)")
        if(tableView.cellForRowAtIndexPath(indexPath)!.tag == 865) {
            print("it worked")
            let activityViewController  = UIActivityViewController(
                activityItems: ["Check out this app" as NSString],
                applicationActivities: nil)
            
            presentViewController(activityViewController, animated: true, completion: nil)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier {
            if identifier == "termsView" {
                if #available(iOS 9.0, *) {
                    let svc = SFSafariViewController(URL: NSURL(string: "http://www.protonpayments.com/home")!, entersReaderIfAvailable: true)
                    self.presentViewController(svc, animated: true, completion: nil)
                } else {
                    UIApplication.sharedApplication().openURL(NSURL(string: "http://www.protonpayments.com/home")!)
                    self.dismissViewControllerAnimated(true, completion: nil)
                }
            }
            if identifier == "privacyView" {
                if #available(iOS 9.0, *) {
                    let svc = SFSafariViewController(URL: NSURL(string: "http://www.protonpayments.com/home")!, entersReaderIfAvailable: true)
                    self.presentViewController(svc, animated: true, completion: nil)
                } else {
                    UIApplication.sharedApplication().openURL(NSURL(string: "http://www.protonpayments.com/home")!)
                    self.dismissViewControllerAnimated(true, completion: nil)
                }
            }
            if identifier == "supportView" {
                if #available(iOS 9.0, *) {
                    let svc = SFSafariViewController(URL: NSURL(string: "http://www.protonpayments.com/home")!, entersReaderIfAvailable: true)
                    self.presentViewController(svc, animated: true, completion: nil)
                } else {
                    UIApplication.sharedApplication().openURL(NSURL(string: "http://www.protonpayments.com/home")!)
                    self.dismissViewControllerAnimated(true, completion: nil)
                }
            }
        }
    }
    
}