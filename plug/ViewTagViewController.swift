//
//  ViewTagViewController.swift
//  plug
//
//  Created by Robert Crosby on 5/30/20.
//  Copyright © 2020 Robert Crosby. All rights reserved.
//

import UIKit
import Firebase

class ViewTagViewController: UITableViewController {

    let tag:Tag
    var items:[Item]?
    
    init(_ tag: Tag) {
        self.tag = tag
        super.init(style: .insetGrouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        self.tableView.separatorInset = .zero
        super.viewDidLoad()
        self.tag.getItemsMatching { (results) in
            if let results = results {
                self.items = results.map({ (qds) -> Item in
                    return Item.init(fromQuery: qds.data(), qds.documentID)
                })
                self.tableView.beginUpdates()
                self.tableView.reloadSections(IndexSet.init(integer: 1), with: .fade)
                self.tableView.endUpdates()
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            if let count = self.items?.count {
                if count > 0 {
                    return "\(count) item\(count > 1 ? "s" : "") found"
                }
            }
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if section == 0 {
            return 3
        }
        return self.items?.count ?? 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.init(style: .default, reuseIdentifier: nil)
        cell.textLabel?.font = buttonFont
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                cell.textLabel?.text = self.tag.string.uppercased()
                cell.textLabel?.numberOfLines = 0
            } else if indexPath.row == 1 {
                cell.textLabel?.text = "Edit Tag"
                cell.accessoryType = .disclosureIndicator
            } else if indexPath.row == 2 {
                cell.textLabel?.text = "Delete Tag"
                cell.textLabel?.textColor = .systemRed
            }
        } else {
            if let item = self.items?[indexPath.row] {
                cell.textLabel?.text = item.name ?? "Error"
                cell.accessoryType = .disclosureIndicator
            } else {
                cell.textLabel?.text = "No Items Currently"
            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            if indexPath.row == 1 {
                let newTagViewController = NewTagViewController.init(self.tag)
                self.present(newTagViewController, animated: true, completion: nil)
            } else if indexPath.row == 2 {
                deleteTag()
            }
        } else {
            if self.items != nil {
                let itemViewController = ItemViewController.init(item: &self.items![indexPath.row])
                let itemNav = UINavigationController.init(rootViewController: itemViewController)
                itemNav.navigationBar.prefersLargeTitles = false
                itemViewController.hidesBottomBarWhenPushed = true
                self.present(itemNav, animated: true, completion: nil)
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func deleteTag() {
        if let uid = Auth.auth().currentUser?.uid {
            Firestore.firestore().collection("users").document(uid).collection("tags").document(self.tag.id).delete { (error) in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                self.dismiss(animated: true, completion: nil)
            }
        }
        
    }
}
