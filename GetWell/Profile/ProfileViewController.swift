//
//  ProfileViewController.swift
//  Copyright © 2016 Get Well Company. All rights reserved.
//

import UIKit
import Intercom
import Localytics
import RealmSwift
import Armchair

class ProfileViewController: UITableViewController {
    
    let realm = try! Realm()
    let sharedUI       = UIManager.sharedManager
    let sharedAuth     = AuthManager.sharedManager
    let sharedLocation = LocationManager.sharedManager
    let sharedStack      = RealmStack.sharedStack
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    @IBOutlet weak var profileAvatarView: UIImageView!
    @IBOutlet weak var profileNameLabel: UILabel!
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var languageLabel: UILabel!
    

    override func viewDidLoad() {
        setLanguageLabel()
        super.viewDidLoad()
        tableView.backgroundColor = sharedUI.colorBackground
        clearsSelectionOnViewWillAppear = true
        let version = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as? String
        versionLabel.text = "Version \(version!)"        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        Localytics.tagScreen("Profile")
    }
    
    override func viewWillAppear(animated: Bool) {
        configureProfileView()
        self.tableView.reloadData()
        super.viewWillAppear(animated)
    }
    
    func setLanguageLabel() {
        var languageLabelText = ""
        
        // Only set it if we are using Armchair localizations
        if !Armchair.useMainAppBundleForLocalizations() {
            let currentLocalization: NSString = NSBundle.mainBundle().preferredLocalizations[0] as NSString
            // Only set it if we are using a different language than this apps development language
            if let developmentLocalization = NSBundle.mainBundle().developmentLocalization {
                if currentLocalization != developmentLocalization {
                    languageLabelText = currentLocalization as String
                    if let displayName = NSLocale(localeIdentifier: currentLocalization as String).displayNameForKey(NSLocaleIdentifier, value:currentLocalization) {
                        languageLabelText = "\(displayName): \(currentLocalization)"
                    }
                }
            }
        }
//        languageLabel.text = languageLabelText
    }

    func configureProfileView() {
        self.profileAvatarView.clipsToBounds = true
        self.profileAvatarView.layer.cornerRadius = 48
        if sharedAuth.isLoggedIn() {
            sharedAuth.userProfile { (profile) -> Void in
                self.profileAvatarView.sd_setImageWithURL(profile.picture)
                self.profileAvatarView.contentMode = .ScaleAspectFill
                self.profileNameLabel.text = profile.name
            }
        }
        else {
            self.profileAvatarView.image           = sharedUI.imageProfile
            self.profileAvatarView.tintColor       = UIColor.whiteColor()
            self.profileAvatarView.contentMode     = .ScaleAspectFill
            self.profileAvatarView.backgroundColor = UIColor (red: 0.6939, green: 0.6887, blue: 0.7271, alpha: 1.0)
            self.profileNameLabel.text = "Google or Facebook"
        }
        self.profileNameLabel.kerning = 0.33
    }

    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row == 3 {
            let searches = realm.objects(Search)
            if searches.count == 0 {
                cell.userInteractionEnabled = false
                cell.contentView.alpha = 0.4
            }
            else {
                cell.userInteractionEnabled = true
                cell.contentView.alpha = 1.0
            }
        }
        if indexPath.row != 3 && indexPath.row != 4 && indexPath.row != 5 && indexPath.row != 6 {
            cell.layoutMargins      = UIEdgeInsetsZero
            let accessoryView       = UIImageView(image: sharedUI.imageDisclose)
            accessoryView.tintColor = sharedUI.colorMain
            cell.accessoryView      = accessoryView
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        if indexPath.row == 0 {
            performSegueWithIdentifier("showWebViewSegue", sender:Constants.GWAPI.helpURL)
        }
        if indexPath.row == 1 {
            performSegueWithIdentifier("showWebViewSegue", sender:Constants.GWAPI.acknowledgmentURL)
        }
        if indexPath.row == 2 {
            performSegueWithIdentifier("showWebViewSegue", sender:Constants.GWAPI.legalURL)
        }
        if indexPath.row == 3 {
            showAlertForSearch({ (status) in
                if status {
                    self.realm.beginWrite()
                    self.realm.delete(self.realm.objects(Search))
                    try! self.realm.commitWrite()
                    self.tableView.reloadData()
                }
            })
        }
        if indexPath.row == 4 {
            navigateHomeView()
        }
        if indexPath.row == 5 {
            rateThisApp()
        }
        if indexPath.row == 6 {
            if sharedAuth.isLoggedIn() {
                showAlertForLogout({ (status) in
                    if status {
                        Intercom.reset()
                        self.sharedAuth.keychain.clearAll()
                        self.sharedAuth.lock.clearSessions()
                        self.configureProfileView()
                        self.appDelegate.logoutAuth()
                        NSUserDefaults.standardUserDefaults().setBool(false, forKey: "isRegionSelected")
                        Localytics.tagCustomerLoggedOut([:])
                    }
                    else {}
                })
            }
        }
    }
    
    func resetAppReviewManager() {
        Armchair.resetDefaults()
    }
    
    func rateThisApp() {
        resetAppReviewManager()
        // The AppID is the only required setup
       Armchair.appID(Pages)
        // Debug means that it will popup on the next available change
        Armchair.debugEnabled(true)
        // This overrides the default of NO in iOS 7. Instead of going to the review page in the App Store App,
        //  the user goes to the main page of the app, in side of this app. Downsides are that it doesn't go directly to
        //  reviews and doesn't take affiliate codes
        Armchair.opensInStoreKit(true)
        // If you are opening in StoreKit, you can change whether or not to animated the push of the View Controller
        Armchair.usesAnimation(true)
        // true here means it is ok to show, but it doesn't matter because we have debug on.
        Armchair.userDidSignificantEvent(true)
    }
    
    func navigateHomeView() {
        sharedStack.initializeDefaultRegion()
        NSUserDefaults.standardUserDefaults().setBool(false, forKey: "isRegionSelected")
//        tabBarController?.selectedIndex = 0
//        let vwController = tabBarController?.selectedViewController as! UINavigationController
////        vwController.popToRootViewControllerAnimated(true);
//        UIView.transitionWithView(vwController.view, duration: 0.8, options: .TransitionFlipFromLeft, animations: {
//            vwController.popToRootViewControllerAnimated(false)
//            }, completion: nil)
        self.appDelegate.navigateFirstView()
    }
    func showAlertForSearch(completion:(status: Bool) -> Void) {
        let alert = UIAlertController(
            title: "Are you sure?",
            message: nil,
            preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (test) -> Void in
            completion(status: false)
            self.dismissViewControllerAnimated(true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "Yes, I'm sure", style: .Default, handler: { (test) -> Void in
            completion(status: true)
            self.dismissViewControllerAnimated(true, completion: nil)
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func showAlertForLogout(completion:(status: Bool) -> Void) {
        let alert = UIAlertController(
            title: "Are you sure?",
            message: nil,
            preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (test) -> Void in
            completion(status: false)
            self.dismissViewControllerAnimated(true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "Log out", style: .Default, handler: { (test) -> Void in
            completion(status: true)
            self.dismissViewControllerAnimated(true, completion: nil)
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showWebViewSegue" {
            let controller = segue.destinationViewController as? WebViewController
            controller?.hidesBottomBarWhenPushed = true
            let URL = sender as? String
            controller?.URL = NSURL(string: URL!)
            if URL!.containsString("legal") { controller?.title = "Legal" }
            if URL!.containsString("help")  { controller?.title = "Help"  }
            if URL!.containsString("acknowledgment")  { controller?.title = "Acknowledgments"  }

        }
    }

}