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
    let phone: NSArray
    let email: NSArray
    
    init(name: String, phone:NSArray, email:NSArray) {
        self.name = name
        self.phone = phone
        self.email = email
        self.userId = ""
        self.img = ""
    }
}
