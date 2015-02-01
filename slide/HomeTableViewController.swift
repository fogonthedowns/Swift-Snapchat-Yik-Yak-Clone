//
//  HomeTableViewController.swift
//  slide
//
//  Created by Justin Zollars on 1/29/15.
//  Copyright (c) 2015 rmb. All rights reserved.
//

import UIKit

// the protocol, api protocol is referenced by the class below
// the method outlined is included in the class

protocol APIProtocol {
    func didReceiveResult(results: JSON)
}

class HomeTableViewController: UITableViewController, APIProtocol {
    let userObject = UserModel()
    var latitude = "1"
    var longitute = "1"
    var videoModelList: NSMutableArray = [] // This is the array that my tableView
    
    override func viewDidLoad() {
        super.viewDidLoad()
        userObject.findUser();
        userObject.apiObject.getSnaps(self.latitude,long: self.longitute, delegate:self)
        
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
        NSLog("Array Count = %u", videoModelList.count);
        return videoModelList.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath) as UITableViewCell

//        let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "VideoCell")
//        let rowData: NSDictionary = videoModelList[indexPath.row] as NSDictionary
        
       // cell.textLabel!.text = rowData["film"] as? String
        
        
        let cell = tableView.dequeueReusableCellWithIdentifier("VideoCell") as VideoCellTableViewCell
        let video: VideoModel = videoModelList[indexPath.row] as VideoModel
        cell.titleLabel.text = video.film
        
        // Grab the artworkUrl60 key to get an image URL for the app's thumbnail
//        let urlString: NSString = rowData["videoModelList"] as NSString
//        let imgURL: NSURL? = NSURL(string: urlString)
        
        // Download an NSData representation of the image at the URL
        // let imgData = NSData(contentsOfURL: imgURL!)
        // cell.imageView.image = UIImage(data: imgData!)
        
        // cell.detailTextLabel?.text = formattedPrice
        
        return cell
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
    
    func didReceiveResult(result: JSON) {
        // local array var used in this function
        var videos: NSMutableArray = []
        
        for (index: String, rowAPIresult: JSON) in result {
            
                var videoModel = VideoModel(
                    id: rowAPIresult["film"].stringValue,
                    user: rowAPIresult["userId"].stringValue
                )
                
                videos.addObject(videoModel)
            }
            
        // Set our array of new models
        videoModelList = videos
        // Make sure we are on the main thread, and update the UI.
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
              NSLog("refreshing \(self.videoModelList)")
            self.tableView.reloadData()
        })
    }

}
