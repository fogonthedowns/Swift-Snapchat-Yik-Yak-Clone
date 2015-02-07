//
//  UserModel.swift
//  slide
//
//  Created by Justin Zollars on 1/28/15.
//  Copyright (c) 2015 rmb. All rights reserved.
//

import UIKit

class UserModel: NSObject {
    var userModel = [NSManagedObject]()
    let apiObject = APIModel();
    
    override init() {
        super.init()
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
                var randomString = CameraViewController.randomStringWithLength(50)
                self.saveUser(randomString)
            } else {
                println("***************** I Found a user! **********************")
                var userRow = userModel[0]
                apiObject.userID = userRow.valueForKey("identity") as String!
                apiObject.accessToken = userRow.valueForKey("accessToken") as String!
                apiObject.apiUserId = userRow.valueForKey("apiUserId") as String!
                NSLog("User:%@", apiObject.userID)
                NSLog("User AccessToken:%@", apiObject.accessToken)
                NSLog("User apiUserId:%@", apiObject.apiUserId)
                
            }
        } else {
            println("Could not fetch \(error), \(error!.userInfo)")
        }
    } // end findUser()
    
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
            apiObject.userID = userRow.valueForKey("identity") as String!
            self.postUsertoSnapServer()
            NSLog("User:%@", apiObject.userID)
        } // end saveUser() (create new user)
    
    // this function uses the APIModel() instance apiObject
    // this will require completion checking, if this is not completed you will need to post again, with the saved id
    func postUsertoSnapServer()-> Bool {
        apiObject.createUser(apiObject.userID)
        return true;
    }
    
}
