//
//  CommentsViewController.swift
//  slide
//
//  Created by Justin Zollars on 2/17/15.
//  Copyright (c) 2015 rmb. All rights reserved.
//

import UIKit

class CommentsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var snapBody: UILabel!
    @IBOutlet weak var likeImage: UIImageView!
    @IBOutlet weak var snapImage: UIImageView!
    @IBOutlet weak var newCommentBody: UITextField!
    let sharedInstance = VideoDataToAPI.sharedInstance
    let userObject = UserModel()
    
    var commentModelList: NSMutableArray = [] // This is the array that my tableView
    
    override func viewDidLoad() {
        super.viewDidLoad()
        userObject.findUser()
        
        var tap:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "DismissKeyboard")
        self.tableView.addGestureRecognizer(tap)

        // self.tableView.registerClass(CommentTableViewCell.self, forCellReuseIdentifier: "CommentCell")
        tableView.delegate = self
        tableView.dataSource = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        self.processComments()
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
        self.postComment(self.newCommentBody.text)
        var commentModel = CommentModel(
            body: self.newCommentBody.text as NSString,
            user: "blank" as NSString
        )
        commentModelList.addObject(commentModel)
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            // NSLog("refreshing \(self.videoModelList)")
            self.tableView.reloadData()
        })
    }
    
    @IBAction func clickBackHome(sender: AnyObject) {
        NSNotificationCenter.defaultCenter().postNotificationName(didClickToNavigateBackHome, object: self)
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
    
    func DismissKeyboard(){
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        self.tableView.endEditing(true)
    }
    
    func postComment(body:NSString) -> Bool {
        self.newCommentBody.text = ""
        userObject.apiObject.createComment(body, film:self.sharedInstance.videoForCommentController.film)
        return true;
    }

}
