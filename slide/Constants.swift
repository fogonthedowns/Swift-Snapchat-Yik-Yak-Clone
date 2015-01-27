//
//  Constants.swift
//  slide
//
//  Created by Justin Zollars on 1/27/15.
//  Copyright (c) 2015 Slide App. All rights reserved.
//

import Foundation

//WARNING: To run this sample correctly, you must set an appropriate AWSAccountID and Cognito Identity.
let AWSAccountID: String = "919607760751"
let CognitoPoolID: String = "us-east-1:685281b0-86e0-4c38-ad8f-120806219e3e"
let CognitoRoleAuth: String? = "arn:aws:iam::919607760751:role/Cognito_SlideAppAuth_Role"
let CognitoRoleUnauth: String? = "arn:aws:iam::919607760751:role/Cognito_SlideAppUnauth_Role"


//WARNING: To run this sample correctly, you must set an appropriate bucketName and downloadKeyName.
let S3BucketName: String = "slideby"
let S3DownloadKeyName: String = "jonathan_some_file.txt"


let S3UploadKeyName: String = "capturedvideo.MOV"
let BackgroundSessionUploadIdentifier: String = "com.slideby.s3BackgroundTransferSwift.uploadSession"
let BackgroundSessionDownloadIdentifier: String = "com.slideby.s3BackgroundTransferSwift.downloadSession"
