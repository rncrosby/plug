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
        self.listenToTags()
        self.sections.updateSection(title: .Notifications, rows: 1)
        self.sections.setHeaderTextForSection(.Notifications, "Notifications")
        self.sections.updateSection(title: .ForYouTags, rows: 1)
        self.sections.setHeaderTextForSection(.ForYouTags, "Tags")
        
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
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if self.sections.identiferForSectionAtIndex(section) == .ForYouTags {
            return "These are products, categories, sizes, brands, that you will recieve notifications whenever new items become available."
        }
        return nil
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
        case .Notifications:
            cell = UITableViewCell.init(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = "PUSH NOTIFICATIONS"
            cell.textLabel?.font = buttonFont
            let control = UISwitch.init()
            control.onTintColor = .systemRed
            control.addTarget(self, action: #selector(togglePushNotifications(sender:)), for: .valueChanged)
            if UIApplication.shared.isRegisteredForRemoteNotifications {
                control.setOn(true, animated: false)
            }
            cell.accessoryView = control
            return cell
        case .ForYouFavorites:
            cell = UITableViewCell.init(style: .subtitle, reuseIdentifier: nil)
            if let item = self.favorites?[indexPath.row] {
                cell.textLabel?.text = item.name ?? "Unknown name"
            }
            cell.textLabel?.text = cell.textLabel?.text?.uppercased()
            cell.textLabel?.font = buttonFont
            cell.textLabel?.numberOfLines = 0
            
        case .ForYouTags:
            cell = UITableViewCell.init(style: .subtitle, reuseIdentifier: nil)
            cell.textLabel?.font = buttonFont
            cell.detailTextLabel?.font = subtitleFont
            if indexPath.row == tableView.numberOfRows(inSection: indexPath.section)-1 {
                cell.textLabel?.textColor = .systemRed
                cell.textLabel?.text = "New Tag".uppercased()
                cell.detailTextLabel?.text = "Size 12, Yeezy, Shirt, etc".uppercased()
            } else if let tag = self.tags?[indexPath.row] {
                cell.textLabel?.text = tag.string.uppercased()
            }
            return cell
        default:
            cell = UITableViewCell()
        }
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    @objc func togglePushNotifications(sender: UISwitch) {
        if sender.isOn {
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options:[.badge, .alert, .sound]) { (granted, error) in
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    InstanceID.instanceID().instanceID { (result, error) in
                      if let error = error {
                        print("Error fetching remote instance ID: \(error)")
                      } else if let result = result {
                        print("Remote instance ID token: \(result.token)")
                        updateNotificationToken(Auth.auth().currentUser!.uid, result.token) { (result) in
                            if result {
                                Messaging.messaging().subscribe(toTopic: "allUsers") { error in
                                  print("Subscribed to all users!")
                                }
                                return
                            }
                            print("Error")
                            return
                        }
                      }
                    }

                }
            }
            UIApplication.shared.registerForRemoteNotifications()
        } else {
            UIApplication.shared.unregisterForRemoteNotifications()
            clearToken(Auth.auth().currentUser!.uid) { (result) in
                if result {
                    print("disabled")
                }
            }
        }

    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch self.sections.identiferForSectionAtIndex(indexPath.section) {
        case .ForYouFavorites:
            let itemViewController = ItemViewController.init(item: &self.favorites![indexPath.row])
            itemViewController.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(itemViewController, animated: true)
        case .ForYouTags:
            if indexPath.row == tableView.numberOfRows(inSection: indexPath.section)-1 {
                let newTagViewController = NewTagViewController.init(nil)
                self.present(newTagViewController, animated: true, completion: nil)
            } else {
                let tagViewController = ViewTagViewController.init(self.tags![indexPath.row])
                self.present(tagViewController, animated: true, completion: nil)
            }
            
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
    
    var tagsListener:ListenerRegistration?
    var tags:[Tag]?
    
    func listenToTags() {
        
        if tagsListener == nil {
            if let uid = Auth.auth().currentUser?.uid {
                tagsListener = Firestore.firestore().collection("users").document(uid).collection("tags").addSnapshotListener({ (snapshot, error) in
                    if let error = error {
                        return
                    }
                    if let results = snapshot?.documentChanges {
                        if results.isEmpty {
                            let (insert, index) = self.sections.updateSection(title: .ForYouTags, rows: 1)
                            self.tableView.beginUpdates()
                            self.tableView.reloadSections(IndexSet.init(integer: index), with: .fade)
                            self.tableView.endUpdates()
                        } else {
                            if self.tags == nil {
                                self.tags = [Tag]()
                            }
                            for result in results {
                                if result.type == .added {
                                    self.tags!.append(Tag.init(qds: result.document))
                                } else {
                                    for (index, element) in self.tags!.enumerated() {
                                        if element.id == result.document.documentID {
                                            self.tags?.remove(at: index)
                                            break
                                        }
                                    }
                                }
                            }
                            let count = self.tags?.count ?? 0
                            let (insert, index) = self.sections.updateSection(title: .ForYouTags, rows: count+1)
                            self.tableView.beginUpdates()
                            if insert {
                                self.tableView.insertSections(IndexSet.init(integer: index), with: .fade)
                            } else {
                                self.tableView.reloadSections(IndexSet.init(integer: index), with: .fade)
                            }
                            self.tableView.endUpdates()
                        }
                    }
                    
                })
            }
        }
    }
}


