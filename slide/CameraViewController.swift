//
//  CameraViewController.swift
//  slide
//
//  Created by Justin Zollars on 1/27/15.
//  Copyright (c) 2015 rmb. All rights reserved.
//

import UIKit
import MediaPlayer
import MobileCoreServices
import AVFoundation
// depends on adding to the plist: NSLocationAlwaysUsageDescription and NSLocationWhenInUseUsageDescription
import CoreLocation

// core data is used to save the user identity, likely this will move
import CoreData


class CameraViewController: UIViewController, NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, CLLocationManagerDelegate {
    
    @IBOutlet var progressView: UIProgressView!
    @IBOutlet var statusLabel: UILabel!
    
    // location
    @IBOutlet var gpsResult : UILabel!
    let manager = CLLocationManager()
    
    // amazon S3
    var session: NSURLSession?
    var uploadTask: NSURLSessionUploadTask?
    var uploadFileURL: NSURL?
    
    // camera
    let captureSession = AVCaptureSession()
    var previewLayer : AVCaptureVideoPreviewLayer?
    var captureDevice : AVCaptureDevice?
    
    // user identity
    var userModel = [NSManagedObject]()
    
    // snap data
    var userID: String = ""
    var lastVideoUploadID: String = ""
    var data: NSMutableData = NSMutableData()
    var accessToken: String = ""
    var snapId: String = ""
    var latitude: String = ""
    var longitute: String = ""
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if CLLocationManager.authorizationStatus() == .NotDetermined {
            // NSLog("\n ****************************** NotDetermined()")
            manager.requestWhenInUseAuthorization()
        }
        
        if CLLocationManager.locationServicesEnabled() {
            // NSLog("\n ****************************** startUpdatingLocation()")
            manager.delegate = self
            manager.desiredAccuracy = kCLLocationAccuracyBest
            manager.startUpdatingLocation()
        }
        
        // NSLog("\n ------------------- viewDidLoad() -------------------------------------- ")
        // Do any additional setup after loading the view, typically from a nib.
        
        struct Static {
            static var session: NSURLSession?
            static var token: dispatch_once_t = 0
        }
        
        dispatch_once(&Static.token) {
            let configuration = NSURLSessionConfiguration.backgroundSessionConfiguration(BackgroundSessionUploadIdentifier)
            Static.session = NSURLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        }
        
        self.session = Static.session;
        self.progressView.progress = 0;
        self.statusLabel.text = "Ready"
        self.findUser();
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func start(sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) {
            // NSLog("\n ------------------- start() -------------------------------------- ")
            
            var imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .Camera;
            imagePicker.mediaTypes = [kUTTypeMovie!]
            imagePicker.allowsEditing = false
            imagePicker.showsCameraControls = true
            self.presentViewController(imagePicker, animated: true, completion: nil)
            
        }
            
        else {
            println("Camera not available.")
        }

        
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        
        let progress = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
        
        NSLog("UploadTask progress: %lf", progress)
        
        dispatch_async(dispatch_get_main_queue()) {
            self.progressView.progress = progress
            self.statusLabel.text = "Uploading..."
        }
        
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        
        if (error == nil) {
            dispatch_async(dispatch_get_main_queue()) {
                self.statusLabel.text = "Upload Successfully"
                // post to snap server 
                // video id, user id, lat, long
                self.postSnap()
            }
            NSLog("S3 UploadTask: %@ completed successfully", task);
            NSLog("S3 Session: %@ completed successfully", session);
        } else {
            dispatch_async(dispatch_get_main_queue()) {
                self.statusLabel.text = "Upload Failed"
            }
            NSLog("S3 UploadTask: %@ completed with error: %@", task, error!.localizedDescription);
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            self.progressView.progress = Float(task.countOfBytesSent) / Float(task.countOfBytesExpectedToSend)
        }
        
