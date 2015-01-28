//
//  APIModel.swift
//  slide
//
//  Created by Justin Zollars on 1/28/15.
//  Copyright (c) 2015 rmb. All rights reserved.
//

import UIKit

class APIModel: NSObject {
    
    // var url: NSString // no need (!). It will be initialised from controller
    var data: NSMutableData = NSMutableData()
    var accessToken: NSString = ""
    var apiUserId: NSString = ""
    var userID: NSString = ""
    
    override init() {
        super.init()
    }
    
    func createUser(Userid:NSString) {
      NSLog("********************************************** createUser() called with Device Token=:%@", Userid)
      userID = Userid
      var requestUrl = "https://airimg.com/profiles/new?token=17975700jDLD5HQtiLbKjwaTkKmZK7zTQO8l5CEmktBzVEAtY&profile[device_token]=" + self.userID +  "&profile[email]=u@u.com&profile[password]=a&profile[os]=ios"
        self.postRequest(requestUrl)
    }
    
    func postRequest(url:String) {
        var url = url
        NSLog("url:%@", url)
        let fileUrl = NSURL(string: url)
        var request = NSMutableURLRequest(URL: NSURL(string: url)!, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData, timeoutInterval: 5)
        var response: NSURLResponse?
        var error: NSError?
        request.HTTPMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        var connection: NSURLConnection = NSURLConnection(request: request, delegate: self, startImmediately: true)!;
    }
    
    func connection(didReceiveResponse: NSURLConnection!, didReceiveResponse response: NSURLResponse!) {
        // Received a new request, clear out the data object
        self.data = NSMutableData()
    }
    
    func connection(connection: NSURLConnection!, didReceiveData data: NSData!) {
        // Append the received chunk of data to our data object
        self.data.appendData(data)
    }
    
    // returns jsonResult as NSDictionary
    
    func connectionDidFinishLoading(connection: NSURLConnection!) {
        // Request complete, self.data should now hold the resulting info
        // Convert the retrieved data in to an object through JSON deserialization
        var err: NSError
        var jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil) as NSDictionary
        // TODO fucking ugly, this needs to be out of this function, yuck.
        self.processResults(jsonResult);
    }
    
    func processResults(jsonResult: NSDictionary) {
        if jsonResult.count>0 {
            if (jsonResult["access_token"] != nil) {
                self.accessToken = jsonResult["access_token"] as NSString
                self.apiUserId = jsonResult["_id"] as NSString
                NSLog("accessToken:%@", accessToken)
                NSLog("snap ID:%@", apiUserId)
                self.updateUser()
            }
        }
    }
    
    func updateUser(){
        let appDelegate =
        UIApplication.sharedApplication().delegate as AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        var request = NSBatchUpdateRequest(entityName: "User")
        request.predicate = NSPredicate(format: "identity == %@", self.userID)
        request.propertiesToUpdate = ["accessToken":self.accessToken, "apiUserId":self.apiUserId]
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
    } // end updateUser()
}