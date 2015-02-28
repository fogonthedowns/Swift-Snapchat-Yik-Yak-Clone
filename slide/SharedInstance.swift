//
//  SharedInstance.swift
//  slide
//
//  Created by Justin Zollars on 2/14/15.
//  Copyright (c) 2015 rmb. All rights reserved.
//

import Foundation

import Foundation

class SharedViewData {
    
    var cameraViewController:CameraViewController!
    
    class var sharedInstance :SharedViewData {
        struct Singleton {
            static let instance = SharedViewData()
        }
        
        return Singleton.instance
    }
}





