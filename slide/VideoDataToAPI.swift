//
//  VideoDataToAPI.swift
//  slide
//
//  Created by Justin Zollars on 2/2/15.
//  Copyright (c) 2015 rmb. All rights reserved.
//

import Foundation

class VideoDataToAPI {
    
    var lastVideoUploadID: String = ""
    var lastImgUploadID: String = ""
    var latitude: String = ""
    var longitute: String = ""
    var downloadName: String = ""
    var listOfVideosToDownload: NSMutableArray = []
    // var userObject = UserModel()
    var polygon: NSArray!
    
    
    class var sharedInstance :VideoDataToAPI {
        struct Singleton {
            static let instance = VideoDataToAPI()
        }
        
        return Singleton.instance
    }
}