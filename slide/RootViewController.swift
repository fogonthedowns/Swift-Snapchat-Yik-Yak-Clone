//
//  RootViewController.swift
//  slide
//
//  Created by Justin Zollars on 2/12/15.
//  Copyright (c) 2015 rmb. All rights reserved.
//

import UIKit

class RootViewController: UIPageViewController, UIPageViewControllerDataSource {
    
    var navViewController : UINavigationController!
    var cameraViewController : CameraViewController!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set UIPageViewControllerDataSource
        self.dataSource = self
        
        // Reference all of the view controllers on the storyboard
        self.navViewController = self.storyboard?.instantiateViewControllerWithIdentifier("navViewController") as? CustomNavigation
        self.navViewController.title = "Soma"
        println("homeTableViewController has landed!")
        
        self.cameraViewController = self.storyboard?.instantiateViewControllerWithIdentifier("cameraViewController") as? CameraViewController
        self.cameraViewController.title = "Camera"
        println("Camera has landed!")
        
        // Set starting view controllers
        var startingViewControllers : NSArray = [self.cameraViewController]
        self.setViewControllers(startingViewControllers, direction: .Forward, animated: false, completion: nil)
        println("Hey swab. C'mere. Listen up.")
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        
        switch viewController.title! {
        case "Camera":
            return navViewController
        case "Soma":
            return cameraViewController
        default:
            return nil
        }
    }
    
    // pink green blue
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        
        switch viewController.title! {
        case "Soma":
            return cameraViewController
        case "Camera":
            return navViewController
        default:
            return nil
            
        }
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
