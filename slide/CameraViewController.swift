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


class CameraViewController: UIViewController, NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, CLLocationManagerDelegate, AVCaptureFileOutputRecordingDelegate {
    
    // UIView 
    @IBOutlet weak var cameraView: UIView!
    
    @IBOutlet var progressView: UIProgressView!
    @IBOutlet var statusLabel: UILabel!
    
    @IBOutlet weak var takeVideoButton: UIButton!
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
    private var stillImageOutput : AVCaptureStillImageOutput?
    private var videoRecordingOutput : AVCaptureMovieFileOutput?
    private var audioDevice : AVCaptureDevice?
    private var audioInput : AVCaptureDeviceInput?
    
    // snap data
    // consider moving successsCount, progressView (if possible) and statusLabel (if possible)
    // to sharedInstance 
    var delegate : AVCaptureFileOutputRecordingDelegate?

    var sharedInstance = VideoDataToAPI.sharedInstance
    
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
        
        // new video code
        
        let longpress = UILongPressGestureRecognizer(target: self, action: "longPress:")
        self.takeVideoButton.addGestureRecognizer(longpress)
        
        // Do any additional setup after loading the view, typically from a nib.
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        
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
                        beginSession()
                    }
                }
            }
        }
        
    }
    
    func focusTo(value : Float) {
        if let device = captureDevice {
            if(device.lockForConfiguration(nil)) {
                device.setFocusModeLockedWithLensPosition(value, completionHandler: { (time) -> Void in
                    //
                })
                device.unlockForConfiguration()
            }
        }
    }
    
    let screenWidth = UIScreen.mainScreen().bounds.size.width
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        var anyTouch = touches.anyObject() as UITouch
        var touchPercent = anyTouch.locationInView(self.view).x / screenWidth
        focusTo(Float(touchPercent))
    }
    
    override func touchesMoved(touches: NSSet, withEvent event: UIEvent) {
        var anyTouch = touches.anyObject() as UITouch
        var touchPercent = anyTouch.locationInView(self.view).x / screenWidth
        focusTo(Float(touchPercent))
    }
    
    func configureDevice() {
        if let device = captureDevice {
            device.lockForConfiguration(nil)
            device.focusMode = .Locked
            device.unlockForConfiguration()
        }
        
    }
    
    
    func beginSession() {
        
        configureDevice()
        delegate = self
        var err : NSError? = nil
        
        // try to open the device
        // AVCaptureDeviceInput(device: captureDevice, error: &err)
        // add video input
        // if captureSession.canAddInput(videoCapture) {
        //    captureSession.addInput(videoCapture)
        // }
        // or do it all on one line
        captureSession.addInput(AVCaptureDeviceInput(device: captureDevice, error: &err))
        
        let audioDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio)
        let audioInput: AnyObject! = AVCaptureDeviceInput.deviceInputWithDevice(audioDevice, error:&err)
        captureSession.addInput(audioInput as AVCaptureInput)
        
        if err != nil {
            println("error: \(err?.localizedDescription)")
        }
        
        // this is the video display, on screen as one records video
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        // this is where you could define a custom view
        cameraView.layer.addSublayer(previewLayer)
        previewLayer?.frame = self.view.layer.frame
        
        if !captureSession.running {
            // set JPEG output
            videoRecordingOutput = AVCaptureMovieFileOutput()
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
        
    }
    
    
    
    // end video code -------------------------------------------
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func start(sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) {
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
    
    func longPress(sender:UILongPressGestureRecognizer!) {
        let longPress = sender as UILongPressGestureRecognizer
            if (sender.state == UIGestureRecognizerState.Ended) {
                NSLog("done with long press")
              self.videoRecordingOutput?.stopRecording()
                NSLog("Done Recording")
            } else if (sender.state == UIGestureRecognizerState.Began) {
                NSLog("long press detected")
                var url:NSURL = tempFileUrl()
                videoRecordingOutput?.startRecordingToOutputFileURL(url, recordingDelegate:delegate)
        }
    }
    
    
    func captureOutput(captureOutput: AVCaptureFileOutput!,
        didStartRecordingToOutputFileAtURL fileURL: NSURL!,
        fromConnections connections: [AnyObject]!){
            NSLog("recording has begain with %@", fileURL)
            
    }
    
    func captureOutput(captureOutput: AVCaptureFileOutput!,
        didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!,
        fromConnections connections: [AnyObject]!,
        error: NSError!) {
             NSLog("*** recording has ended with %@", outputFileURL)
            let tempImage = outputFileURL as NSURL!
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
            self.uploadImageURL = NSURL.fileURLWithPath(directory)
            
            self.dismissViewControllerAnimated(true, completion: {})
            self.uploadFileURL = NSURL.fileURLWithPath(pathString!)
            self.saveImageToAWS()
            self.saveToAWS()

            
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        
        let progress = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
        
        // NSLog("UploadTask progress: %lf", progress)
        
        dispatch_async(dispatch_get_main_queue()) {
            self.progressView.progress = progress
            self.statusLabel.text = "Uploading..."
        }
        
    }
    
    func tempFileUrl()->NSURL{
        // var movieString:NSString = "camera.mov"
        
        let tempDirectoryTemplate = NSTemporaryDirectory().stringByAppendingPathComponent("camera.mov")
        let url = NSURL.fileURLWithPath(tempDirectoryTemplate)
        // let url = NSURL.fileURLWithPath(movieString)
        // let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        // let documentsPath = paths.first as? String
        // let filePath = documentsPath! + "/" + movieString
        if NSFileManager.defaultManager().fileExistsAtPath(tempDirectoryTemplate) {
            NSFileManager.defaultManager().removeItemAtPath(tempDirectoryTemplate, error: nil)
        }
        
        return url!
        
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        
        if (error == nil) {
            dispatch_async(dispatch_get_main_queue()) {
                self.successCount = self.successCount.integerValue+1
                // NSLog("success count: %@", self.successCount.isEqual(2) )
                // post to snap server
                // video id, user id, lat, long
                if ( self.successCount.isEqual(2) ) {
                  self.statusLabel.text = "Upload Successfully"
                  self.postSnap(self.sharedInstance.latitude,long: self.sharedInstance.longitute,video: self.sharedInstance.lastVideoUploadID, image: self.sharedInstance.lastImgUploadID)
                  self.successCount = 0
                }
            } // end dispatch_async()
        } else {
            dispatch_async(dispatch_get_main_queue()) {
                self.statusLabel.text = "Upload Failed"
            }
            // NSLog("S3 UploadTask: %@ completed with error: %@", task, error!.localizedDescription);
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
        self.uploadImageURL = NSURL.fileURLWithPath(directory)
        
        self.dismissViewControllerAnimated(true, completion: {})
        self.uploadFileURL = NSURL.fileURLWithPath(pathString!)
        self.saveImageToAWS()
        self.saveToAWS()
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
        println("locations = \(locValue.latitude) \(locValue.longitude)")
        sharedInstance.latitude =  String(format: "%f", locValue.latitude)
        sharedInstance.longitute = String(format: "%f", locValue.longitude)
        
    }
    
    func locationManager(manager: CLLocationManager!,
        didChangeAuthorizationStatus status: CLAuthorizationStatus)
        
    {
        if status == .Authorized || status == .AuthorizedWhenInUse {
            // NSLog(".Authorized || .AuthorizedWhenInUse block")
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
    
    func postSnap(lat:NSString,long:NSString,video:NSString,image:NSString) -> Bool {
        userObject.apiObject.createSnap(lat,long:long,video:video,image:image)
        return true;
    }
    
}

