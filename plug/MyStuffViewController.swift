//
//  MyStuffViewController.swift
//  plug
//
//  Created by Robert Crosby on 5/26/20.
//  Copyright © 2020 Robert Crosby. All rights reserved.
//

import UIKit
import Firebase

class MyStuffViewController: UITableViewController {
    
    weak var rootDelegate:RootDelegate?
//    var sections = SectionController()
//    var favorites:[Item]?
//
//    func favoritesChanged(_ favorites: inout [Item]) {
//        self.favorites = favorites
//
//        self.sections.updateSection(title: .MyStuffFavorites, rows: self.favorites?.count ?? 1)
//        self.sections.setHeaderTextForSection(.MyStuffFavorites, "Favorites")
//        self.updateTable()
//    }
    
    var offersListener:ListenerRegistration?
    var offers:[Offer]?
    
    func getOffers(_ completion: @escaping () -> Void) {
        if let uid = Auth.auth().currentUser?.uid {
            if offersListener != nil {
                offersListener = nil
                self.offers = nil
            }
            offersListener = Firestore.firestore().collection("offers").whereField("parties", arrayContains: uid).addSnapshotListener { (snapshot, error) in
                guard let data = snapshot?.documentChanges else {
                    self.offers = nil
                    completion()
                    return
                }
                if data.isEmpty {
                    self.offers = nil
                    completion()
                    return
                }
                if self.offers == nil {
                    self.offers = [Offer]()
                }
                for doc in data {
                    if doc.type == .added {
                        let offer = Offer.init(fromQuery: doc.document)
                        if !(offer.complete) {
                            self.offers?.insert(offer, at: 0)
                        } else {
                            self.offers?.append(offer)
                        }
                    } else if doc.type == .removed {
                        for (index, offer) in self.offers!.enumerated() {
                            if offer.id == doc.document.documentID {
                                self.offers?.remove(at: index)
                            }
                        }
                    }
                }
                completion()
                return
            }
        }
    }

    init() {
        super.init(style: .grouped)
        self.title = "Bag"
        self.tabBarItem = UITabBarItem.init(title: nil, image: UIImage.init(systemName: "bag"), selectedImage: UIImage.init(systemName: "bag.fill"))
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        self.tableView.separatorInset = UIEdgeInsets.init(top: 0, left: 15, bottom: 0, right: 15)
        self.tableView.register(UINib(nibName: "OfferCell", bundle: nil), forCellReuseIdentifier: "OfferCell")
//        self.tableView.contentInset.top+=35
        super.viewDidLoad()
        
        let refresh = UIRefreshControl.init()
        refresh.addTarget(self, action: #selector(refreshStuff), for: .valueChanged)
        self.tableView.refreshControl = refresh
        self.view.backgroundColor = .systemGroupedBackground
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    var checkBackView:UIView?
    
    @objc func refreshStuff() {
        getOffers {
            
            self.tableView.refreshControl?.endRefreshing()
            if let count = self.offers?.count {
//                self.sections.updateSection(title: .MyStuffOffers, rows: count)
//                self.sections.setHeaderTextForSection(.MyStuffOffers, "Offers")
                self.tableView.reloadData()
            }
                
        }
        
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 54
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let offer = self.offers?[section] {
            return offer.statusText
        }
        return nil
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return self.offers?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "OfferCell", for: indexPath) as! OfferCell
//                    cell.backgroundColor = .systemGroupedBackground
        //            cell.itemName?.font = buttonFont
                    if let offer = self.offers?[indexPath.section] {
                        cell.itemImageView.backgroundColor = .systemGroupedBackground
                        cell.itemImageView.layer.cornerRadius = 5
                        cell.itemImageView.layer.masksToBounds = true
        //                cell.offerStatus.text = offer.offerStatusString
                        fetchItemDetail(offer.item!) { (name, imageUrl) in
                            if let name = name {
                                cell.itemName.text = name
                                if cell.tag == 0 {
                                    cell.tag = 1
                                    self.tableView.reloadRows(at: [indexPath], with: .fade)
                                    
                                }
                                
                            }
                            if let imageUrl = imageUrl {
                                downloadImage(url: URL.init(string: imageUrl)!) { (image, error) in
                                    if let error = error {
                                        print(error)
                                    }
                                    print("image downloaded")
                                    
                                    if let image = image {
                                        DispatchQueue.main.async {
                                            cell.itemImageView.image = image
                                        }
                                        
                                    }
                                }
                            }
                        }
                    }
                    return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.present(OfferViewController.init(offer: &self.offers![indexPath.section]), animated: true, completion: nil)
        self.tableView.deselectRow(at: indexPath, animated: true)
    }

}
