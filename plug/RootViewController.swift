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

@objc protocol RootDelegate: class {
    @objc func authenticationChanged()
    @objc func showAlert(title: String?, message: String)
}

extension RootViewController: RootDelegate {
    @objc func authenticationChanged() {
        self.accountViewController!.organizeTable()
    }
    
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
    
    var browseViewController:BrowseViewController?
    
    var postViewController:PostViewController?
    
    var accountViewController:AccountViewController?
    
    var myStuffViewController:MyStuffViewController?
    
    init() {
        
        super.init(nibName: nil, bundle: nil)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        let width = (self.view.frame.size.width-30-15)/2
        browseViewController = BrowseViewController.init(itemSize: CGSize.init(width: width, height: width+60))
        let browseNav = UINavigationController.init(rootViewController: browseViewController!)
        browseNav.navigationBar.prefersLargeTitles = true
        
        myStuffViewController = MyStuffViewController.init()
        let myStuffNav = UINavigationController.init(rootViewController: myStuffViewController!)
//        myStuffNav.setNavigationBarHidden(true, animated: false)
        myStuffNav.navigationBar.prefersLargeTitles = true
        
        
        postViewController = PostViewController()
        accountViewController = AccountViewController()
        accountViewController?.delegate = self
        postViewController?.delegate = self
        
        
        self.viewControllers = [
            browseNav,
            myStuffNav,
            postViewController!,
            accountViewController!
        ]
        super.viewDidLoad()
        getFavorites()
        getOffers()
        // Do any additional setup after loading the view.
    }
    

    // MARK: SAVED STUFF
    
    var favorites:[Item]?
    
    func getFavorites() {
        if let uid = Auth.auth().currentUser?.uid {
            Firestore.firestore().collection("users").document(uid).collection("favorites").getDocuments { (snapshot, error) in
                guard let data = snapshot?.documents else {
                    return
                }
                self.favorites = [Item]()
                for favorite in data {
                    if let query = favorite.data()["item"] as? [String] {
                        Firestore.firestore().collection("items").whereField("tags", arrayContainsAny: query).getDocuments { (snapshot, error) in
                            guard let results = snapshot?.documents else {
                                return
                            }
                            let temp = results.map { (fItem) -> Item in
                                return Item.init(fromQuery: fItem.data(), fItem.documentID)
                            }
                            self.favorites?.append(contentsOf: temp)
                            self.myStuffViewController?.favoritesChanged(&self.favorites!)
                        }
                    }
                }
                return
            }
        }
    }
    
    var offers:[Offer]?
    
    func getOffers() {
        if let uid = Auth.auth().currentUser?.uid {
            Firestore.firestore().collection("offers").whereField("customer", isEqualTo: uid).getDocuments { (snapshot, error) in
                guard let data = snapshot?.documents else {
                    return
                }
                self.offers = data.map({ (doc) -> Offer in
                    return Offer.init(fromQuery: doc)
                })
                self.myStuffViewController?.offersChanged(&self.offers!)
                return
            }
        }
    }

}
