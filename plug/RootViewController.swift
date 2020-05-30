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
        self.checkIfSeller(true)
        self.accountViewController!.organizeTable()
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
        postViewController?.delegate = self
        
        
        self.viewControllers = [
            browseNav,
            personalNav,
            myStuffNav,
            accountNav
        ]
        super.viewDidLoad()
        checkIfSeller(false)
//        getFavorites()
//        getOffers()
        // Do any additional setup after loading the view.
    }
    
    func checkIfSeller(_ force: Bool) {
        if force {
            UserDefaults.standard.removeObject(forKey: "seller")
        }
        if UserDefaults.contains("seller") {
            if UserDefaults.standard.bool(forKey: "seller") == true {
                postViewController = PostViewController()
                self.viewControllers?.append(postViewController!)
                self.accountViewController?.insertSellerSection()
                return
            }
        } else {
            if let uid = Auth.auth().currentUser?.uid {
                Firestore.firestore().collection("users").document(uid).getDocument { (snapshot, _) in
                    guard let result = snapshot?.data() else {
                        return
                    }
                    if let seller = result["seller"] as? Bool {
                        UserDefaults.standard.set(seller, forKey: "seller")
                        self.postViewController = PostViewController()
                        self.viewControllers?.append(self.postViewController!)
                        return
                    } else {
                        UserDefaults.standard.set(false, forKey: "seller")
                    }
                }
            }
        }
        
    }
    

    // MARK: SAVED STUFF
//    
//    var favoritesListener:ListenerRegistration?
//    var favorites:[Item]?
//    
//    func getFavorites() {
//        if let uid = Auth.auth().currentUser?.uid {
//            favoritesListener = Firestore.firestore().collection("users").document(uid).collection("favorites").addSnapshotListener { (snapshot, error) in
//                guard let results = snapshot?.documentChanges else {
//                    return
//                }
//                if self.favorites == nil {
//                    self.favorites = [Item]()
//                }
//                for doc in results {
//                    if doc.type == .added {
//                        print("new favorite!")
//                        if let query = doc.document["item"] as? [String] {
//                            Firestore.firestore().collection("items").whereField("tags", arrayContainsAny: query).getDocuments { (snapshot, error) in
//                                guard let results = snapshot?.documents else {
//                                    return
//                                }
//                                let temp = results.map { (fItem) -> Item in
//                                    return Item.init(fromQuery: fItem.data(), fItem.documentID)
//                                }
//                                self.favorites?.append(contentsOf: temp)
//                                self.myStuffViewController?.favoritesChanged(&self.favorites!)
//                            }
//                        }
//                    } else if doc.type == .removed {
//                        if let docIdentifiers = doc.document.data()["item"] as? [String] {
//                            for (index, favorite) in self.favorites!.enumerated() {
//                                if let id = favorite.id,
//                                    let name = favorite.name {
//                                    if docIdentifiers.contains(id) || docIdentifiers.contains(name) {
//                                        self.favorites!.remove(at: index)
//                                        self.myStuffViewController?.favoritesChanged(&self.favorites!)
//                                    }
//                                }
//                               
//                            }
//                        }
//                        
//                        
//                    }
//                }
//                
//            }
//        }
//    }
    
    
    

}
