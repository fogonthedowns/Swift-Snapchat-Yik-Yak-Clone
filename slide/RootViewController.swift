//
//  RootViewController.swift
//  slide
//
//  Created by Justin Zollars on 2/12/15.
//  Copyright (c) 2015 rmb. All rights reserved.
//

import UIKit

let didFinishUploadPresentNewPage = "com.snapAPI.presentNewPage"
let didClickToNavigateToCamera = "com.snapAPI.presentCamera"
let didClickToNavigateToDistricts = "com.snapAPI.presentDistricts"


class RootViewController: UIPageViewController, UIPageViewControllerDataSource {
    
    var navViewController : UINavigationController!
    var cameraViewController : CameraViewController!
    var districtsViewController: DistrictsUINavigationController!
    var currentViewController:UIViewController? = nil
        
    override func viewDidLoad() {
        super.viewDidLoad()
        NSLog("*****************************")
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "navigateHome", name: didFinishUploadPresentNewPage, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "navigateToCamera", name: didClickToNavigateToCamera, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "navigateToDistricts", name: didClickToNavigateToDistricts, object: nil)
        
        // set UIPageViewControllerDataSource
        self.dataSource = self
        
        // Reference all of the view controllers on the storyboard
        self.navViewController = self.storyboard?.instantiateViewControllerWithIdentifier("navViewController") as? CustomNavigation
        self.navViewController.title = "Soma"
        // println("homeTableViewController has landed!")
        
        self.cameraViewController = self.storyboard?.instantiateViewControllerWithIdentifier("cameraViewController") as? CameraViewController
        self.cameraViewController.title = "Camera"
        
        self.districtsViewController = self.storyboard?.instantiateViewControllerWithIdentifier("districtsUINavigationController") as? DistrictsUINavigationController
        self.districtsViewController.title = "San Francisco"
        // println("Camera has landed!")
        self.currentViewController = self.navViewController
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
        
        switch viewController.restorationIdentifier! {
        case "cameraViewController":
            return navViewController
        case "navViewController":
            return districtsViewController
        case "districtsUINavigationController":
            return nil
        default:
            return nil
        }
    }
    
    //  order: San Francisco(districtsViewController) |soma (navViewController) |camera (cameraViewController)
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        NSLog("restorationIdentifie@%", viewController.restorationIdentifier!)
        switch viewController.restorationIdentifier! {
        case "navViewController":
            return cameraViewController
        case "cameraViewController":
            return nil
        case "districtsUINavigationController":
            return navViewController
        default:
            return nil
            
        }
    }
    
    func navigateHome() {
        var navigateToHome : NSArray = [self.navViewController]
        self.setViewControllers(navigateToHome, direction: .Forward, animated: true, completion: nil)
    }
    
    func navigateToCamera() {
        var navigateToHome : NSArray = [self.cameraViewController]
        self.setViewControllers(navigateToHome, direction: .Forward, animated: true, completion: nil)
    }

    func navigateToDistricts() {
        var navigateToHome : NSArray = [self.districtsViewController]
        self.setViewControllers(navigateToHome, direction: .Reverse, animated: true, completion: nil)
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
