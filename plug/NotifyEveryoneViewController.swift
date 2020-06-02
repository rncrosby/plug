//
//  NotifyEveryoneViewController.swift
//  plug
//
//  Created by Robert Crosby on 6/1/20.
//  Copyright © 2020 Robert Crosby. All rights reserved.
//

import UIKit
import Firebase

class NotifyEveryoneViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UINib(nibName: "GrowingCell", bundle: nil), forCellReuseIdentifier: "GrowingCell")
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
        if section == 0 {
            return 2
        }
        return 1
    }
    
    var notificationTitle:String?
    var notificationMessage:String?

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "GrowingCell", for: indexPath) as! GrowingCell
            if indexPath.row == 0 {
                cell.textView.text = notificationTitle
                cell.placeholder.text = "Title"
                cell.textView.autocapitalizationType = .words
                cell.textView.autocorrectionType = .no
                cell.textView.font = titleFont
            } else {
                cell.textView.text = notificationMessage
                cell.placeholder.text = "Message"
                cell.textView.font = buttonFont
            }
            cell.placeholder.font = cell.textView.font
            cell.textView.tag = indexPath.row
            cell.placeholder.isHidden = !(cell.textView.text.isEmpty)
            cell.cellDelegate = self
            cell.selectionStyle = .none
            return cell
        } else {
            let cell = UITableViewCell.init(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = "Send Notification"
            cell.textLabel?.textColor = .systemRed
            cell.imageView?.image = UIImage.init(systemName: "paperplane.fill")
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            if let t = notificationTitle, let m = notificationMessage {
                Firestore.firestore().collection("notifications").addDocument(data: [
                    "title"     : t,
                    "message"   : m,
                    "date"      : FieldValue.serverTimestamp()
                ]) { (error) in
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

extension NotifyEveryoneViewController: GrowingCellProtocol {
    
    func updateHeightOfRow(_ cell: GrowingCell, _ textView: UITextView) {
        if textView.tag == 0 {
            self.notificationTitle = textView.text
        } else {
            self.notificationMessage = textView.text
        }
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
