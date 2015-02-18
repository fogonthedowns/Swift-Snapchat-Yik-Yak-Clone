//
//  CommentModel.swift
//  slide
//
//  Created by Justin Zollars on 2/18/15.
//  Copyright (c) 2015 rmb. All rights reserved.
//

import UIKit

class CommentModel: NSObject {
   
    let body: String
    var userId: String
    
    init(body: String, user:String) {
        self.body = body
        self.userId = user
    }
    
}