        self.uploadTask = nil
        
    }
    
    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        if ((appDelegate.backgroundUploadSessionCompletionHandler) != nil) {
            let completionHandler:() = appDelegate.backgroundUploadSessionCompletionHandler!;
            appDelegate.backgroundUploadSessionCompletionHandler = nil
            completionHandler
        }
    }
    
    
    func imagePickerController(picker: UIImagePickerController!, didFinishPickingMediaWithInfo info:NSDictionary!) {
        let tempImage = info[UIImagePickerControllerMediaURL] as NSURL!
        let pathString = tempImage.relativePath
        self.dismissViewControllerAnimated(true, completion: {})
        self.uploadFileURL = NSURL.fileURLWithPath(pathString!)
        self.saveToAWS()
    }
    
    func saveToAWS () {
        NSLog("url: %@",  self.uploadFileURL as NSURL!)
        NSLog("self %@", self)
        var error: NSError? = nil
        
        if (error) != nil {
            NSLog("Error: %@",error!);
        }
        
        lastVideoUploadID = randomStringWithLength(75) + ".mov"
        
        let getPreSignedURLRequest = AWSS3GetPreSignedURLRequest()
        getPreSignedURLRequest.bucket = S3BucketName
        getPreSignedURLRequest.key = lastVideoUploadID
        getPreSignedURLRequest.HTTPMethod = AWSHTTPMethod.PUT
        getPreSignedURLRequest.expires = NSDate(timeIntervalSinceNow: 36600)
        
        //Important: must set contentType for PUT request
        let fileContentTypeStr = "video/quicktime"
        getPreSignedURLRequest.contentType = fileContentTypeStr
        
        
        AWSS3PreSignedURLBuilder.defaultS3PreSignedURLBuilder().getPreSignedURL(getPreSignedURLRequest).continueWithBlock { (task:BFTask!) -> (AnyObject!) in
            if (task.error != nil) {
                NSLog("Error: %@", task.error)
            } else {
                // NSLog("\n !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! task.result: %@", task.result as NSURL!)
                let presignedURL = task.result as NSURL!
                if (presignedURL != nil) {
                    var request = NSMutableURLRequest(URL: presignedURL)
                    request.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData
                    request.HTTPMethod = "PUT"
                    request.setValue(fileContentTypeStr, forHTTPHeaderField: "Content-Type")
                    self.uploadTask = self.session?.uploadTaskWithRequest(request, fromFile: self.uploadFileURL!)
                    self.uploadTask!.resume()
                }
            }
            return nil;
        }
    }
    
    //     location
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        var locValue:CLLocationCoordinate2D = manager.location.coordinate
        println("locations = \(locValue.latitude) \(locValue.longitude)")
        self.latitude =  String(format: "%f", locValue.latitude)
        self.longitute = String(format: "%f", locValue.longitude)
        
    }
    
    func locationManager(manager: CLLocationManager!,
        didChangeAuthorizationStatus status: CLAuthorizationStatus)
        
    {
        NSLog("didChangeAuthorizationStatus() block")
        
        if status == .Authorized || status == .AuthorizedWhenInUse {
            NSLog(".Authorized || .AuthorizedWhenInUse block")
            manager.startUpdatingLocation()
            if (manager.location != nil){
              var locValue:CLLocationCoordinate2D = manager.location.coordinate
              println("locations = \(locValue.latitude) \(locValue.longitude)")
            }
            
        }
    }
    
    // User Identity Save
    func saveUser(name: String) {
         println("***************** saveUser()")
        //1
        let appDelegate =
        UIApplication.sharedApplication().delegate as AppDelegate
        
        let managedContext = appDelegate.managedObjectContext!
        
        //2
        let entity =  NSEntityDescription.entityForName("User",
            inManagedObjectContext:
            managedContext)
        
        let userName = NSManagedObject(entity: entity!,
            insertIntoManagedObjectContext:managedContext)
        
        //3
        userName.setValue(name, forKey: "identity")
        
        //4
        var error: NSError?
        if !managedContext.save(&error) {
            println("Could not save \(error), \(error?.userInfo)")
        }  
        //5
        userModel.append(userName)
        var userRow = userModel[0]
        userID = userRow.valueForKey("identity") as String!
        self.postUsertoSnapServer()
        NSLog("User:%@", userID)
    }
    
    func findUser() {
        println("***************** findUser()")
        //1
        let appDelegate =
        UIApplication.sharedApplication().delegate as AppDelegate
        
        let managedContext = appDelegate.managedObjectContext!
        
        //2
        let fetchRequest = NSFetchRequest(entityName:"User")
        
        //3
        var error: NSError?
        
        let fetchedResults =
        managedContext.executeFetchRequest(fetchRequest,
            error: &error) as [NSManagedObject]?
        
        if let results = fetchedResults {
            userModel = results
            println("Count: \(userModel), \(userModel.count)")
            if (userModel.count == 0){
                println("***************** no user found **********************")
                // No User is found, so we generate a User Identity
                // it is then passed to saveUser()
                var randomString = randomStringWithLength(50)
                self.saveUser(randomString)
            } else {
               println("***************** I Found a user! **********************")
               var userRow = userModel[0]
               userID = userRow.valueForKey("identity") as String!
               accessToken = userRow.valueForKey("accessToken") as String!
               snapId = userRow.valueForKey("snapId") as String!
               NSLog("User:%@", userID)
               NSLog("User AccessToken:%@", accessToken)
               NSLog("User SnapId:%@", snapId)
            }
        } else {
            println("Could not fetch \(error), \(error!.userInfo)")
        }
    }
    
    func randomStringWithLength (len : Int) -> NSString {
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        var randomString : NSMutableString = NSMutableString(capacity: len)
        for (var i=0; i < len; i++){
            var length = UInt32 (letters.length)
            var rand = arc4random_uniform(length)
            randomString.appendFormat("%C", letters.characterAtIndex(Int(rand)))
        }
        return randomString
    }
    
    // 4 functions below post a new user
    // connection delegate, methods grab the data returned by the api
    // append the data to self.data
    // and serialize the JSON so that updateUser() is called
    
    func postUsertoSnapServer()-> Bool {
        var url = "https://airimg.com/profiles/new?token=17975700jDLD5HQtiLbKjwaTkKmZK7zTQO8l5CEmktBzVEAtY&profile[device_token]=" + self.userID +  "&profile[email]=u@u.com&profile[password]=a&profile[os]=ios"
        NSLog("url:%@", url)
        let fileUrl = NSURL(string: url)
        var request = NSMutableURLRequest(URL: NSURL(string: url)!, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData, timeoutInterval: 5)
        var response: NSURLResponse?
        var error: NSError?
        request.HTTPMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        var connection: NSURLConnection = NSURLConnection(request: request, delegate: self, startImmediately: true)!;
        return true;
    }
    
    func connection(didReceiveResponse: NSURLConnection!, didReceiveResponse response: NSURLResponse!) {
        // Received a new request, clear out the data object
        self.data = NSMutableData()
    }
    
    func connection(connection: NSURLConnection!, didReceiveData data: NSData!) {
        // Append the received chunk of data to our data object
        self.data.appendData(data)
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection!) {
        // Request complete, self.data should now hold the resulting info
        // Convert the retrieved data in to an object through JSON deserialization
        var err: NSError
        var jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil) as NSDictionary
        // TODO fucking ugly, this needs to be out of this function, yuck.
        if jsonResult.count>0 {
            if (jsonResult["access_token"] != nil) {
              self.accessToken = jsonResult["access_token"] as NSString
              self.snapId = jsonResult["_id"] as NSString
              NSLog("accessToken:%@", accessToken)
              NSLog("snap ID:%@", snapId)
              self.updateUser()
            }
        }
    }
    
    // updateUser() called after a user is created, so the response can save the users access Token
    
    func updateUser(){
        let appDelegate =
        UIApplication.sharedApplication().delegate as AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        var request = NSBatchUpdateRequest(entityName: "User")
        request.predicate = NSPredicate(format: "identity == %@", self.userID)
        request.propertiesToUpdate = ["accessToken":self.accessToken, "snapId":self.snapId]
        request.resultType = .UpdatedObjectsCountResultType
        var batchError: NSError?
        let result = managedContext.executeRequest(request,
            error: &batchError)
        
        if result != nil{
            if let theResult = result as? NSBatchUpdateResult{
                if let numberOfAffectedPersons = theResult.result as? Int{
                    println("The number of records that match the predicate " +
                        "and have an access token is \(numberOfAffectedPersons)")
            
                }
            }
        } else {
            if let error = batchError{
                println("Could not perform batch request. Error = \(error)")
            }
        }
        
    }
    
    func postSnap() -> Bool {
        var url = "https://airimg.com/snaps/new?access_token=" + self.accessToken + "&token=17975700jDLD5HQtiLbKjwaTkKmZK7zTQO8l5CEmktBzVEAtY&snap[userId]=" + self.snapId +  "&snap[film]=" + self.lastVideoUploadID + "&snap[lat]=" + self.latitude + "&snap[long]=" + self.longitute + "&device_token=" + self.userID
        NSLog("url:%@", url)
        let fileUrl = NSURL(string: url)
        var request = NSMutableURLRequest(URL: NSURL(string: url)!, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData, timeoutInterval: 5)
        var response: NSURLResponse?
        var error: NSError?
        request.HTTPMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        var connection: NSURLConnection = NSURLConnection(request: request, delegate: self, startImmediately: true)!;
        return true;
    }
    
}

