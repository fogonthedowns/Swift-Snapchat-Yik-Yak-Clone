//
//  DistrictsTableViewController.swift
//  slide
//
//  Created by Justin Zollars on 2/13/15.
//  Copyright (c) 2015 rmb. All rights reserved.
//

import UIKit

let getDistrictsBecauseIhaveAUserLoaded = "com.snapAPI.getDistricts"

class DistrictsTableViewController: UITableViewController, APIProtocol {
    let userObject = UserModel()
    var latitude = "1"
    var longitute = "1"
    var districtModelList: NSMutableArray = [] // This is the array that my tableView
    var sharedInstance = VideoDataToAPI.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSLog("shared instance before%@", self.latitude)
        self.latitude = sharedInstance.latitude
        self.longitute = sharedInstance.longitute
        NSLog("shared instance before%@", self.latitude)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "loadDistricts", name: getSnapsBecauseIhaveAUserLoaded, object: nil)
        userObject.findUser();
        

        
        // Table Row Init
        self.tableView.rowHeight = 115.0
        self.title = "San Francisco"

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return districtModelList.count
    }
    
    func loadDistricts() {
        NSLog("Load districts called")
        userObject.apiObject.getDistricts(self.latitude, longitude: self.longitute, delegate:self)
    }
    
    // implement APIProtocol
    func didReceiveResult(result: JSON) {
        // local array var used in this function
        var districts: NSMutableArray = []
        
        for (index: String, rowAPIresult: JSON) in result {
            let apipolygon: AnyObject = rowAPIresult["thepolygon"].arrayObject!
            var districtModel = DistrictModel(
                polygon: apipolygon as NSArray,
                name: rowAPIresult["name"].stringValue,
                img: rowAPIresult["img"].stringValue
            )
            
            districts.addObject(districtModel)
        }
        districtModelList = districts
        // Set our array of new models
        // videoModelList = videos
        // Make sure we are on the main thread, and update the UI.
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            // NSLog("refreshing \(self.videoModelList)")
            self.tableView.reloadData()
        })
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("DistrictCell") as DistrictTableViewCell
        let district: DistrictModel = districtModelList[indexPath.row] as DistrictModel
        cell.polygon = district.polygon
        cell.titleLabel.text = district.name
        

        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let indexPath = tableView.indexPathForSelectedRow();
        
        let currentCell = tableView.cellForRowAtIndexPath(indexPath!) as DistrictTableViewCell
        
        sharedInstance.polygon = currentCell.polygon
    }


    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
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
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}
