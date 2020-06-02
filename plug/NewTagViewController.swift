//
//  NewTagViewController.swift
//  plug
//
//  Created by Robert Crosby on 5/30/20.
//  Copyright © 2020 Robert Crosby. All rights reserved.
//

import UIKit
import Firebase

class NewTagViewController: UITableViewController {
    
    var tag:Tag?
    var inputTag:String?
    
    init(_ tag: Tag?) {
        self.tag = tag
        self.inputTag = tag?.string
        super.init(style: .grouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        self.tableView.register(UINib(nibName: "GrowingCell", bundle: nil), forCellReuseIdentifier: "GrowingCell")

        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "tags"
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 {
            return "Type space separated words that you want to recieve updates for.\n\nFor example: \"12.5\" would let you recieve notifications whenever a size 12.5 shoe is posted. Similarly, \"Yeezy 12.5\" would notify you whenever a Yeezy shoe of size 12.5 is available."
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "GrowingCell", for: indexPath) as! GrowingCell
            cell.textView.font = .systemFont(ofSize: 24, weight: .bold)
            cell.textView.autocapitalizationType = .words
            cell.textView.autocorrectionType = .no
            cell.placeholder.font = cell.textView.font
            cell.textView.text = self.inputTag
            cell.placeholder.isHidden = !(cell.textView.text.isEmpty)
            cell.cellDelegate = self
            cell.selectionStyle = .none
            return cell
        } else {
            let cell = UITableViewCell.init(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = "Create Tag"
            cell.textLabel?.textColor = .systemRed
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            processTag()
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func processTag() {
        if  let text = inputTag?.lowercased(),
            let uid = Auth.auth().currentUser?.uid {
            let trimmed = text.trimmingCharacters(in: CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789").inverted)
            var filtered = trimmed.components(separatedBy: " ")
            if filtered.contains("shoe") {
                filtered.append("shoes")
            }
            if self.tag != nil {
                Firestore.firestore().collection("users").document(uid).collection("tags").document(self.tag!.id).updateData(["tags":filtered], completion: { (error) in
                    if let error = error {
                        print(error.localizedDescription)
                        return
                    }
                    self.dismiss(animated: true, completion: nil)
                })
            } else {
                Firestore.firestore().collection("users").document(uid).collection("tags").addDocument(data: ["tags":filtered]) { (error) in
                    if let error = error {
                        print(error.localizedDescription)
                        return
                    }
                    self.dismiss(animated: true, completion: nil)
                }
            }
            
        }
        
    }
}

extension NewTagViewController: GrowingCellProtocol {
    
    
    func updateHeightOfRow(_ cell: GrowingCell, _ textView: UITextView) {
        self.inputTag = textView.text
        let size = textView.bounds.size
        let newSize = tableView.sizeThatFits(CGSize(width: size.width,
                                                        height: CGFloat.greatestFiniteMagnitude))
        if size.height != newSize.height {
            UIView.setAnimationsEnabled(false)
            tableView?.beginUpdates()
            tableView?.endUpdates()
            UIView.setAnimationsEnabled(true)
            if let thisIndexPath = tableView.indexPath(for: cell) {
                tableView.scrollToRow(at: thisIndexPath, at: .bottom, animated: false)
            }
        }
    }
}

struct Tag {
    
    let id:String
    let tags:[String]
    
    init(qds: QueryDocumentSnapshot) {
        self.id = qds.documentID
        self.tags = qds.data()["tags"] as! [String]
    }
    
    func getItemsMatching(_ complete: @escaping ([QueryDocumentSnapshot]?) -> Void) {
        Firestore.firestore().collection("items").whereField("tags", arrayContainsAny: self.tags).getDocuments { (snapshot, error) in
            if let error = error {
                print(error.localizedDescription)
                complete(nil)
                return
            }
            complete(snapshot?.documents)
        }
    }
    
    var string: String {
        var ret = ""
        for tag in tags {
            ret = ret + " " + tag
        }
        return ret
    }
}
