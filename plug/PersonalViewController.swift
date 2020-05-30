//
//  PersonalViewController.swift
//  plug
//
//  Created by Robert Crosby on 5/29/20.
//  Copyright © 2020 Robert Crosby. All rights reserved.
//

import UIKit
import Firebase

class PersonalViewController: UITableViewController {
    
    var sections = SectionController()
    
    init() {
        super.init(style: .insetGrouped)
        self.title = "For You"
        self.tabBarItem = UITabBarItem.init(title: nil, image: UIImage.init(systemName: "eye"), selectedImage: UIImage.init(systemName: "eye.fill"))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.listenToFavorites()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return self.sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.sections.rowsInSectionAtIndex(section)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.sections.titleForSectionAtIndex(section)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        let identifier = self.sections.identiferForSectionAtIndex(indexPath.section)
//        if identifier == .ForYouSearch {
//            return 44+15+15
//        }
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell:UITableViewCell
        let identifier = self.sections.identiferForSectionAtIndex(indexPath.section)
        switch identifier {
        case .ForYouFavorites:
            cell = UITableViewCell.init(style: .subtitle, reuseIdentifier: nil)
            if let item = self.favorites?[indexPath.row] {
                cell.textLabel?.text = item.name ?? "Unknown name"
            }
            cell.textLabel?.numberOfLines = 0
            cell.accessoryType = .disclosureIndicator
        default:
            cell = UITableViewCell()
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch self.sections.identiferForSectionAtIndex(indexPath.section) {
        case .ForYouFavorites:
            let itemViewController = ItemViewController.init(item: &self.favorites![indexPath.row])
            itemViewController.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(itemViewController, animated: true)
        default:
            break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    var favoritesListener:ListenerRegistration?
    var favorites:[Item]?
    
    func listenToFavorites() {
        if let uid = Auth.auth().currentUser?.uid {
            if favoritesListener == nil {
                favoritesListener = Firestore.firestore().collection("users").document(uid).collection("favorites").addSnapshotListener({ (snapshot, error) in
                    if let error = error {
                        print(error.localizedDescription)
                        return
                    }
                    if let results = snapshot?.documentChanges {
                        if self.favorites == nil {
                            self.favorites = [Item]()
                        }
                        for document in results {
                            if document.type == .added {
                                if let query = document.document["item"] as? [String] {
                                    Firestore.firestore().collection("items").whereField("tags", arrayContainsAny: query).getDocuments { (snapshot, error) in
                                        guard let results = snapshot?.documents else {
                                            return
                                        }
                                        let temp = results.map { (fItem) -> Item in
                                            return Item.init(fromQuery: fItem.data(), fItem.documentID)
                                        }
                                        self.favorites?.append(contentsOf: temp)
                                        let (insert, index) = self.sections.updateSection(title: .ForYouFavorites, rows: self.favorites!.count)
                                        
                                        print(self.sections.sections)
                                        self.tableView.beginUpdates()
                                        if insert {
                                            self.sections.setHeaderTextForSection(.ForYouFavorites, "favorites")
                                            self.tableView.insertSections(IndexSet.init(integer: index), with: .fade)
                                        } else {
                                            self.tableView.reloadSections(IndexSet.init(integer: index), with: .fade)
                                        }
                                        
                                        self.tableView.endUpdates()
                                    }
                                }
                            } else {
                                if let docIdentifiers = document.document.data()["item"] as? [String] {
                                    for (index, favorite) in self.favorites!.enumerated() {
                                        if let id = favorite.id,
                                            let name = favorite.name {
                                            if docIdentifiers.contains(id) || docIdentifiers.contains(name) {
                                                self.favorites!.remove(at: index)
                                                
                                                self.tableView.beginUpdates()
                                                if let count = self.favorites?.count {
                                                    if count == 0 {
                                                        if let index = self.sections.removeSection(title: .ForYouFavorites) {
                                                            self.favorites = nil
                                                            self.tableView.deleteSections(IndexSet.init(integer: index), with: .fade)
                                                            self.tableView.endUpdates()
                                                        }
                                                    } else {
                                                        let (_, index) = self.sections.updateSection(title: .ForYouFavorites, rows: count)
                                                        self.tableView.reloadSections(IndexSet.init(integer: index), with: .fade)
                                                    }
                                                }
                                                self.tableView.endUpdates()
                                                break
                                            }
                                        }
                                    }
                                    
                                }
                            }
                        }
                    }
                })
            }
        }
        
    }
}
