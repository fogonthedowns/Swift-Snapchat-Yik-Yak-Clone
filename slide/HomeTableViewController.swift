//
//  HomeTableViewController.swift
//  slide
//
//  Created by Justin Zollars on 1/29/15.
//  Copyright (c) 2015 rmb. All rights reserved.
//

import UIKit
import MediaPlayer

// the protocol, api protocol is referenced by the class below
// the method outlined is included in the class

protocol APIProtocol {
    func didReceiveResult(results: JSON)
    func addResult(results:JSON)
}

let getSnapsBecauseIhaveAUserLoaded = "com.snapAPI.specialNotificationKey"
let didCompleteUploadWithNoErrors = "com.snapAPI.didCompleteUpload"

class HomeTableViewController: UITableViewController, NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate, UIPageViewControllerDelegate, APIProtocol {
    let userObject = UserModel()

    @IBOutlet var progressView: UIProgressView!
    @IBOutlet var statusLabel: UILabel!
    

    var session: NSURLSession?
    var downloadTask: NSURLSessionDownloadTask?
    var moviePlayer:MPMoviePlayerController!
    var latitude = "1"
    var longitute = "1"
    var videoModelList: NSMutableArray = [] // This is the array that my tableView
    var sharedInstance = VideoDataToAPI.sharedInstance
    var hood:NSString = ""
    var offset:Int = 0
    
    let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
    
    // notification
    // var localNotification:UILocalNotification = UILocalNotification()
   
    override func viewDidLoad() {
        super.viewDidLoad()
               // Receive Notification and call loadSnaps once we have a user
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "loadSnaps", name: getSnapsBecauseIhaveAUserLoaded, object: nil)
        userObject.findUser();
        
        
        //// end notification

        // Table Row Init
        self.tableView.rowHeight = 70.0
        let longpress = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
        longpress.minimumPressDuration = 0.35
        tableView.addGestureRecognizer(longpress)

        // singleton of session
        // ie we can only download one object at a time from Amazon
        struct Static {
            static var session: NSURLSession?
            static var token: dispatch_once_t = 0
        }
        
        dispatch_once(&Static.token) {
            let configuration = NSURLSessionConfiguration.backgroundSessionConfiguration(BackgroundSessionDownloadIdentifier)
            Static.session = NSURLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        }
        
        self.session = Static.session;
        var refresh = UIRefreshControl()
        refresh.addTarget(self, action: "pullToLoadSnaps:", forControlEvents:.ValueChanged)
        self.refreshControl = refresh
    }
    
     override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        if (sharedInstance.hood == nil) {
        } else if (self.title == sharedInstance.hood) {
            println("title didn't change")
            self.loadSnaps()
            self.tableView.reloadData()
        } else {
          self.hood = sharedInstance.hood
          self.loadSnaps()
          self.tableView.reloadData()
          self.title = self.hood
        }
        
     }
    
     override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(true)
        self.offset = 0
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func navigateToCamera(sender: AnyObject) {
        NSNotificationCenter.defaultCenter().postNotificationName(didClickToNavigateToCamera, object: self)
    }

    @IBAction func navigateToDistricts(sender: AnyObject) {
        NSNotificationCenter.defaultCenter().postNotificationName(didClickToNavigateToDistricts, object: self)
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
        // NSLog("Array Count = %u", videoModelList.count);
        return videoModelList.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCellWithIdentifier("VideoCell") as VideoCellTableViewCell
        let video: VideoModel = videoModelList[indexPath.row] as VideoModel
        cell.videoModel = video
        // possible point for dictionary integration, key is video.film
        // but how to solve this when there are many districts? many dictionaries?
        cell.titleLabel.text = video.film
        // println("votes")
        // println(video.votes)
        var lbl : UILabel? = cell.contentView.viewWithTag(1) as? UILabel
        lbl?.text = video.userDescription
        if (video.votes > 0) {
            cell.starImage.image = UIImage(named:("starwithvotes"))
            cell.voteCount.text = video.votes.stringValue
        } else {
            cell.starImage.image = UIImage(named:("starnovotes"))
            cell.voteCount.text = ""
        }
        
        if (video.comments.count > 0){
            var reply = " replies"
            if (video.comments.count == 1) {
                reply = " reply"
            }
            
           var commentCount = video.comments.count as NSNumber
           var commentString = commentCount.stringValue + reply
           cell.commentCount.text = commentString
        } else {
            cell.commentCount.text = ""
        }
        
        cell.userVote.addTarget(self, action: "checkButtonTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        
        cell.selectionStyle = .None
        self.start(video.film)
        var urlString = "https://s3-us-west-1.amazonaws.com/slideby/" + video.img
        let url = NSURL(string: urlString)
        let main_queue = dispatch_get_main_queue()
        // This is the temporary image, that loads before the Async images below
        cell.videoPreview.image = UIImage(named: ("placeholder"))
        // this allows images to load in the background
        // and allows the page to load without the image
        let backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        
        // Load Images Asynchroniously
        dispatch_async(backgroundQueue, {
            SGImageCache.getImageForURL(urlString) { image in
                if image != nil {
                    dispatch_async(dispatch_get_main_queue(), {
                        cell.videoPreview.contentMode = UIViewContentMode.ScaleAspectFill
                        cell.videoPreview.image = image;
                        cell.videoPreview.layer.cornerRadius = cell.videoPreview.frame.size.width  / 2;
                        cell.videoPreview.clipsToBounds = true;
                    })

                }
            }
        })
        return cell
    } // func tableView(cellForRowAtIndexPath)
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let indexPath = tableView.indexPathForSelectedRow();
        
        let currentCell = tableView.cellForRowAtIndexPath(indexPath!) as VideoCellTableViewCell
        sharedInstance.videoForCommentController = currentCell.videoModel
        println(currentCell.videoModel.userDescription)
        println(self.sharedInstance.videoForCommentController.userDescription)
        NSNotificationCenter.defaultCenter().postNotificationName(didClickToNavigateToComments, object: self)
    } // tableView(didSelectRowAtIndexPath)
    
    func handleLongPress(sender:UILongPressGestureRecognizer!) {
        let localLongPress = sender as UILongPressGestureRecognizer
        var locationInView = localLongPress.locationInView(tableView)
        
        // returns nil in the case of last cell
        // but strangely only on EndedState
        var indexPath = tableView.indexPathForRowAtPoint(locationInView)
        if indexPath != nil {
            let cell = self.tableView.cellForRowAtIndexPath(indexPath!) as VideoCellTableViewCell
            let urlString = cell.titleLabel.text!
            println("Long press Block .................");

            let filePath = determineFilePath(cell.titleLabel.text!)
            
            if (sender.state == UIGestureRecognizerState.Ended) {
                println("Long press Ended");
                self.moviePlayer.stop()
                self.moviePlayer.view.removeFromSuperview()
                self.tableView.reloadData()
                navigationController?.navigationBarHidden = false
                UIApplication.sharedApplication().statusBarHidden=false;
            } else if (sender.state == UIGestureRecognizerState.Began) {
                println("Long press detected.");
                let path = NSBundle.mainBundle().pathForResource("video", ofType:"m4v")
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
    
    func didReceiveResult(result: JSON) {
        // local array var used in this function
        var videos: NSMutableArray = []
        
        for (index: String, rowAPIresult: JSON) in result {
            
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
                if (videoModel.flags >= 2){
                    
                } else {
                    videos.addObject(videoModel)
                }
            }
            
        // Set our array of new models
        videoModelList = videos
        // Make sure we are on the main thread, and update the UI.
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
              // NSLog("refreshing \(self.videoModelList)")
            self.tableView.reloadData()
        })
    }
    
    // doesn't work because offset is always reset, or native loadSnaps call returns just 10.
    // offset is set to zero when we navigate away for other cities case
    // but poses a problem when we check out a snap
    // we must reload the snap, to persist the comments between clicks, but the reload calls loadSnaps
    // its pretty messy
    
    func addResult(result: JSON) {
        // local array var used in this function
        var videos = videoModelList
        
        for (index: String, rowAPIresult: JSON) in result {
            
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
            
            videos.addObject(videoModel)
        }
        
        // Set our array of new models
        videoModelList = videos
        // Make sure we are on the main thread, and update the UI.
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            // NSLog("refreshing \(self.videoModelList)")
            self.tableView.reloadData()
        })
    }
    
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
    
