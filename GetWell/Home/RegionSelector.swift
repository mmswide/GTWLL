//
//  RegionSelector.swift
//  GetWell
//
//  Created by mac on 7/27/16.
//  Copyright © 2016 Beakyn Company. All rights reserved.
//

import UIKit
import Localytics
import SDWebImage
import RealmSwift

class RegionSelector: UITableViewController,StackDelegate {
    private let realm = try! Realm()
    let sharedUI         = UIManager.sharedManager
    let sharedAuth       = AuthManager.sharedManager
    let sharedStack      = RealmStack.sharedStack
    let sharedLocation   = LocationManager.sharedManager
    var regions = [Region]()
//    var regions = [Region]() {
//        didSet {
//            self.tableView.reloadData()
//        }
//    }
    var sources  = [SlideObject]()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarController!.tabBar.hidden = true
        self.tableView.separatorColor = UIColor.clearColor()
        sharedStack.delegate = self
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    func regionImportDone() {
        let regionObjects = realm.objects(Region)
        sharedStack.alphabetRegions = Array(regionObjects.toArray())
        regions = sharedStack.alphabetRegions
        self.tableView.reloadData()
    }
    func delegateUpdate() {
//        if sharedStack.source.count != 0 {
//            sources  = sharedStack.source
//        }
//        if sharedStack.alphabetRegions.count != 0 {
//            regions = sharedStack.alphabetRegions
//            self.tableView.reloadData()
//        }
        let regionObjects = realm.objects(Region)
        sharedStack.alphabetRegions = Array(regionObjects.toArray())
        regions = sharedStack.alphabetRegions
        self.tableView.reloadData()
    }
    func sliderImportDone() {
//        sources = sharedStack.source
    }
    
    func regionDistanceDone() {
        let regionObjects = realm.objects(Region)
        sharedStack.alphabetRegions = Array(regionObjects.toArray())
        regions = sharedStack.alphabetRegions
        self.tableView.reloadData()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return regions.count
    }
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 135
    }
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("RegionCell", forIndexPath: indexPath) as! RegionSelectionCell
        let region = regions[indexPath.row]
        cell.lblRegionName.text = region.name
        let placeholder = sharedUI.imagePlaceholder
        if region.image != "" {
            //                    let URL = NSMutableString(string: region.image)
            //                    URL.insertString(sharedUI.ratio, atIndex: 50)
            SDWebImageManager.sharedManager().downloadImageWithURL(NSURL(string: region.image), options: .RetryFailed, progress: { (receivedSize: Int, expectedSize: Int) in
                }, completed: { (image: UIImage!, error: NSError!, cacheType: SDImageCacheType, finished: Bool, url: NSURL!) in
                    if error != nil {
                        print("Error: \(error.userInfo)")
                    }
                    if image != nil {
                        cell.imgRegion.image = image
                    }
                    else {
                        UIView.transitionWithView(cell.imgRegion
                            ,duration: 0.2
                            ,options: UIViewAnimationOptions.TransitionCrossDissolve
                            ,animations: {
                                cell.imgRegion.image = image
                            }
                            ,completion: {(finished) in
                        })
                    }
            })
        }
        else {
            cell.imgRegion.image = placeholder
        }
        return cell
    }
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let region = regions[indexPath.row]
        sharedStack.defaultRegion = region
        sharedStack.initializeDefaultRegion()
        let defRegion = DefaultRegion()
        defRegion.initWithRegion(region)
        let realm = try! Realm()
        try! realm.write({
            realm.create(DefaultRegion.self, value: defRegion, update: true)
        })
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "isRegionSelected")
        performSegueWithIdentifier("showHomeVC", sender: nil)
    }
    /*
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
