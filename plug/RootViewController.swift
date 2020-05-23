//
//  RootViewController.swift
//  plug
//
//  Created by Robert Crosby on 5/23/20.
//  Copyright © 2020 Robert Crosby. All rights reserved.
//

import UIKit

class RootViewController: UITabBarController {
    
    var postViewController:PostViewController?
    
    init() {
        postViewController = PostViewController()
        super.init(nibName: nil, bundle: nil)
        let postNav = UINavigationController.init(rootViewController: postViewController!)
        postNav.navigationBar.prefersLargeTitles = true
        self.viewControllers = [
            postNav
        ]
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
