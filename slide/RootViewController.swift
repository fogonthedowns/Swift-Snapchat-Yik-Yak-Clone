//
//  RootViewController.swift
//  slide
//
//  Created by Justin Zollars on 2/12/15.
//  Copyright (c) 2015 rmb. All rights reserved.
//

import UIKit

let didFinishUploadPresentNewPage = "com.snapAPI.presentNewPage"

class RootViewController: UIPageViewController, UIPageViewControllerDataSource {
    
    var navViewController : UINavigationController!
    var cameraViewController : CameraViewController!
    var districtsViewController: DistrictsTableViewController!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "navigateHome", name: didFinishUploadPresentNewPage, object: nil)
        // set UIPageViewControllerDataSource
        self.dataSource = self
        
        // Reference all of the view controllers on the storyboard
        self.navViewController = self.storyboard?.instantiateViewControllerWithIdentifier("navViewController") as? CustomNavigation
        self.navViewController.title = "Soma"
        // println("homeTableViewController has landed!")
        
        self.cameraViewController = self.storyboard?.instantiateViewControllerWithIdentifier("cameraViewController") as? CameraViewController
        self.cameraViewController.title = "Camera"
        
        self.districtsViewController = self.storyboard?.instantiateViewControllerWithIdentifier("districtsViewController") as? DistrictsTableViewController
        self.districtsViewController.title = "San Francisco"
        // println("Camera has landed!")
        
        // Set starting view controllers
        var startingViewControllers : NSArray = [self.cameraViewController]
        self.setViewControllers(startingViewControllers, direction: .Forward, animated: false, completion: nil)
        // println("Hey swab. C'mere. Listen up.")
        
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
            return districtsViewController
        case "San Francisco":
            return nil
        default:
            return nil
        }
    }
    
    //  order: San Francisco(districtsViewController) |soma (navViewController) |camera (cameraViewController)
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        
        switch viewController.title! {
        case "Soma":
            return cameraViewController
        case "Camera":
            return nil
        case "San Francisco":
            return navViewController
        default:
            return nil
            
        }
    }
    
    func navigateHome() {
        var navigateToHome : NSArray = [self.navViewController]
        self.setViewControllers(navigateToHome, direction: .Forward, animated: true, completion: nil)
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
