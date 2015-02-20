//
//  DistrictModel.swift
//  slide
//
//  Created by Justin Zollars on 2/13/15.
//  Copyright (c) 2015 rmb. All rights reserved.
//

import UIKit

class DistrictModel: NSObject {
    
    var name: String
    let img: String
    let id: String
    
    init(name:String, img:String, id:String) {
        self.name = name
        self.img = img
        self.id = id
    }
    
}
