//
//  friendModel.swift
//  slide
//
//  Created by Justin Zollars on 2/25/15.
//  Copyright (c) 2015 rmb. All rights reserved.
//

import UIKit

class FriendModel: NSObject {
    let name: String
    var userId: String
    let img: String
    let phoneNumbers: NSArray
    let emailAddresses: NSArray
    
    init(name: String, phone:NSArray, email:NSArray) {
        self.name = name
        self.phoneNumbers = phone
        self.emailAddresses = email
        self.userId = ""
        self.img = ""
    }
}
