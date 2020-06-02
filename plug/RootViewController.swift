//
//  RootViewController.swift
//  plug
//
//  Created by Robert Crosby on 5/23/20.
//  Copyright © 2020 Robert Crosby. All rights reserved.
//

import UIKit
import Firebase

let headerFont = UIFont.systemFont(ofSize: 34, weight: .bold)
let titleFont = UIFont.systemFont(ofSize: 24, weight: .bold)
let buttonFont = UIFont.systemFont(ofSize: 16, weight: .bold)
let subtitleFont = UIFont.systemFont(ofSize: 12, weight: .regular)

@objc protocol RootDelegate: class {
    @objc func authenticationChanged()
    @objc func showSeller()
    @objc func hideSeller()
//    @objc func refreshMyStuff()
    @objc func showAlert(title: String?, message: String)
}

extension RootViewController: RootDelegate {
    @objc func authenticationChanged() {
        for (i, view) in self.viewControllers!.enumerated() {
            if let _ = view as? PostViewController {
                self.viewControllers?.remove(at: i)
                break
            }
        }
    }
    
    @objc func showSeller() {
        for view in self.viewControllers! {
            if let _ = view as? PostViewController {
                return
            }
        }
        self.postViewController = PostViewController.init()
        self.postViewController?.delegate = self
        self.viewControllers?.append(postViewController!)
    }
    
    @objc func hideSeller() {
        for (i, view) in self.viewControllers!.enumerated() {
            if let _ = view as? PostViewController {
                self.viewControllers?.remove(at: i)
                break
            }
        }
    }
    
//    func refreshMyStuff() {
//        self.favoritesListener = nil
//        self.offersListener = nil
//        self.offers = nil
//        self.favorites = nil
//        getOffers()
//        getFavorites()
//    }
//
    @objc func showAlert(title: String?, message: String) {
        let alert = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        self.present(alert, animated: true) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                alert.dismiss(animated: true, completion: nil)
            }
        }
        
    }
    
    
}

class RootViewController: UITabBarController {
    
    static let dfm: DateFormatter = {
        let dfm = DateFormatter()
        dfm.dateFormat = "EEEE, MMMM d_h:mm a"
        return dfm
    }()
    
    var browseViewController:BrowseViewController?
    
    var postViewController:PostViewController?
    
    var accountViewController:AccountViewController?
    
    var myStuffViewController:MyStuffViewController?
    
    var personalViewController:PersonalViewController?
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        
//        let brandNav = UINavigationController.init(rootViewController: BrandViewController.init())
        
        let width = (self.view.frame.size.width-30-15)/2
        browseViewController = BrowseViewController.init(screenWidth: self.view.frame.size.width, itemSize: CGSize.init(width: width, height: width+60))
        let browseNav = UINavigationController.init(rootViewController: browseViewController!)
        browseNav.navigationBar.prefersLargeTitles = true
        
        personalViewController = PersonalViewController.init()
        let personalNav = UINavigationController.init(rootViewController: personalViewController!)
        personalNav.navigationBar.prefersLargeTitles = true
        
        myStuffViewController = MyStuffViewController.init()
        myStuffViewController?.rootDelegate = self
        let myStuffNav = UINavigationController.init(rootViewController: myStuffViewController!)
//        myStuffNav.setNavigationBarHidden(true, animated: false)
        myStuffNav.navigationBar.prefersLargeTitles = true
        myStuffViewController?.refreshStuff()
        
        
        accountViewController = AccountViewController()
        let accountNav = UINavigationController.init(rootViewController: accountViewController!)
        accountNav.navigationBar.prefersLargeTitles = true
        accountViewController?.delegate = self

        
        
        self.viewControllers = [
            browseNav,
            personalNav,
            myStuffNav,
            accountNav
        ]
        
        if UserDefaults.standard.bool(forKey: "seller") == true {
            self.accountViewController?.showSellerStuff()
            self.postViewController = PostViewController()
            self.postViewController?.delegate = self
            self.viewControllers?.append(self.postViewController!)
        }
        super.viewDidLoad()
//        getFavorites()
//        getOffers()
        // Do any additional setup after loading the view.
    }
    

    
    

}
