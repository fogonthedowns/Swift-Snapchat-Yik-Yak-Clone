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
}

let getSnapsBecauseIhaveAUserLoaded = "com.snapAPI.specialNotificationKey"

class HomeTableViewController: UITableViewController, NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate, APIProtocol {
    let userObject = UserModel()
    
    var latitude = "1"
    var longitute = "1"
    var videoModelList: NSMutableArray = [] // This is the array that my tableView
    var sharedInstance = VideoDataToAPI.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // notification center - Receive Notification!
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "loadSnaps", name: getSnapsBecauseIhaveAUserLoaded, object: nil)
        userObject.findUser();

        self.tableView.rowHeight = 115.0
        
        self.title = "Soma"
        // ----------------
        // lots of code
        
        let longpress = UILongPressGestureRecognizer(target: self, action: "longPress:")
        
        tableView.addGestureRecognizer(longpress)
        
        struct Static {
            static var session: NSURLSession?
            static var token: dispatch_once_t = 0
        }
        
        dispatch_once(&Static.token) {
            let configuration = NSURLSessionConfiguration.backgroundSessionConfiguration(BackgroundSessionDownloadIdentifier)
            Static.session = NSURLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        }
        
        self.session = Static.session;
        

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
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
        // NSLog("Array Count = %u", videoModelList.count);
        return videoModelList.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCellWithIdentifier("VideoCell") as VideoCellTableViewCell
        let video: VideoModel = videoModelList[indexPath.row] as VideoModel
        cell.titleLabel.text = video.film
        cell.selectionStyle = .None
        self.start(video.film)
        var urlString = "https://s3-us-west-1.amazonaws.com/slideby/" + video.img
        // NSLog("video url: %@", urlString)
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
    }
    
    func longPress(sender:UILongPressGestureRecognizer!) {
        let longPress = sender as UILongPressGestureRecognizer
        var locationInView = longPress.locationInView(tableView)
        var indexPath = tableView.indexPathForRowAtPoint(locationInView)
        var cell = self.tableView.cellForRowAtIndexPath(indexPath!) as VideoCellTableViewCell
        var urlString = cell.titleLabel.text!
        // NSLog(urlString)
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let documentsPath = paths.first as? String
        let filePath = documentsPath! + "/" + cell.titleLabel.text!
        
        if (sender.state == UIGestureRecognizerState.Ended) {
            println("Long press Ended");
            println("Long press Ended%@", self.view.subviews.count);
            self.moviePlayer.stop()
            self.moviePlayer.view.removeFromSuperview()
            self.tableView.reloadData()
            navigationController?.navigationBarHidden = false
            UIApplication.sharedApplication().statusBarHidden=false;
        } else if (sender.state == UIGestureRecognizerState.Began) {
            println("Long press detected.");
            let path = NSBundle.mainBundle().pathForResource("video", ofType:"m4v")
            let url = NSURL.fileURLWithPath(filePath)
            println(url)
            self.moviePlayer = MPMoviePlayerController(contentURL: url)
            if var player = self.moviePlayer {
                navigationController?.navigationBarHidden = true
                UIApplication.sharedApplication().statusBarHidden=true
                player.view.frame = self.view.bounds
                player.prepareToPlay()
                player.scalingMode = .AspectFill
                player.controlStyle = .None
                self.view.addSubview(player.view)
            }
        }
    }
    
    func longPressGestureRecognized(gestureRecognizer: UIGestureRecognizer) {
        let longPress = gestureRecognizer as UILongPressGestureRecognizer
        
        let state = longPress.state
        
        var locationInView = longPress.locationInView(tableView)
        
        var indexPath = tableView.indexPathForRowAtPoint(locationInView)
    }
    
    func didReceiveResult(result: JSON) {
        // local array var used in this function
        var videos: NSMutableArray = []
        
        for (index: String, rowAPIresult: JSON) in result {
            
                var videoModel = VideoModel(
                    id: rowAPIresult["film"].stringValue,
                    user: rowAPIresult["userId"].stringValue,
                    img: rowAPIresult["img"].stringValue
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
// ------------------------------------------
// Lots of code
    
    @IBOutlet var progressView: UIProgressView!
    @IBOutlet var statusLabel: UILabel!

    var session: NSURLSession?
    var downloadTask: NSURLSessionDownloadTask?
    var moviePlayer:MPMoviePlayerController!


    func start(s3downloadname: NSString) {
         NSLog("************************************************%@", s3downloadname)
        if (self.downloadTask != nil) {
            // push current downloadtask into an array
            // array processes recursive function
            NSLog("------------------------------- return -----------------%@", s3downloadname)

            return;
        }
        // test if file path is blank
        // if so go forward
        // if not return
        
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let documentsPath = paths.first as? String
        let filePath = documentsPath! + "/" + s3downloadname
        NSLog("------------------------------- filePath -----------------%@", filePath)
        let url = NSURL.fileURLWithPath(filePath)
        
        // if the file exists return, don't start an asynch download
        if NSFileManager.defaultManager().fileExistsAtPath(filePath) {
            NSLog("FILE ALREADY DOWNLOADED")
            return;
        }
        
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
        
//        NSLog("[%@ %@]", reflect(self).summary, __FUNCTION__)
        
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        
        let documentsPath = paths.first as? String
        let filePath = documentsPath! + "/" + sharedInstance.downloadName
//        NSLog("the filepath let:%@", filePath)
//        NSLog("the downloadkename let %@", sharedInstance.downloadName)
        NSFileManager.defaultManager().moveItemAtURL(location, toURL: NSURL.fileURLWithPath(filePath)!, error: nil)
        
        
        //update UI elements
        dispatch_async(dispatch_get_main_queue()) {
//            let path = NSBundle.mainBundle().pathForResource("video", ofType:"m4v")
//            let url = NSURL.fileURLWithPath(filePath)
//            println(url)
//            self.moviePlayer = MPMoviePlayerController(contentURL: url)
//            if let player = self.moviePlayer {
//                player.view.frame = self.view.bounds
//                player.prepareToPlay()
//                player.scalingMode = .AspectFill
//                self.view.addSubview(player.view)
//            }
        }
    }


    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if (error == nil) {
//            dispatch_async(dispatch_get_main_queue()) {
//                self.statusLabel.text = "Download Successfully"
//            }
            // NSLog("S3 DownloadTask: %@ completed successfully", task);
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
    
    func loadSnaps() {
        userObject.apiObject.getSnaps(self.latitude,long: self.longitute, delegate:self)
    }
}
