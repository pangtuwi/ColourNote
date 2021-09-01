//
//  ActivitySwipeViewController.swift
//  eFit
//
//  Created by Paul Williams on 13/10/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//
// https://stackoverflow.com/questions/18398796/uipageviewcontroller-and-storyboard/26024779#26024779
// https://medium.com/@LKChk/ios-use-uipageviewcontroller-to-build-swipe-views-dc36b8225013


import UIKit


class ActivitySwipeViewController: UIPageViewController , UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    var pages = [UIViewController]()
  
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        self.dataSource = self
        
        let p1: UIViewController! = storyboard?.instantiateViewController(withIdentifier: "ActivityMap")
        let p2: UIViewController! = storyboard?.instantiateViewController(withIdentifier: "ActivityLineChart")
        let p3: UIViewController! = storyboard?.instantiateViewController(withIdentifier: "ActivityBarChart")
        let p4: UIViewController! = storyboard?.instantiateViewController(withIdentifier: "ID4")
        
        pages.append(p1)
        pages.append(p2)
        pages.append(p3)
        pages.append(p4)

        setViewControllers([p1], direction: UIPageViewController.NavigationDirection.forward, animated: false, completion: nil)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController)-> UIViewController? {
        
        let cur = pages.index(of: viewController)!
        
        // if you prefer to NOT scroll circularly, simply add here:
        // if cur == 0 { return nil }
        
        let prev = abs((cur - 1) % pages.count)
        return pages[prev]
        
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController)-> UIViewController? {
        
        let cur = pages.index(of: viewController)!
        
        // if you prefer to NOT scroll circularly, simply add here:
        // if cur == (pages.count - 1) { return nil }
        
        let nxt = abs((cur + 1) % pages.count)
        return pages[nxt]
    }
    
    func presentationIndex(for pageViewController: UIPageViewController)-> Int {
        return pages.count
    }
}
