//
//  VideoModel.swift
//  slide
//
//  Created by Justin Zollars on 1/31/15.
//  Copyright (c) 2015 rmb. All rights reserved.
//

import UIKit

class VideoModel: NSObject {

    let film: String
    var userId: String
    let img: String
    let userDescription: String
    let votes: NSNumber
    let comments: NSMutableDictionary
    let voters: NSMutableDictionary
    let flags: NSNumber
    var videoNSManagedObject = [NSManagedObject]()
    
    init(id: String, user:String, img:String, description:String, votes:NSNumber, comments:NSMutableDictionary, voters:NSMutableDictionary, flags:NSNumber) {
        self.film = id
        self.userId = user
        self.img = img
        self.userDescription = description
        self.votes = votes
        self.comments = comments
        self.voters = voters
        self.flags = flags
    }
    
    // searches by a userID, then it updates the access token
    // this should probably be moved to the User Model since its a CRUD event, even though its tied to the response
    // function above, processResults(), this probably doesn't matter bc its saving something. This could be made
    // more general by passing a key, to the update field and value of that being updated
    // called on didRecieveJSONResult
    
    func findOrCreate(districtId:String) {
        var appDel: AppDelegate = (UIApplication.sharedApplication().delegate as AppDelegate)
        var context: NSManagedObjectContext = appDel.managedObjectContext!
        var managedObject: NSManagedObject!
        var fetchRequest = NSFetchRequest(entityName: "Video")
        fetchRequest.predicate = NSPredicate(format: "film = %@", self.film)
        
        if let fetchResults = appDel.managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [NSManagedObject] {
            if fetchResults.count != 0{
                NSLog("***************** found film, no need to create %@", self.film)
                var managedObject = fetchResults[0]
                // println("date %@", managedObject.valueForKey("date"))
                // println("id %@", managedObject.valueForKey("film"))
                // println("bool %@", managedObject.valueForKey("downloaded"))
                // println("hoodId %@", managedObject.valueForKey("districtId"))
            } else {
                println("***************** creating a new video record")
                let entity =  NSEntityDescription.entityForName("Video",
                    inManagedObjectContext:
                    context)
                
                let managedObject = NSManagedObject(entity: entity!,
                    insertIntoManagedObjectContext:context)
                
                //  set film id to film row
                managedObject.setValue(self.film, forKey: "film")
                managedObject.setValue(districtId, forKey: "districtId")
                println("**************** creating a video with hoodId %@",districtId)
                
                // handle errors
                var error: NSError?
                if !context.save(&error) {
                    println("Could not save")
                }
                //5
                videoNSManagedObject.append(managedObject)
                var row = videoNSManagedObject[0]
                var logforrecord = row.valueForKey("film") as String!
                NSLog("Video:%@", logforrecord)
            } // else
        }
    } // end findOrCreate()
    
    class func saveFilmAsDownloaded(film:NSString) {
        var appDel: AppDelegate = (UIApplication.sharedApplication().delegate as AppDelegate)
        var context: NSManagedObjectContext = appDel.managedObjectContext!
        var managedObject: NSManagedObject!
        var fetchRequest = NSFetchRequest(entityName: "Video")
        fetchRequest.predicate = NSPredicate(format: "film = %@", film)
        
        if let fetchResults = appDel.managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [NSManagedObject] {
            if fetchResults.count != 0{
                NSLog("***************** found film! updating status %@", film)
                var managedObject = fetchResults[0]
                managedObject.setValue(true, forKey: "downloaded")
                var date = NSDate()
                managedObject.setValue(date, forKey: "date")
                context.save(nil)
                // notification center - Post Notification!
                // NSNotificationCenter.defaultCenter().postNotificationName(getSnapsBecauseIhaveAUserLoaded, object: self)
            } else {
                println("***************** crap, no record found, so create it.")
                // TODO
                // Create an API endpoint to warn us that something very bad is happening in nature
                // this could be a general api endpoint, used to report bugs
                // it could simply accept a string
                // for the error description
                // in this case no record found
            } // else
        }
    } //  saveFilmAsDownloaded()
    
    class func saveFilmAsFlagged(film:NSString) {
        var appDel: AppDelegate = (UIApplication.sharedApplication().delegate as AppDelegate)
        var context: NSManagedObjectContext = appDel.managedObjectContext!
        var managedObject: NSManagedObject!
        var fetchRequest = NSFetchRequest(entityName: "Video")
        fetchRequest.predicate = NSPredicate(format: "film = %@", film)
        
        if let fetchResults = appDel.managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [NSManagedObject] {
            if fetchResults.count != 0{
                NSLog("***************** found film! updating status %@", film)
                var managedObject = fetchResults[0]
                managedObject.setValue(true, forKey: "flagged")
                context.save(nil)
            } else {
                println("***************** crap, no record found, so create it.")
                // TODO
                // Create an API endpoint to warn us that something very bad is happening in nature
                // this could be a general api endpoint, used to report bugs
                // it could simply accept a string
                // for the error description
                // in this case no record found
            } // else
        }
    } //  saveFilmAsFlagged()
    
    class func findByDistrict(district:NSString) -> NSArray? {
        var appDel: AppDelegate = (UIApplication.sharedApplication().delegate as AppDelegate)
        var context: NSManagedObjectContext = appDel.managedObjectContext!
        var managedObject: NSManagedObject!
        var results: NSArray?
        var fetchRequest = NSFetchRequest(entityName: "Video")
        fetchRequest.predicate = NSPredicate(format: "districtId = %@ AND downloaded = %@ AND flagged = %@", district, true, false)
        
        if let fetchResults = appDel.managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [NSManagedObject] {
            if fetchResults.count != 0{
                NSLog("***************** found film for district id: %@", district)
                results = fetchResults
                
            } else {
                println("***************** crap, no record found, so create it.")
                results = []
            } // else
        }
        return results
    } //  findByDistrict()
    
    class func deleteOldFilms() {
        var appDel: AppDelegate = (UIApplication.sharedApplication().delegate as AppDelegate)
        var context: NSManagedObjectContext = appDel.managedObjectContext!
        var managedObject: NSManagedObject!
        var fetchRequest = NSFetchRequest(entityName: "Video")
        let date = NSCalendar.currentCalendar().dateByAddingUnit(.DayCalendarUnit,
            value: -2, toDate: NSDate(), options: nil)
        fetchRequest.predicate = NSPredicate(format: "date <= %@", date!)
        
        if let fetchResults = appDel.managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [NSManagedObject] {
            if fetchResults.count != 0{
                NSLog("***************** found film! updating status %@", fetchResults)
            } else {
                println("***************** no films found")
            } // else
        }
    } //  saveFilmAsDownloaded()

    
}
