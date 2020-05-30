//
//  AccountViewController.swift
//  plug
//
//  Created by Robert Crosby on 5/24/20.
//  Copyright © 2020 Robert Crosby. All rights reserved.
//

import UIKit
import Firebase

class AccountViewController: UITableViewController {

    var seller = false
    weak var delegate:RootDelegate?
    let sections = SectionController()
    
    
    var customerTransactions:[Transaction]?
    var salesTransactions:[Transaction]?
    
    init() {
        super.init(style: .insetGrouped)
        self.title = "Account"
        self.tabBarItem = UITabBarItem.init(title: nil, image: UIImage.init(systemName: "person"), selectedImage: UIImage.init(systemName: "person.fill"))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        organizeTable()
        super.viewDidLoad()
        
        
        self.tableView.refreshControl = UIRefreshControl.init()
        self.tableView.refreshControl!.addTarget(self, action: #selector(refreshTable), for: .valueChanged)
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    @objc func refreshTable() {
        self.tableView.refreshControl?.endRefreshing()
        if seller {
            self.getPastSales()
        } else {
            self.getCustomerTransactions()
        }
    }
    
    
    
    func organizeTable() {
        self.sections.sections.removeAll()
        if Auth.auth().currentUser == nil {
            self.sections.updateSection(title: .Authentication, rows: 4)
            self.navigationItem.leftBarButtonItem = nil
        } else {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem.init(title: "Sign Out", style: .plain, target: self, action: #selector(signOut))
            if seller {
                self.getPastSales()
            } else {
                self.getCustomerTransactions()
            }
        }
        self.tableView.reloadData()
    }
    
    func insertSellerSection() {
        seller = true
        self.getPastSales()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return self.sections.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.sections.titleForSectionAtIndex(section)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.sections.rowsInSectionAtIndex(section)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let identifier = self.sections.identiferForSectionAtIndex(indexPath.section)
        if identifier == .Authentication && indexPath.row < 2 {
            return 60
        }
        if identifier == .PublicProfile && indexPath.row == 0 {
            return 60
        }
        return UITableView.automaticDimension
    }
    
    var username:String?
    var email:String?
    var password:String?

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "cell")
        let identifier = self.sections.identiferForSectionAtIndex(indexPath.section)
        switch identifier {
        case .Authentication:
            if indexPath.row < 2 {
                let textfield = UITextField.init(frame: CGRect.init(x: 15, y: 15, width: self.view.frame.size.width-40, height: 30))
                textfield.autocapitalizationType = .none
                textfield.font = .systemFont(ofSize: 24, weight: .bold)
                if indexPath.row == 0 {
                    textfield.text = email
                    textfield.placeholder = "email address"
                    textfield.keyboardType = .emailAddress
                } else {
                    textfield.text = password
                    textfield.placeholder = "password"
                    textfield.isSecureTextEntry = true
                }
                textfield.delegate = self
                textfield.tag = indexPath.row
                cell.addSubview(textfield)
            } else if indexPath.row == 2 {
                cell.textLabel?.text = "SIGN IN"
                cell.textLabel?.font = .systemFont(ofSize: 16, weight: .bold)
                cell.textLabel?.textColor = .systemRed
            } else {
                cell.textLabel?.text = "SIGN UP"
                cell.textLabel?.font = .systemFont(ofSize: 16, weight: .bold)
                cell.textLabel?.textColor = .systemRed
            }
        case .AccountSellerSummary:
            if indexPath.row == 4 {
                cell.textLabel?.text = "See All Sales"
                cell.accessoryType = .disclosureIndicator
            } else {
                if let tx = self.salesTransactions?[indexPath.row] {
                    cell.textLabel?.text = "$\(tx.amount)"
                    cell.detailTextLabel?.text = RootViewController.dfm.string(from: tx.date!).replacingOccurrences(of: "_", with: " at ")
                }
            }
        case .AccountCustomerSummary:
            if self.customerTransactions == nil {
                cell.textLabel?.text = "Past purchases will appear here"
            } else {
                if let tx = self.customerTransactions?[indexPath.row] {
                    cell.textLabel?.text = "$\(tx.amount)"
                    cell.detailTextLabel?.text = RootViewController.dfm.string(from: tx.date!).replacingOccurrences(of: "_", with: " at ")
                }
            }
        case .Actions:
            cell.textLabel?.text = "Sign Out"
            cell.textLabel?.textColor = .systemRed
            cell.textLabel?.font = buttonFont
        default:
            break
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let identifier = self.sections.identiferForSectionAtIndex(indexPath.section)
        if identifier == .Authentication {
            if indexPath.row < 2 {
                if let subviews = tableView.cellForRow(at: indexPath)?.subviews {
                    for view in subviews {
                        if let tf = view as? UITextField {
                            tf.becomeFirstResponder()
                        }
                    }
                }
            } else if indexPath.row == 2 {
                signIn()
            } else {
                signUp()
            }
        } else if identifier == .AccountSellerSummary {
            if indexPath.row == 4 {
                
            } else {
                let transactionViewController = IndividualTransactionViewController.init(self.salesTransactions![indexPath.row])
                self.present(transactionViewController, animated: true, completion: nil)
            }
        }
        else if identifier == .Actions {
            signOut()
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func signIn() {
        print("email \(self.email ?? "error"), password \(self.password ?? "error")")
        if  let email = self.email,
            let password = self.password {
            Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
                if let error = error {
                    self.delegate?.showAlert(title: nil, message: error.localizedDescription)
                    return
                }
                self.delegate?.authenticationChanged()
            }
        }
    }
    
    func signUp() {
        if  let email = self.email,
            let password = self.password {
            Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
                if let error = error {
                    self.delegate?.showAlert(title: nil, message: error.localizedDescription)
                    return
                }
                self.delegate?.authenticationChanged()
            }
        }
    }
    
    @objc func signOut() {
        do {
            try Auth.auth().signOut()
            self.delegate?.authenticationChanged()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func updatePublicProfile() {
        if let uid = Auth.auth().currentUser?.uid,
            let username = self.username {
            let loading = UIAlertController.init(title: nil, message: "Updating...", preferredStyle: .alert)
            self.present(loading, animated: true) {
                Firestore.firestore().collection("users").document(uid).setData(["username":username], merge: true, completion: { (error) in
                    if let error = error {
                        loading.dismiss(animated: true) {
                            self.delegate?.showAlert(title: "Error", message: error.localizedDescription)
                        }
                        return
                    }
                    loading.dismiss(animated: true, completion: nil)
                    return
                })
            }
        }
        
    }
    
    func getPastSales() {
        if seller {
            Functions.functions().httpsCallable("ListAllCharges").call() { (result, error) in
                if let error = error as NSError? {
                    if error.domain == FunctionsErrorDomain {
                        let message = error.localizedDescription
                        print("ERROR: \(message)")
                        return
                    }
                }
                if let data = result?.data as? [String:Any] {
                    if let list = data["data"] as? [[String:Any]] {
                        self.salesTransactions = list.map({ (tx) -> Transaction in
                            return Transaction.init(data: tx)
                        })
                        if self.salesTransactions != nil {
                            var count = self.salesTransactions!.count
                            if count > 4 {
                                count = 5
                            }
                            self.sections.updateSection(title: .AccountSellerSummary, rows: count)
                            self.sections.setHeaderTextForSection(.AccountSellerSummary, "Sales")
                            self.tableView.reloadData()
//                            if let index = self.sections.indexForIdentifier(.AccountSellerSummary) {
//                                self.tableView.beginUpdates()
//                                self.tableView.reloadSections(IndexSet.init(integer: index), with: .fade)
//                                self.tableView.endUpdates()
//                            }
                        }
                        return
                    }
                    
                }
            }
        }
    }

    func getCustomerTransactions() {
        if Auth.auth().currentUser != nil {
            Functions.functions().httpsCallable("listCustomerCharges").call() { (result, error) in
                if let error = error as NSError? {
                    if error.domain == FunctionsErrorDomain {
                        let message = error.localizedDescription
                        print("ERROR: \(message)")
                        return
                    }
                }
                if let data = result?.data as? [String:Any] {
                    if let list = data["data"] as? [[String:Any]] {
                        self.customerTransactions = list.map({ (tx) -> Transaction in
                            return Transaction.init(data: tx)
                        })
                        if self.customerTransactions != nil {
                            if let count = self.customerTransactions?.count {
                                if count > 0 {
                                    self.sections.updateSection(title: .AccountCustomerSummary, rows: count)
                                    self.sections.setHeaderTextForSection(.AccountCustomerSummary, "Purchases")
                                    self.tableView.reloadData()
//                                    if let index = self.sections.indexForIdentifier(.AccountCustomerSummary) {
//                                        self.tableView.beginUpdates()
//                                        self.tableView.reloadSections(IndexSet.init(integer: index), with: .fade)
//                                        self.tableView.endUpdates()
//                                    }
                                }
                                
                            }
                            
                        }
                        return
                    }
                    
                }
            }
        }
    }
}

extension AccountViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let current = textField.text {
            let text = current + string
            switch textField.tag {
            case 0:
                self.email = text
            case 1:
                self.password = text
            case 3:
                self.username = text
            default:
                break
            }
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let text = textField.text {
            switch textField.tag {
            case 0:
                self.email = text
                if self.password?.isEmpty ?? true {
                    if let next = self.tableView.cellForRow(at: IndexPath.init(row: 1, section: 0)) {
                        for view in next.subviews {
                            if let tf = view as? UITextField {
                                tf.becomeFirstResponder()
                            }
                        }
                    }
                }
            case 1:
                self.password = text
            case 3:
                self.username = text
            default:
                break
            }
        }
        textField.resignFirstResponder()
        return true
    }
}
