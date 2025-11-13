//
//  HomeViewController.swift
//  eFit
//
//  Created by Paul Williams on 20/10/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//
// https://medium.com/@PavelGnatyuk/large-title-and-search-in-ios-11-514d5e020cee
// https://robkerr.com/configuring-uiscrollview-in-a-storyboard-d579706b2591
// https://www.hackingwithswift.com/example-code/uikit/how-to-add-a-shadow-to-a-uiview
// https://github.com/zhangao0086/DrawingBoard/issues/3
// https://stackoverflow.com/questions/24803178/swift-navigation-bar-image-title


import UIKit

class HomeViewController: UIViewController {
    
    @IBOutlet weak var yourView : RoundUIView!
    @IBOutlet weak var runningLast7Label : UILabel!
    @IBOutlet weak var cyclingLast7Label : UILabel!
    @IBOutlet weak var swimmingLast7Label : UILabel!
    @IBOutlet weak var totalLast7Label : UILabel!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contentChangedNotification(_:)),
            name: DataLoaderNotification.contentUpdated,
            object: nil)
        
  /*   This version put image as background of title bar
         
         if let navController = navigationController {
            navController.navigationBar.prefersLargeTitles = true
            let img = UIImage(named: "navbar-background")
            navController.navigationBar.barTintColor = UIColor(patternImage: scaleImageToSize(size: self.view.bounds.size, image: img!))
            navController.navigationBar.isTranslucent = true
            navController.navigationBar.largeTitleTextAttributes = [
                NSAttributedString.Key.foregroundColor: UIColor.white
            ]
        }
  */
        
        if let navControllerBar = navigationController?.navigationBar {
        
            navControllerBar.prefersLargeTitles = true
            
            let logo = UIImage(named: "pw")
            let imageView = UIImageView(image:logo)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.contentMode = .scaleAspectFit
            
            navControllerBar.addSubview(imageView)
            
            imageView.addConstraint(imageView.widthAnchor.constraint(equalToConstant: 80))
            imageView.addConstraint(imageView.heightAnchor.constraint(equalToConstant: 80))
            navControllerBar.addConstraint (navControllerBar.rightAnchor.constraint(equalTo: imageView.rightAnchor, constant: 10))
            navControllerBar.addConstraint (navControllerBar.topAnchor.constraint(equalTo: imageView.topAnchor, constant: -5))
            
            imageView.layer.cornerRadius = 40//imageView.frame.size.width / 2
            imageView.clipsToBounds = true
            imageView.layer.borderWidth = 3.0
            imageView.layer.borderColor = UIColor.white.cgColor
        }
    } //viewDidLoad
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        updateViews()
    }
    
    
    func updateViews() {
        let last7Days = ActivityCount(dayCount: 7)
        runningLast7Label.text = "\(last7Days.noRuns)x Running = \(last7Days.runningTimeString())"
        cyclingLast7Label.text = "\(last7Days.noCycles)x Cycling = \(last7Days.cyclingTimeString())"
        swimmingLast7Label.text = "\(last7Days.noSwims)x Swimming = \(last7Days.swimmingTimeString())"
        totalLast7Label.text = "Total    \(last7Days.totalTimeString())  -  \(last7Days.TSSTotal) TSS"
        
    }
}

// MARK: - Notification handlers
extension HomeViewController {
    @objc func contentChangedNotification(_ notification: Notification!) {
        updateViews()
    }
}


