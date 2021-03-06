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


protocol sendVideoProtocol {
    func sendVideo()
}


class CameraViewController: UIViewController, NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, CLLocationManagerDelegate, AVCaptureFileOutputRecordingDelegate, UITextFieldDelegate, sendVideoProtocol {
    
    // UIView 
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var confirmationView: UIView!
    @IBOutlet weak var takeVideoButton: UIButton!
    
    @IBOutlet weak var cameraIsRecording: UIImageView!
    @IBOutlet weak var userDescription: UITextField!
    // location
    @IBOutlet var gpsResult : UILabel!
    let manager = CLLocationManager()

    // amazon S3
    var session: NSURLSession?
    var uploadTask: NSURLSessionUploadTask?
    var uploadFileURL: NSURL?
    var uploadImageURL: NSURL?
    var successCount: NSNumber = 0
    let ItemStatusContext:NSString?

    // camera
    let captureSession = AVCaptureSession()
    var previewLayer : AVCaptureVideoPreviewLayer?
    var captureDevice : AVCaptureDevice?
    private var stillImageOutput : AVCaptureStillImageOutput?
    private var videoRecordingOutput : AVCaptureMovieFileOutput?
    private var audioDevice : AVCaptureDevice?
    private var audioInput : AVCaptureDeviceInput?
    var delegate : AVCaptureFileOutputRecordingDelegate?
    var sharedInstance = VideoDataToAPI.sharedInstance
    var tempVideo: NSURL?
    // var screentap: UITapGestureRecognizer!
    
    // camera preview
    var moviePlayer:MPMoviePlayerController!
    var stopPreview:Bool = false
   
    // user identity
    let userObject = UserModel()
    
    // image processing
    let time = CMTimeMakeWithSeconds(0, 30)
    let size = CGSizeMake(425,355)
    
    var backPressed = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.sharedApplication().statusBarStyle = .LightContent
        var ItemStatusContext = "com.foo.bar.jz"
        
        // hide big blue bar
        navigationController?.navigationBarHidden = true
        
        // bind keyboard
        self.userDescription.delegate = self;
        
        
        // camera
        self.cameraIsRecording.hidden = true
        
        // add tap gesture recognizer
        var tap:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "DismissKeyboard")
        self.confirmationView.addGestureRecognizer(tap)
        
        // location
        if CLLocationManager.authorizationStatus() == .NotDetermined {
            NSLog("\n ****************************** NotDetermined()")
            manager.requestWhenInUseAuthorization()
        }
        
        if CLLocationManager.locationServicesEnabled() {
            NSLog("\n ****************************** if CLLocationManager.locationServicesEnabled() startUpdatingLocation()")
            manager.delegate = self
            manager.desiredAccuracy = kCLLocationAccuracyBest
            manager.startUpdatingLocation()
        }
        
        struct Static {
            static var session: NSURLSession?
            static var token: dispatch_once_t = 0
        }
        
        dispatch_once(&Static.token) {
            let configuration = NSURLSessionConfiguration.backgroundSessionConfiguration(BackgroundSessionUploadIdentifier)
            Static.session = NSURLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        }
        
        self.session = Static.session;
        userObject.findUser();
        
        // pass self to sharedInstance so that we can use upload button
        // via delegate
        SharedViewData.sharedInstance.cameraViewController = self

        // new video code
        // this is used to see if a user is recording a video or not
        // long press, they are recording
        // let go it stops
        
        var tapRecord:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "tapRecord:")
        let longpress = UILongPressGestureRecognizer(target: self, action: "longPress:")
        longpress.minimumPressDuration = 0.10
        self.takeVideoButton.addGestureRecognizer(longpress)
        self.takeVideoButton.addGestureRecognizer(tapRecord)
        
        // this notifcation is to determine if a video preview has finished playing
        // if so we loop it
        
         NSNotificationCenter.defaultCenter().addObserver(self, selector: "MovieFinishedPlayingCallback", name: MPMoviePlayerPlaybackDidFinishNotification, object: nil)
        
        // Do any additional setup after loading the view, typically from a nib.
        captureSession.sessionPreset = AVCaptureSessionPresetMedium
        
        let devices = AVCaptureDevice.devices()
        
        // Loop through all the capture devices on this phone
        for device in devices {
            // Make sure this particular device supports video
            if (device.hasMediaType(AVMediaTypeVideo)) {
                // Finally check the position and confirm we've got the back camera
                if(device.position == AVCaptureDevicePosition.Back) {
                    captureDevice = device as? AVCaptureDevice
                    if captureDevice != nil {
                        println("Capture device found")
                        setupCamera()
                    }
                }
            }
        }
        
    }
    
    override func viewDidAppear(animated:Bool) {
        super.viewDidAppear(true)
        if (self.sharedInstance.userIsAddingFriends) {
          UIApplication.sharedApplication().statusBarHidden=true
        }
        if CLLocationManager.locationServicesEnabled() {
            NSLog("\n ******************************viewdidappear startUpdatingLocation()")
            manager.delegate = self
            manager.desiredAccuracy = kCLLocationAccuracyBest
            manager.startUpdatingLocation()
        }
    }
