//
//  CommentsViewController.swift
//  slide
//
//  Created by Justin Zollars on 2/17/15.
//  Copyright (c) 2015 rmb. All rights reserved.
//

import UIKit
import MediaPlayer

class CommentsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {

    @IBOutlet weak var snapView: UIView!
    @IBOutlet weak var commentCreateView: UIView!
    @IBOutlet var primaryView: UIView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var snapBody: UILabel!
    @IBOutlet weak var likeImage: UIImageView!
    @IBOutlet weak var snapImage: UIImageView!
    @IBOutlet weak var newCommentBody: UITextField!
    let sharedInstance = VideoDataToAPI.sharedInstance
    let userObject = UserModel()
    var moviePlayer:MPMoviePlayerController!
     let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
    
    var commentModelList: NSMutableArray = [] // This is the array that my tableView
    
    override func viewDidLoad() {
        super.viewDidLoad()
        userObject.findUser()
        var tap:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "DismissKeyboard")
        self.primaryView.addGestureRecognizer(tap)
//        self.snapView.addGestureRecognizer(tap)
        
        // self.tableView.registerClass(CommentTableViewCell.self, forCellReuseIdentifier: "CommentCell")
        tableView.delegate = self
        tableView.dataSource = self
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name:UIKeyboardWillShowNotification, object: nil);
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name:UIKeyboardWillHideNotification, object: nil);
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        self.processComments()
        let longpress = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
        longpress.minimumPressDuration = 0.35
        snapView.addGestureRecognizer(longpress)
        // setup the snap cell, text, links, image etc.
        // lots of repeated code, but we use the sharedInstance to pass data between controllers
        println("comments: %@", VideoDataToAPI.sharedInstance.videoForCommentController.comments)
        self.snapBody.text = sharedInstance.videoForCommentController.userDescription
        var urlString = "https://s3-us-west-1.amazonaws.com/slideby/" + sharedInstance.videoForCommentController.img
        let url = NSURL(string: urlString)
        let main_queue = dispatch_get_main_queue()
        // This is the temporary image, that loads before the Async images below
        self.snapImage.image = UIImage(named: ("placeholder"))
        // this allows images to load in the background
        // and allows the page to load without the image
        let backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        
        // Load Images Asynchroniously
        dispatch_async(backgroundQueue, {
            SGImageCache.getImageForURL(urlString) { image in
                if image != nil {
                    dispatch_async(dispatch_get_main_queue(), {
                        self.snapImage.contentMode = UIViewContentMode.ScaleAspectFill
                        self.snapImage.image = image;
                        self.snapImage.layer.cornerRadius = self.snapImage.frame.size.width  / 2;
                        self.snapImage.clipsToBounds = true;
                    })
                    
                }
            }
        })
    }
    
    // User Clicked to Post Comment
    @IBAction func userPostComment(sender: AnyObject) {
        var commentModel = CommentModel(
            body: self.newCommentBody.text as NSString,
            user: "blank" as NSString
        )
        commentModelList.addObject(commentModel)
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            // NSLog("refreshing \(self.videoModelList)")
            self.tableView.reloadData()
        })
        self.postComment(self.newCommentBody.text)
        self.DismissKeyboard()
    }
    
    @IBAction func clickBackHome(sender: AnyObject) {
        self.DismissKeyboard()
        NSNotificationCenter.defaultCenter().postNotificationName(didClickToNavigateBackHome, object: self)
    }
    
    
    @IBAction func clickReport(sender: AnyObject) {
        func handler(act:UIAlertAction!) {
           println("user clicked report")
           self.postFlag()
           var ty = UIAlertController(title: "Report created", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
            ty.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(ty, animated: true, completion: nil)
        }
        
        var alert = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        alert.addAction(UIAlertAction(title: "Report Inappropriate", style: .Destructive, handler: handler))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil))
      self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        self.view.endEditing(true);
        return false;
    }
    
    
    override func viewDidDisappear(animated: Bool) {
        self.snapBody.text = ""
        self.snapImage.image = UIImage(named: ("placeholder"))
    }
        
    // MARK: - Table view data source
    
   func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }
    
   func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return commentModelList.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("CommentCell") as CommentTableViewCell
        let comment: CommentModel = commentModelList[indexPath.row] as CommentModel
        cell.commentBody.text = comment.body
        return cell
    }

    // MARK:  UITableViewDelegate Methods
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let row = indexPath.row
        println(row)
    }
    
    func handleLongPress(sender:UILongPressGestureRecognizer!) {
        println("Long press Block .................");
        let filePath = determineFilePath(self.sharedInstance.videoForCommentController.film)
        
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
                self.view.addSubview(player.view)
            }
        }
    } // longPress
    
    
    func determineFilePath(file:NSString)-> NSString {
        let documentsPath = paths.first as? String
        let filePath = documentsPath! + "/" + file
        return filePath
    } // determineFilePath
    
    func processComments() {
        // local array var used in this function
        var comments: NSMutableArray = []
        
        for (key, value) in VideoDataToAPI.sharedInstance.videoForCommentController.comments {
            var commentModel = CommentModel(
                body: value as NSString,
                user: key as NSString
            )
            comments.addObject(commentModel)
        }
        
        // Set our array of new models
        commentModelList = comments
        // Make sure we are on the main thread, and update the UI.
        println(commentModelList)
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            // NSLog("refreshing \(self.videoModelList)")
            self.tableView.reloadData()
        })
    }
    
    func keyboardWillShow(sender: NSNotification) {
        self.view.frame.origin.y -= 255
    }
    func keyboardWillHide(sender: NSNotification) {
        self.view.frame.origin.y += 255
    }
    
    func DismissKeyboard(){
        println("tap" )
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        self.commentCreateView.endEditing(true)
    }
    
    func postComment(body:NSString) -> Bool {
        userObject.apiObject.createComment(body, film:self.sharedInstance.videoForCommentController.film)
        self.newCommentBody.text = ""
        return true;
    }
    
    func postFlag() {
        userObject.apiObject.createFlag(self.sharedInstance.videoForCommentController.film)
    }

}
