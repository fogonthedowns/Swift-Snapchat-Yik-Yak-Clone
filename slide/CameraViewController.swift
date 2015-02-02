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
    var uploadImageURL: NSURL?
    var successCount: NSNumber = 0

    // camera
    let captureSession = AVCaptureSession()
    var previewLayer : AVCaptureVideoPreviewLayer?
    var captureDevice : AVCaptureDevice?
    
    // snap data

    var lastVideoUploadID: String = ""
    var lastImgUploadID: String = ""
    var latitude: String = ""
    var longitute: String = ""
    
    // user identity

    let userObject = UserModel()
    
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
        userObject.findUser();
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
                self.successCount = self.successCount.integerValue+1
                NSLog("success count: %@", self.successCount.isEqual(2) )
                // post to snap server
                // video id, user id, lat, long
                if ( self.successCount.isEqual(2) ) {
                  self.statusLabel.text = "Upload Successfully"
                  self.postSnap()
                  self.successCount = 0
                }
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
        
        // process image
        let asset1 = AVURLAsset(URL:tempImage, options:nil)
        let generator = AVAssetImageGenerator(asset: asset1)
        let time = CMTimeMakeWithSeconds(0, 30)
        let size = CGSizeMake(425,355)
        generator.maximumSize = size
        let imgRef = generator.copyCGImageAtTime(time, actualTime: nil, error: nil)
        let thumb = UIImage(CGImage:imgRef)
        let data = UIImagePNGRepresentation(thumb)
        var directory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as NSString
        directory = directory + "/img.img"
        data.writeToFile(directory, atomically: true)
         var myimg = UIImage(contentsOfFile: directory)
         NSLog("my img:%@", myimg!)
        self.uploadImageURL = NSURL.fileURLWithPath(directory)
        
        self.dismissViewControllerAnimated(true, completion: {})
        self.uploadFileURL = NSURL.fileURLWithPath(pathString!)
        self.saveImageToAWS()
        self.saveToAWS()
    }
    
    // TODO refactor this shit
    // terribly undry 
    
    func saveToAWS () {
        NSLog("url: %@",  self.uploadFileURL as NSURL!)
        NSLog("self %@", self)
        var error: NSError? = nil
        
        if (error) != nil {
            NSLog("Error: %@",error!);
        }
        
        lastVideoUploadID = CameraViewController.randomStringWithLength(75) + ".mov"
        
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
    } // end saveToAws()
    
    func saveImageToAWS () {
        NSLog("saveImageToAWS() url image: %@",  self.uploadImageURL as NSURL!)
        var error: NSError? = nil
        
        if (error) != nil {
            NSLog("Error: %@",error!);
        }
        
        lastImgUploadID = CameraViewController.randomStringWithLength(75) + ".png"
        
        let getPreSignedURLRequest = AWSS3GetPreSignedURLRequest()
        getPreSignedURLRequest.bucket = S3BucketName
        getPreSignedURLRequest.key = lastImgUploadID
        getPreSignedURLRequest.HTTPMethod = AWSHTTPMethod.PUT
        getPreSignedURLRequest.expires = NSDate(timeIntervalSinceNow: 36600)
        
        //Important: must set contentType for PUT request
        let fileContentTypeStr = "image/png"
        getPreSignedURLRequest.contentType = fileContentTypeStr
        
        
        AWSS3PreSignedURLBuilder.defaultS3PreSignedURLBuilder().getPreSignedURL(getPreSignedURLRequest).continueWithBlock { (task:BFTask!) -> (AnyObject!) in
            if (task.error != nil) {
                NSLog("Error: %@", task.error)
            } else {
                let presignedURL = task.result as NSURL!
                if (presignedURL != nil) {
                    var request = NSMutableURLRequest(URL: presignedURL)
                    request.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData
                    request.HTTPMethod = "PUT"
                    request.setValue(fileContentTypeStr, forHTTPHeaderField: "Content-Type")
                    self.uploadTask = self.session?.uploadTaskWithRequest(request, fromFile: self.uploadImageURL!)
                    self.uploadTask!.resume()
                }
            }
            return nil;
        }
    } // end saveImageToAWS
    
    // location
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
    
    
    class func randomStringWithLength (len : Int) -> NSString {
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        var randomString : NSMutableString = NSMutableString(capacity: len)
        for (var i=0; i < len; i++){
            var length = UInt32 (letters.length)
            var rand = arc4random_uniform(length)
            randomString.appendFormat("%C", letters.characterAtIndex(Int(rand)))
        }
        return randomString
    }
    
    // this function uses the APIModel() instance apiObject
    // Todo This requires some completion handler 
    // maybe write a success row 
    
    func postSnap() -> Bool {
        userObject.apiObject.createSnap(self.latitude,long: self.longitute,video: self.lastVideoUploadID, image: self.lastImgUploadID)
        return true;
    }
    
}