//
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(true)
        
        if CLLocationManager.locationServicesEnabled() {
            NSLog("\n ****************************** startUpdatingLocation()")
            manager.delegate = self
            manager.desiredAccuracy = kCLLocationAccuracyBest
            manager.startUpdatingLocation()
        }
        
        self.DismissKeyboard()
        if (sharedInstance.userIsAddingFriends) {
            
        } else {
            // self.sharedInstance.userDescription = self.userDescription.text
            self.userDescription.text = ""
            self.stopPreview = true
            if (self.moviePlayer != nil) {
              self.moviePlayer.stop()
              self.view.sendSubviewToBack(self.confirmationView)
              self.view.sendSubviewToBack(self.moviePlayer.view)
            }
        }

    }
    
    func configureDevice() {
        if let device = captureDevice {
            device.lockForConfiguration(nil)
            device.focusMode = .ContinuousAutoFocus
            // device.focusPointOfInterest = screentap.locationInView(self) CGPOINT
            device.unlockForConfiguration()
            
        }
        
    }
    
    func setupCamera() {
        
        configureDevice()
        delegate = self
        var err : NSError? = nil
        
        // try to open the device
         let videoCapture = AVCaptureDeviceInput(device: captureDevice, error: &err)
         let audioDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio)
         let audioInput: AnyObject! = AVCaptureDeviceInput.deviceInputWithDevice(audioDevice, error:&err)
         // add video input
         if captureSession.canAddInput(videoCapture) {
            captureSession.addInput(videoCapture)
            captureSession.addInput(audioInput as AVCaptureInput)
         }
  
        if err != nil {
            println("error: \(err?.localizedDescription)")
        }
        
        // this is the video display, on screen as one records video
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        // this is where you could define a custom view
        cameraView.layer.addSublayer(previewLayer)
        previewLayer?.frame = self.view.layer.frame
        
        if !captureSession.running {
            videoRecordingOutput = AVCaptureMovieFileOutput()
            videoRecordingOutput?.maxRecordedDuration = CMTimeMake(660, 60)
            // stillImageOutput = AVCaptureStillImageOutput()
            // let outputSettings = [ AVVideoCodecKey : AVVideoCodecJPEG ]
            // stillImageOutput!.outputSettings = outputSettings
        
            
            // add output to session
            if captureSession.canAddOutput(videoRecordingOutput) {
                captureSession.addOutput(videoRecordingOutput)
            }
            
            // display camera in UI
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            cameraView.layer.addSublayer(previewLayer)
            previewLayer?.frame = cameraView.layer.frame
            previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
            
            // start camera
            captureSession.startRunning()
        }
        
    } // end setupCamera()
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tapRecord(sender:UITapGestureRecognizer!) {
         UIApplication.sharedApplication().statusBarHidden=false
        let alertController = UIAlertController(title: "Hold to Record 📼", message: "To record a movie hold the camera button.", preferredStyle: .Alert)

        let cancelAction = UIAlertAction(title: "Ok", style: .Cancel) { (_) in }
        alertController.addAction(cancelAction)
        self.presentViewController(alertController, animated: true, completion:nil)
    }
    

    // new
    func longPress(sender:UILongPressGestureRecognizer!) {
        let longPress = sender as UILongPressGestureRecognizer
            if (sender.state == UIGestureRecognizerState.Ended) {
                NSLog("done with long press")
              self.videoRecordingOutput?.stopRecording()
                NSLog("Done Recording")
                self.cameraIsRecording.hidden = true
            } else if (sender.state == UIGestureRecognizerState.Began) {
                NSLog("long press detected")
                self.backPressed = false
                self.cameraIsRecording.hidden = false
                UIApplication.sharedApplication().statusBarHidden=true
                var url:NSURL = tempFileUrl()
                videoRecordingOutput?.startRecordingToOutputFileURL(url, recordingDelegate:delegate)
        }
    }
    
    // new
    // I think this is function implements a protocol
    // so we can't change the name
    func captureOutput(captureOutput: AVCaptureFileOutput!,
        didStartRecordingToOutputFileAtURL fileURL: NSURL!,
        fromConnections connections: [AnyObject]!){
            NSLog("recording has begain with %@", fileURL)
            
    }
    
    
    // new 
    // I think this is function implements a protocol
    // this function captures the output of a film
    // so we can't change the name
    func captureOutput(captureOutput: AVCaptureFileOutput!,
        didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!,
        fromConnections connections: [AnyObject]!,
        error: NSError!) {
             NSLog("*** recording has ended with %@", outputFileURL)
            self.tempVideo = outputFileURL as NSURL!
            var videoFile = self.tempVideo as NSURL!
            let pathString = videoFile.relativePath
            
            let url = NSURL.fileURLWithPath(pathString!)
            self.moviePlayer = MPMoviePlayerController(contentURL: url)
            if var player = self.moviePlayer {
                // let the preview loop
                self.stopPreview = false
                UIApplication.sharedApplication().statusBarHidden=true
                player.view.frame = self.view.bounds
                player.prepareToPlay()
                player.scalingMode = .AspectFill
                player.controlStyle = .None
                self.view.addSubview(player.view)
        
                // custom UI preview controlls
                // Back button and send buttons
                self.view.addSubview(self.confirmationView)
                self.view.bringSubviewToFront(self.confirmationView)
            }
    }
    
    @IBAction func addFriends(sender: AnyObject) {
        self.sharedInstance.userIsAddingFriends = true
        NSNotificationCenter.defaultCenter().postNotificationName(didClickToNavigateToFriends, object: self)
    }
    // User pressed back button from video preview
    // stop video, stop preview
    // clear views
    
    // cancel
    @IBAction func pressBackButtonfromConfirm(sender: AnyObject) {
        
        if (self.backPressed == false) {
            UIApplication.sharedApplication().statusBarHidden=false
            self.clearTaggedFriends()
            self.DismissKeyboard()
            self.userDescription.text = ""
            self.stopPreview = true
            self.moviePlayer.stop()
            self.view.sendSubviewToBack(self.confirmationView)
            self.view.sendSubviewToBack(self.moviePlayer.view)
            self.backPressed = true
        }
    }
    
    // User pressed confirm video
    // so start processing video and segue
    
    @IBAction func pressConfirmVideo(sender: AnyObject) {
        self.sendVideo()
    }
    
    // sendVideoProtocol function implementation
    func sendVideo() {
        UIApplication.sharedApplication().statusBarHidden=false
        self.sharedInstance.userIsAddingFriends = false
        self.view.sendSubviewToBack(self.confirmationView)
        self.view.sendSubviewToBack(self.moviePlayer.view)
        // view logic
        self.stopPreview = true
        self.moviePlayer.stop()
        
        self.sharedInstance.userDescription = self.userDescription.text
        NSNotificationCenter.defaultCenter().postNotificationName(didClickToNavigateBackHome, object: self)
        let qualityOfServiceClass = QOS_CLASS_BACKGROUND
        let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
        dispatch_async(backgroundQueue, {
            self.processImage()
        })
    }
    
    func processImage(){
        // process image
        var videoFile = self.tempVideo as NSURL!
        let pathString = videoFile.relativePath
        
        // process image from videoFile
        let asset1 = AVURLAsset(URL:videoFile, options:nil)
        let generator = AVAssetImageGenerator(asset: asset1)

        generator.maximumSize = size
        let imgRef = generator.copyCGImageAtTime(time, actualTime: nil, error: nil)
        let thumb = UIImage(CGImage:imgRef)
        let data = UIImagePNGRepresentation(thumb)
        // var directory = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)[0] as NSString
        var directory = NSTemporaryDirectory()
        var imageFile = directory + "/img.img"
        data.writeToFile(imageFile, atomically: true)
        CameraViewController.excludeFromBackup(directory)
        var myimg = UIImage(contentsOfFile: imageFile)
        self.uploadImageURL = NSURL.fileURLWithPath(imageFile)

        self.dismissViewControllerAnimated(true, completion: {})
        self.uploadFileURL = NSURL.fileURLWithPath(pathString!)
        self.saveImageToAWS()
        self.saveToAWS()
    }
    
    class func excludeFromBackup(savePath:NSString) {
        var error: NSError? = nil
        var url = NSURL(fileURLWithPath: savePath)
        var success = url!.setResourceValue(true, forKey: NSURLIsExcludedFromBackupKey, error: &error)
        
        if (!success) {
            println("we've got a problem")
        } else {
        }
        
        if (error != nil) {
          println(error);
        }
    }
    
    
    // needs more logic, so it doesn't get in infinate loop
    // first check to see if the send button has been sent
    func MovieFinishedPlayingCallback() -> Void {
        if (!self.stopPreview) {
            if (self.moviePlayer != nil) {
              self.moviePlayer.play()
            }
        }
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        
        let progress = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
        
        // NSLog("UploadTask progress: %lf", progress)
        
        // dispatch_async(dispatch_get_main_queue()) {
           // TODO Status Status "UPLOADING"
        // }
        
    }
    
    // used in longpress of camera button to make a temp file
    func tempFileUrl()->NSURL{
        var movieTempString = CameraViewController.randomStringWithLength(10) + ".mov"
        let tempDirectoryTemplate = NSTemporaryDirectory().stringByAppendingPathComponent(movieTempString)
        let url = NSURL.fileURLWithPath(tempDirectoryTemplate)
        CameraViewController.excludeFromBackup(tempDirectoryTemplate)
        if NSFileManager.defaultManager().fileExistsAtPath(tempDirectoryTemplate) {
            NSFileManager.defaultManager().removeItemAtPath(tempDirectoryTemplate, error: nil)
        }
        return url!
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        
        if (error == nil) {
            dispatch_async(dispatch_get_main_queue()) {
                self.successCount = self.successCount.integerValue+1
                // post to snap server
                // video id, user id, lat, long
                if ( self.successCount.isEqual(2) ) {
                  // TODO UPLOADED Successfully notification
                  // TODO consider moving away from singleton, and towards db entries, that way we can track success and failure and also handle multiple uploads simultaneously
                    
                    self.postSnap(self.sharedInstance.latitude,long: self.sharedInstance.longitute,video: self.sharedInstance.lastVideoUploadID, image: self.sharedInstance.lastImgUploadID, description: self.sharedInstance.userDescription, tags:self.processTags(self.sharedInstance.taggedFriends))
                  self.successCount = 0
                  self.clearTaggedFriends()
                  
                }
            } // end dispatch_async()
        } else {
            // dispatch_async(dispatch_get_main_queue()) {
                // todo UPLOADED Failed notification
            // }
            // NSLog("S3 UploadTask: %@ completed with error: %@", task, error!.localizedDescription);
        }
        
        self.uploadTask = nil
        
    }
    
    
    func processTags(friends:NSArray)-> NSString {
        var theString:String = ""
        var myFriends:[FriendModel] = friends as [FriendModel]
        for friend in myFriends {
            theString = theString + " " + friend.phoneString
        }
        return theString
    }
    
    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        if ((appDelegate.backgroundUploadSessionCompletionHandler) != nil) {
            let completionHandler:() = appDelegate.backgroundUploadSessionCompletionHandler!;
            appDelegate.backgroundUploadSessionCompletionHandler = nil
            completionHandler
        }
    }
    
    
    // TODO refactor this shit
    // terribly undry 
    
    func saveToAWS () {
        
        var error: NSError? = nil
        
        if (error) != nil {
            NSLog("Error: %@",error!);
        }
        
        sharedInstance.lastVideoUploadID = CameraViewController.randomStringWithLength(75) + ".mov"
        
        let getPreSignedURLRequest = AWSS3GetPreSignedURLRequest()
        getPreSignedURLRequest.bucket = S3BucketName
        getPreSignedURLRequest.key = sharedInstance.lastVideoUploadID
        getPreSignedURLRequest.HTTPMethod = AWSHTTPMethod.PUT
        getPreSignedURLRequest.expires = NSDate(timeIntervalSinceNow: 36600)
        
        //Important: must set contentType for PUT request
        let fileContentTypeStr = "video/quicktime"
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
                    self.uploadTask = self.session?.uploadTaskWithRequest(request, fromFile: self.uploadFileURL!)
                    self.uploadTask!.resume()
                }
            }
            return nil;
        }
    } // end saveToAws()
    
    func saveImageToAWS () {
        // NSLog("saveImageToAWS() url image: %@",  self.uploadImageURL as NSURL!)
        var error: NSError? = nil
        
        if (error) != nil {
            NSLog("Error: %@",error!);
        }
        
        sharedInstance.lastImgUploadID = CameraViewController.randomStringWithLength(75) + ".png"
        
        let getPreSignedURLRequest = AWSS3GetPreSignedURLRequest()
        getPreSignedURLRequest.bucket = S3BucketName
        getPreSignedURLRequest.key = sharedInstance.lastImgUploadID
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
        // println("locations = \(locValue.latitude) \(locValue.longitude)")
        sharedInstance.latitude =  String(format: "%f", locValue.latitude)
        sharedInstance.longitute = String(format: "%f", locValue.longitude)
        
    }
    
    func locationManager(manager: CLLocationManager!,
        didChangeAuthorizationStatus status: CLAuthorizationStatus) {
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
    
    func DismissKeyboard(){
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        self.confirmationView.endEditing(true)
    }
    
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        self.view.endEditing(true);
        return false;
    }
    
    func clearTaggedFriends() {
        self.sharedInstance.taggedFriends = []
        for friend in self.sharedInstance.friendsList {
            let friend:FriendModel = friend as FriendModel
            friend.tagged = false
        }
    }
    
    // this function uses the APIModel() instance apiObject
    // Todo This requires some completion handler 
    // maybe write a success row 
    
    func postSnap(lat:NSString,long:NSString,video:NSString,image:NSString, description:NSString, tags:NSString) -> Bool {
        userObject.apiObject.createSnap(lat,long:long,video:video,image:image, description:description, tags:tags)
        self.userDescription.text = ""
        return true;
    }
    
}

