//
//  CustomNavigation.swift
//  slide
//
//  Created by Justin Zollars on 2/1/15.
//  Copyright (c) 2015 rmb. All rights reserved.
//

import UIKit

class CustomNavigation: UINavigationController {
    var cameraButton:UIBarButtonItem = UIBarButtonItem()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var image : UIImage = UIImage(named:"camera")!
        image.imageWithRenderingMode(.AlwaysOriginal)
        cameraButton.setBackButtonBackgroundImage(image, forState: .Normal, barMetrics: .Default)
        
       
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
        
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
