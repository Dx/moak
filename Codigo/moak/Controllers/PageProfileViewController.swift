//
//  PageProfileViewController.swift
//  moak
//
//  Created by Dx on 12/09/16.
//  Copyright © 2016 Dx. All rights reserved.
//

import UIKit

class PageProfileViewController: UIPageViewController {
    
    let defaults = UserDefaults.standard
    
    fileprivate(set) lazy var orderedViewControllers: [UIViewController] = {
        return [self.newViewController("BarCodeScannerView"), self.newViewController("AddProductDescription"), self.newViewController("MagicListView")]
    }()
    
    fileprivate func newViewController(_ prefijo: String) -> UIViewController {
        let viewController = UIStoryboard(name: "Main", bundle: nil) .
            instantiateViewController(withIdentifier: "\(prefijo)Controller")
        
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = self
        
        
        if (self.defaults.string(forKey: defaultKeys.CaptureMode) == nil) {
        
        	if let firstViewController = orderedViewControllers.first {
            	setViewControllers([firstViewController],
                               direction: .forward,
                               animated: true,
                               completion: nil)
        	}
        } else {
            
            switch self.defaults.string(forKey: defaultKeys.CaptureMode)! {
            case "BarCode":
                setViewControllers([orderedViewControllers[0]],
                                       direction: .forward,
                                       animated: true,
                                       completion: nil)
            case "Description":
                setViewControllers([orderedViewControllers[1]],
                                       direction: .forward,
                                       animated: true,
                                       completion: nil)
            case "MagicList":
                setViewControllers([orderedViewControllers[2]],
                                       direction: .forward,
                                       animated: true,
                                       completion: nil)
            default:
                print("ups sin opción")
            }
        }
        
        
    }
    
    @objc(pageViewController:viewControllerBeforeViewController:) func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.firstIndex(of: viewController) else {
            return nil
        }
        
        let previousIndex = viewControllerIndex - 1
        
        // User is on the first view controller and swiped left to loop to
        // the last view controller.
        guard previousIndex >= 0 else {
            return orderedViewControllers.last
        }
        
        guard orderedViewControllers.count > previousIndex else {
            return nil
        }
        
        return orderedViewControllers[previousIndex]
    }
    
    @objc(pageViewController:viewControllerAfterViewController:) func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.firstIndex(of: viewController) else {
            return nil
        }
        
        let nextIndex = viewControllerIndex + 1
        let orderedViewControllersCount = orderedViewControllers.count
        
        // User is on the last view controller and swiped right to loop to
        // the first view controller.
        guard orderedViewControllersCount != nextIndex else {
            return orderedViewControllers.first
        }
        
        guard orderedViewControllersCount > nextIndex else {
            return nil
        }
        
        return orderedViewControllers[nextIndex]
    }
    
}

extension PageProfileViewController: UIPageViewControllerDataSource {
    
//    func pageViewController(pageViewController: UIPageViewController,
//                            viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
//        return nil
//    }
//    
//    func pageViewController(pageViewController: UIPageViewController,
//                            viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
//        return nil
//    }
    
}

