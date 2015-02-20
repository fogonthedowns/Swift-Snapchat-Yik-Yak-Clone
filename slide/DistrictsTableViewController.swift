//
//  DistrictsTableViewController.swift
//  slide
//
//  Created by Justin Zollars on 2/13/15.
//  Copyright (c) 2015 rmb. All rights reserved.
//

import UIKit
import MediaPlayer

let getDistrictsBecauseIhaveAUserLoaded = "com.snapAPI.getDistricts"

class DistrictsTableViewController: UITableViewController, APIProtocol {
    let userObject = UserModel()
    var latitude = "1"
    var longitute = "1"
    var districtModelList: NSMutableArray = [] // This is the array that my tableView
    var sharedInstance = VideoDataToAPI.sharedInstance
    
    // movie player code
    var moviePlayer:MPMoviePlayerController!
    var moviePlayerTwo:MPMoviePlayerController!
    let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
    var userIntendsToWatchVideo = false
    var currentIndex = 0
    
    // file download 
    var session: NSURLSession?
    var downloadTask: NSURLSessionDownloadTask?
    var videoModelList: NSMutableArray = [] // This is the array that my tableView
    var playList: NSMutableArray = [] // list of urls to play
    
    
   
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "loadSnaps", name: getSnapsBecauseIhaveAUserLoaded, object: nil)
        userObject.findUser();

        NSLog("shared instance before%@", self.latitude)
        self.latitude = sharedInstance.latitude
        self.longitute = sharedInstance.longitute
        NSLog("shared instance before%@", self.latitude)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "loadDistricts", name: getSnapsBecauseIhaveAUserLoaded, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "switchPlayerOrQuit", name: MPMoviePlayerPlaybackDidFinishNotification, object: nil)
        userObject.findUser();
        
    
        // Table Row Init
        self.tableView.rowHeight = 115.0
        self.title = "San Francisco"
        
        let longpress = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
        longpress.minimumPressDuration = 0.35
        tableView.addGestureRecognizer(longpress)
        
        var refresh = UIRefreshControl()
        refresh.addTarget(self, action: "pullToLoadDistricts:", forControlEvents:.ValueChanged)
        self.refreshControl = refresh

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
        var videos: NSMutableArray = []
        
        for (index: String, rowAPIresult: JSON) in result {
            if (rowAPIresult["film"] != nil) {
                // VideoModel
                var videoModel = VideoModel(
                    id: rowAPIresult["film"].stringValue,
                    user: rowAPIresult["userId"].stringValue,
                    img: rowAPIresult["img"].stringValue,
                    description: rowAPIresult["description"].stringValue,
                    votes: rowAPIresult["votes"].count,
                    comments: processComments(rowAPIresult["comments"]),
                    voters: processVotes(rowAPIresult["votes"]),
                    flags: rowAPIresult["flags"].count
                )
                videoModel.findOrCreate()
                if (videoModel.flags >= 2){
                   // skip flagged videos
                } else {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.start(videoModel.film)
                    })
                    videos.addObject(videoModel)
                } // end video
                // Set our array of new models
                videoModelList = videos
                
            } else { // there is no ["film"] object from the returned protocol call
                // DistrictModel
                var districtModel = DistrictModel(
                    name: rowAPIresult["name"].stringValue,
                    img: rowAPIresult["coverphoto"].stringValue
                )
                districts.addObject(districtModel)
                districtModelList = districts
                // Set our array of new models
                // videoModelList = videos
                // Make sure we are on the main thread, and update the UI.
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.tableView.reloadData()
                })
                
            } // if (rowAPIresult["film"])
        } // for JSON result
    } // didReceiveJSONResult
    
    func processComments(comments:JSON) -> NSMutableDictionary {
        var commentDictionary:NSMutableDictionary = [:]
        
        for (index: String, rowAPIresult: JSON) in comments {
            commentDictionary.setObject(rowAPIresult["body"].stringValue, forKey: rowAPIresult["_id"]["$oid"].stringValue)
        }
        return commentDictionary as NSMutableDictionary
    }
    
    func processVotes(votes:JSON) -> NSMutableDictionary {
        var voteDictionary:NSMutableDictionary = [:]
        
        for (index: String, rowAPIresult: JSON) in votes {
            voteDictionary.setObject(rowAPIresult["user_id"].stringValue, forKey: rowAPIresult["_id"]["$oid"].stringValue)
        }
        return voteDictionary as NSMutableDictionary
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("DistrictCell") as DistrictTableViewCell
        let district: DistrictModel = districtModelList[indexPath.row] as DistrictModel
        cell.hood = district.name
        cell.titleLabel.text = district.name
   
        // Load Images Asynchroniously
        let backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        dispatch_async(backgroundQueue, {
            SGImageCache.getImageForURL(district.img) { image in
                if image != nil {
                    dispatch_async(dispatch_get_main_queue(), {
                        
                        // cell.coverPhoto.contentMode = UIViewContentMode.ScaleAspectFill
                        cell.coverPhoto.image = image;
                        cell.coverPhoto.layer.cornerRadius = cell.coverPhoto.frame.size.width  / 2;
                        cell.coverPhoto.clipsToBounds = true;
                    })
                    
                }
            }
        })
        

        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let indexPath = tableView.indexPathForSelectedRow();
        
        let currentCell = tableView.cellForRowAtIndexPath(indexPath!) as DistrictTableViewCell
        
        sharedInstance.hood = currentCell.titleLabel.text
        NSNotificationCenter.defaultCenter().postNotificationName(didFinishUploadPresentNewPage, object: self)
    }
    
    func pullToLoadDistricts(sender:AnyObject) {
        self.loadDistricts()
        self.tableView.reloadData()
        self.refreshControl?.endRefreshing()
    }
    
    func handleLongPress(sender:UILongPressGestureRecognizer!) {
        let localLongPress = sender as UILongPressGestureRecognizer
        var locationInView = localLongPress.locationInView(tableView)
        
        // returns nil in the case of last cell
        // but strangely only on EndedState
        var indexPath = tableView.indexPathForRowAtPoint(locationInView)
        if indexPath != nil {
            let cell = self.tableView.cellForRowAtIndexPath(indexPath!) as DistrictTableViewCell
            println("Long press Block .................");
            
            let filePath = self.playList[0] as NSString
            
            if (sender.state == UIGestureRecognizerState.Ended) {
                self.userIntendsToWatchVideo = false
                self.currentIndex = 0
                println("Long press Ended");
                self.moviePlayer.stop()
                self.moviePlayer.view.removeFromSuperview()
//                self.moviePlayerTwo.stop()
//                self.moviePlayerTwo.view.removeFromSuperview()
                self.tableView.reloadData()
                navigationController?.navigationBarHidden = false
                UIApplication.sharedApplication().statusBarHidden=false;
            } else if (sender.state == UIGestureRecognizerState.Began) {
                 self.userIntendsToWatchVideo = true
                println("Long press detected.");
//                let path = NSBundle.mainBundle().pathForResource("video", ofType:"m4v")
                let url = NSURL.fileURLWithPath(filePath)
                self.moviePlayer = MPMoviePlayerController(contentURL: url)
                if var player = self.moviePlayer {
                    navigationController?.navigationBarHidden = true
                    UIApplication.sharedApplication().statusBarHidden=true
                    player.view.frame = self.view.bounds
                    player.prepareToPlay()
                    player.scalingMode = .AspectFill
                    player.controlStyle = .None
                    self.tableView.addSubview(player.view)
                }
            }
            // HACK
        } else {
            println("HACK - Long press Ended");
            self.moviePlayer.stop()
            self.moviePlayer.view.removeFromSuperview()
            self.tableView.reloadData()
            navigationController?.navigationBarHidden = false
            UIApplication.sharedApplication().statusBarHidden=false;
        }
    }
    
    func switchPlayerOrQuit(){
        println("FIRED! :)")
        if (currentIndex <= self.playList.count) {
            self.moviePlayer.view.removeFromSuperview()
            if  (self.userIntendsToWatchVideo == true) {
                let filePath = self.playList[self.currentIndex] as NSString
                let url = NSURL.fileURLWithPath(filePath)
                self.moviePlayer = MPMoviePlayerController(contentURL: url)
                if var player = self.moviePlayer {
                    navigationController?.navigationBarHidden = true
                    UIApplication.sharedApplication().statusBarHidden=true
                    player.view.frame = self.view.bounds
                    player.prepareToPlay()
                    player.scalingMode = .AspectFill
                    player.controlStyle = .None
                    self.tableView.addSubview(player.view)
                }
            }
        currentIndex += 1
        }
    }

    func determineFilePath(file:NSString)-> NSString {
        let documentsPath = paths.first as? String
        let filePath = documentsPath! + "/" + file
        return filePath
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
    
    // ------------------------------------------
    // Lots of code
    
    func start(s3downloadname: NSString) {
        
        let filePath = determineFilePath(s3downloadname)
        // if the file exists return, don't start an asynch download
        if NSFileManager.defaultManager().fileExistsAtPath(filePath) {
            self.playList.addObject(filePath)
            NSLog("FILE ALREADY DOWNLOADED")
            return;
        }
        
        if (self.downloadTask != nil) {
            // push current downloadtask into an array
            // array processes recursive function
            sharedInstance.listOfVideosToDownload.addObject(s3downloadname)
            // NSLog("videos in array %@", sharedInstance.listOfVideosToDownload)
            return;
        }
        
        
        // NSLog("------------------------------- filePath -----------------%@", filePath)
        
        sharedInstance.downloadName = s3downloadname
        let getPreSignedURLRequest = AWSS3GetPreSignedURLRequest()
        getPreSignedURLRequest.bucket = S3BucketName
        getPreSignedURLRequest.key = s3downloadname
        getPreSignedURLRequest.HTTPMethod = AWSHTTPMethod.GET
        getPreSignedURLRequest.expires = NSDate(timeIntervalSinceNow: 3600)
        
        
        AWSS3PreSignedURLBuilder.defaultS3PreSignedURLBuilder().getPreSignedURL(getPreSignedURLRequest) .continueWithBlock { (task:BFTask!) -> (AnyObject!) in
            if (task.error != nil) {
                NSLog("Error: %@", task.error)
            } else {
                let presignedURL = task.result as NSURL!
                if (presignedURL != nil) {
                    NSLog("download presignedURL is: \n%@", presignedURL)
                    
                    let request = NSURLRequest(URL: presignedURL)
                    self.downloadTask = self.session?.downloadTaskWithRequest(request)
                    self.downloadTask?.resume()
                }
            }
            return nil;
        }
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        
        NSLog("DownloadTask progress: %lf", progress)
        
        dispatch_async(dispatch_get_main_queue()) {
            //            self.progressView.progress = progress
            //            self.statusLabel.text = "Downloading..."
        }
        
    }
    
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        
        let filePath = determineFilePath(sharedInstance.downloadName)
        NSFileManager.defaultManager().moveItemAtURL(location, toURL: NSURL.fileURLWithPath(filePath)!, error: nil)
        
        // update UI elements
        // dispatch_async(dispatch_get_main_queue()) {
        // }
    }
    
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if (error == nil) {
            dispatch_async(dispatch_get_main_queue()) {
                // self.statusLabel.text = "Download Successfully"
                // recursive completion handler function, we delete the video that was just processed,
                // then we check if any videos are left to process
                // if so we spawn a new download
                // Todo integration point for new model
                
                
                self.sharedInstance.listOfVideosToDownload.removeObjectIdenticalTo(self.sharedInstance.downloadName)
                print(self.sharedInstance.listOfVideosToDownload.count)
                VideoModel.saveFilmAsDownloaded(self.sharedInstance.downloadName)
                if ((self.sharedInstance.listOfVideosToDownload.count) == 0) {
                    // NSLog("no videos left to process");
                } else {
                    // videos need to be downloaded, so start another download
                    self.start(self.sharedInstance.listOfVideosToDownload[0] as NSString)
                }
            }
        } else {
            dispatch_async(dispatch_get_main_queue()) {
                //                self.statusLabel.text = "Download Failed"
            }
            NSLog("S3 DownloadTask: %@ completed with error: %@", task, error!.localizedDescription);
        }
        
        //        dispatch_async(dispatch_get_main_queue()) {
        //            self.progressView.progress = Float(task.countOfBytesReceived) / Float(task.countOfBytesExpectedToReceive)
        //        }
        
        self.downloadTask = nil
    }
    
    func loadSnaps() {
        userObject.apiObject.getSnaps(self.latitude,long: self.longitute, hood: "Potrero Hill", delegate:self)
    }
    

}
