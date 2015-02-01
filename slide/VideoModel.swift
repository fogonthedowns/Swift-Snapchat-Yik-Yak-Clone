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
    init(id: String, user:String) {
        self.film = id
        self.userId = user
    }
    
}
