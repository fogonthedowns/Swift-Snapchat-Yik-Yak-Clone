//
//  APIModel.swift
//  slide
//
//  Created by Justin Zollars on 1/28/15.
//  Copyright (c) 2015 rmb. All rights reserved.
//

import UIKit

// This class is responible for calls to the Snap API server


class APIModel: NSObject {
    
    // var url: NSString // no need (!). It will be initialised from controller
    // These are set by the UserModel
    var data: NSMutableData = NSMutableData()
    var accessToken: NSString = ""
    var apiUserId: NSString = ""
    // TODO rename to device token
    var userID: NSString = ""

    
    // It doesn't look like Userid is used, rather self.userID is used. This is set by a chain method call apiObject.userid
    // from the userObject.findUser() on ViewDidLoad. We always have a user, we find one, and with it from disk and we set
    // the userid, accesstoken and other info
    func getSnaps(lat:NSString,long:NSString, hood:NSString, delegate:APIProtocol) {
       var requestUrl = "https://airimg.com/snaps"
        // ?token=17975700jDLD5HQtiLbKjwaTkKmZK7zTQO8l5CEmktBzVEAtY&device_token=" + self.userID + "&access_token=" + self.accessToken + "&lat=" + lat + "&long=" + polygon
        NSLog("getting Snaps")
        //        self.getRequest(requestUrl)
      
        request(.GET, requestUrl, parameters: ["hood": hood, "lat":lat, "long":long, "token":"17975700jDLD5HQtiLbKjwaTkKmZK7zTQO8l5CEmktBzVEAtY","device_token":self.userID, "access_token": self.accessToken])
            .responseJSON { (req, res, json, error) in
                if(error != nil) {
                    println(res)
                }
                else {
                    var json = JSON(json!)
                    NSLog("GET Result: \(json)")
                    
                    // Call delegate
                    delegate.didReceiveResult(json)
                }
        }
        
    }
    
    func getDistricts(lat:NSString,longitude: NSString, delegate:APIProtocol) {
        var requestUrl = "https://airimg.com/locations?token=17975700jDLD5HQtiLbKjwaTkKmZK7zTQO8l5CEmktBzVEAtY&device_token=" + self.userID + "&access_token=" + self.accessToken + "&lat=" + lat + "&long=" + longitude
        NSLog("getting districts")
        self.getRequest(requestUrl)
        request(.GET, requestUrl)
            .responseJSON { (req, res, json, error) in
                if(error != nil) {
                    NSLog("GET Error: \(error)")
                    println(res)
                }
                else {
                    var json = JSON(json!)
                    NSLog("GET Result: \(json)")
                    
                    // Call delegate
                    delegate.didReceiveResult(json)
                }
        }
    }
    
    
    
    func createUser(Userid:NSString) {
      NSLog("********************************************** createUser() called with Device Token=%@", Userid)
      userID = Userid
      var requestUrl = "https://airimg.com/profiles/new?token=17975700jDLD5HQtiLbKjwaTkKmZK7zTQO8l5CEmktBzVEAtY&profile[device_token]=" + self.userID +  "&profile[email]=u@u.com&profile[password]=a&profile[os]=ios"
        self.postRequest(requestUrl)
    }
    
    func createSnap(lat:NSString,long:NSString,video:NSString,image:NSString, description:NSString){
        let parameters = [
            "device_token":self.userID,
            "access_token": self.accessToken,
            "token": "17975700jDLD5HQtiLbKjwaTkKmZK7zTQO8l5CEmktBzVEAtY",
            "snap":[
                "userId": self.apiUserId,
                "img": image,
                "film": video,
                "lat": lat,
                "long":long,
                "description": description
            ]
        ]
        
        request(.POST, "https://airimg.com/snaps/new", parameters: parameters).validate().response { (request, response, data, error) in
            println(request)
            println(response)
             if (error == nil){
                 println("we have a good! response")
                didCompleteUploadWithNoErrors
                 NSNotificationCenter.defaultCenter().postNotificationName(getSnapsBecauseIhaveAUserLoaded, object: self)
             } else {
                println(error)
            }
        }
        
        // self.postRequest(requestUrl)
    }
    
    //
    func voteforSnap(video:NSString){
        let parameters = [
            "device_token":self.userID,
            "access_token": self.accessToken,
            "token": "17975700jDLD5HQtiLbKjwaTkKmZK7zTQO8l5CEmktBzVEAtY",
            "user_id": self.apiUserId,
            "film": video
        ]
        
        request(.PUT, "https://airimg.com/snaps/update", parameters: parameters).validate().response { (request, response, data, error) in
            println(request)
            println(response)
            if (error == nil){
                println("we have a good! update response")
                didCompleteUploadWithNoErrors
                NSNotificationCenter.defaultCenter().postNotificationName(getSnapsBecauseIhaveAUserLoaded, object: self)
            } else {
                println(error)
            }
        }
        
        // self.postRequest(requestUrl)
    }
    
