//
//  TransactionsViewController.swift
//  plug
//
//  Created by Robert Crosby on 5/29/20.
//  Copyright © 2020 Robert Crosby. All rights reserved.
//

import UIKit
import WebKit

class ListTransactionsViewController: UITableViewController {
    
    init() {
        super.init(style: .grouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }

}

class IndividualTransactionViewController: UIViewController {
    
    var transaction:Transaction
    
    init(_ transaction: Transaction) {
        self.transaction = transaction
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let web = WKWebView.init(frame: self.view.bounds)
        web.load(URLRequest.init(url: transaction.receipt!))
        self.view.addSubview(web)
    }

    // MARK: - Table view data source

//    override func numberOfSections(in tableView: UITableView) -> Int {
//        // #warning Incomplete implementation, return the number of sections
//        return 0
//    }
//
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        // #warning Incomplete implementation, return the number of rows
//        return 0
//    }
}

struct Transaction {
    var status:String?
    var amount:Int
    var date:Date?
    var customer:String?
    var id:String?
    var item:String?
    var offer:String?
    var receipt:URL?
    var paid:Bool?
    var refunded:Bool?
    
    init(data: [String:Any]) {
        self.status = data["status"] as? String
        self.amount = (data["amount"] as? Int ?? 0) / 100
        if let created = data["created"] as? Int {
            self.date = Date.init(timeIntervalSince1970: Double(created))
        }
        self.customer = data["customer"] as? String
        self.id = data["id"] as? String
        if let metadata = data["metadata"] as? [String:String] {
            self.item = metadata["item"]
            self.offer = metadata["offer"]
        }
        if let charges = data["charges"] as? [String:Any] {
            if let charge = (charges["data"] as? [[String:Any]])?.first {
                if let receipt_url = charge["receipt_url"] as? String {
                    self.receipt = URL.init(string: receipt_url)
                }
                self.refunded = charge["refunded"] as? Bool
                self.paid = charge["paid"] as? Bool
            }
        }
    }
}
