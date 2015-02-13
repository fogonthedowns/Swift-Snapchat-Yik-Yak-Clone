//
//  DistrictModel.swift
//  slide
//
//  Created by Justin Zollars on 2/13/15.
//  Copyright (c) 2015 rmb. All rights reserved.
//

import UIKit

class DistrictModel: NSObject {
    
    let polygon: NSArray
    var name: String
    let img: String
    
    init(polygon: NSArray, name:String, img:String) {
        self.polygon = polygon
        self.name = name
        self.img = img
    }
    
}