    //
    func postRequest(url:NSString) {
        if var localURL = url as NSString? {
            NSLog("localURL: %@", localURL)
            let fileUrl:NSURL = NSURL(string: localURL)!

            var request = NSMutableURLRequest(URL: NSURL(string: localURL)!, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData, timeoutInterval: 5)
            var response: NSURLResponse?
            var error: NSError?
            request.HTTPMethod = "POST"
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            var connection: NSURLConnection = NSURLConnection(request: request, delegate: self, startImmediately: true)!;
            NSLog("posting")
        }
    }
    
    func getRequest(url:String) {
        var url = url
        NSLog("url:%@", url)
        let fileUrl = NSURL(string: url)
        var request = NSMutableURLRequest(URL: NSURL(string: url)!, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData, timeoutInterval: 5)
        var response: NSURLResponse?
        var error: NSError?
        request.HTTPMethod = "GET"
        request.setValue("text/plain; charset=utf-8", forHTTPHeaderField: "Content-Type")
        var connection: NSURLConnection = NSURLConnection(request: request, delegate: self, startImmediately: true)!;
    }
    
    func connection(didReceiveResponse: NSURLConnection!, didReceiveResponse response: NSURLResponse!) {
        // Received a new request, clear out the data object
        NSLog(" ----------------------------- didReceiveResponse() ----------------------------- ")
        self.data = NSMutableData()
    }
    
    func connection(connection: NSURLConnection!, didReceiveData data: NSData!) {
        NSLog(" ----------------------------- didReceiveData() ----------------------------- ")

        // Append the received chunk of data to our data object
        self.data.appendData(data)
    }
    
    // returns jsonResult as NSDictionary
    
    func connectionDidFinishLoading(connection: NSURLConnection!) {
         NSLog(" ----------------------------- connectionDidFinishLoading() ----------------------------- ")
        // Request complete, self.data should now hold the resulting info
        // Convert the retrieved data in to an object through JSON deserialization
        var err: NSError
        let json = JSON(data: data)
        self.processJson(json)
        
    }
    
    
    // TODO this is still a bit messy, this function handles the response of all API calls made through connnection delegate
    // It ended up this way because of a lack of being able to return a value to delegate functions
    // all processing events get lopped together for now, until this can be fixed in the future with a
    // better understanding of delegate on NSURLConnection() (connection) method
    

    func processJson(json:JSON) {
     
        NSLog(" ----------------------------- processJson() ----------------------------- ")
        if json.count>0 {
            if (json["access_token"] != nil) {
                NSLog(" ----------------------------- found access_token key ----------------------------- ")
                self.accessToken = json["access_token"].stringValue as NSString
                self.apiUserId = json["_id"].stringValue as NSString
                NSLog("accessToken:%@", accessToken)
                NSLog("snap ID:%@", apiUserId)
                self.updateUser()
            }
            
            if (json["success"] != nil){
                NSLog(" ----------------------------- video uploaded ----------------------------- ")
            }
        }
    }
    
    
    // searches by a userID, then it updates the access token
    // this should probably be moved to the User Model since its a CRUD event, even though its tied to the response
    // function above, processResults(), this probably doesn't matter bc its saving something. This could be made
    // more general by passing a key, to the update field and value of that being updated

    func updateUser() {
        var appDel: AppDelegate = (UIApplication.sharedApplication().delegate as AppDelegate)
        var context: NSManagedObjectContext = appDel.managedObjectContext!
        
        var fetchRequest = NSFetchRequest(entityName: "User")
        fetchRequest.predicate = NSPredicate(format: "identity = %@", self.userID)
        
        if let fetchResults = appDel.managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [NSManagedObject] {
            if fetchResults.count != 0{
                NSLog("saving access token now :%@", self.accessToken)
                var managedObject = fetchResults[0]
                managedObject.setValue(self.apiUserId, forKey: "apiUserId")
                managedObject.setValue(self.accessToken, forKey: "accessToken")
                context.save(nil)
                // notification center - Post Notification!
                NSNotificationCenter.defaultCenter().postNotificationName(getSnapsBecauseIhaveAUserLoaded, object: self)
            }
        }
    } // end updateUser()
}