// ------------------------------------------
// Lots of code
    
    func start(s3downloadname: NSString) {
        
        let filePath = determineFilePath(s3downloadname)
        // if the file exists return, don't start an asynch download
        if NSFileManager.defaultManager().fileExistsAtPath(filePath) {
            // NSLog("FILE ALREADY DOWNLOADED")
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
                self.sharedInstance.listOfVideosToDownload.removeObjectIdenticalTo(self.sharedInstance.downloadName)
                print(self.sharedInstance.listOfVideosToDownload.count)
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

    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        if ((appDelegate.backgroundDownloadSessionCompletionHandler) != nil) {
            let completionHandler:() = appDelegate.backgroundDownloadSessionCompletionHandler!;
            appDelegate.backgroundDownloadSessionCompletionHandler = nil
            completionHandler
        }
        
        // NSLog("Completion Handler has been invoked, background download task has finished.");
    }
    
    
    func checkButtonTapped(sender:AnyObject){
        var btnPos: CGPoint = sender.convertPoint(CGPointZero, toView: self.tableView)
        var indexPath: NSIndexPath = self.tableView.indexPathForRowAtPoint(btnPos)!
        let video: VideoModel = videoModelList[indexPath.row] as VideoModel
        println(video.userDescription)
        self.vote(video.film)
        
    }
    
    func determineFilePath(file:NSString)-> NSString {
        let documentsPath = paths.first as? String
        let filePath = documentsPath! + "/" + file
        return filePath
    }
    
    //    override func scrollViewDidEndDragging(scrollView: UIScrollView,
    //        willDecelerate decelerate: Bool) {
    //        if (scrollView.contentOffset.y >= (scrollView.contentSize.height - scrollView.frame.size.height)) {
    //            println("reach bottom")
    //            self.loadOffsetSnaps()
    //        }
    //    }
    
    func pullToLoadSnaps(sender:AnyObject)
    {
        self.loadSnaps()
        self.tableView.reloadData()
        self.refreshControl?.endRefreshing()
    }
    
    func loadSnaps() {
        userObject.apiObject.getSnaps(self.latitude,long: self.longitute, hood: self.hood, delegate:self)
    }
    
    func loadOffsetSnaps() {
        offset = offset + 10
        let offsetAPI = NSNumber(integer:offset)
        
        userObject.apiObject.getOffsetSnaps(self.latitude,long: self.longitute, hood: self.hood, offset: offsetAPI, delegate:self)
        println(offsetAPI)
    }
    
    func vote(video:NSString) {
        userObject.apiObject.voteforSnap(video)
    }
}
