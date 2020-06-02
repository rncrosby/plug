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
    
    var waitingForVerificationCode = true
    
    override func viewDidLoad() {
        if Auth.auth().currentUser == nil {
            self.sections.updateSection(title: .AuthPhone, rows: 1)
            self.sections.setHeaderTextForSection(.AuthPhone, "Phone number")
            self.sections.updateSection(title: .AuthContinue, rows: 1)
        } else {
            self.sections.updateSection(title: .AccountProfile, rows: 2)
            self.sections.setHeaderTextForSection(.AccountProfile, "Profile details")
            self.getCustomerTransactions()
        }
        
        super.viewDidLoad()
        
        
        self.tableView.refreshControl = UIRefreshControl.init()
        self.tableView.refreshControl!.addTarget(self, action: #selector(refreshTable), for: .valueChanged)
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    @objc func refreshTable() {
        if let uid = Auth.auth().currentUser?.uid {
            Firestore.firestore().collection("users").document(uid).getDocument { (snapshot, error) in
                guard let data = snapshot?.data() else {
                    return
                }
                if let tseller = data["seller"] as? Bool {
                    if tseller {
                        UserDefaults.standard.set(true, forKey: "seller")
                        self.seller = true
                        self.delegate?.showSeller()
                        self.showSellerStuff()
                    }
                } else {
                    UserDefaults.standard.set(false, forKey: "seller")
                    self.delegate?.hideSeller()
                }
                self.getCustomerTransactions()
            }
        }
        self.tableView.refreshControl?.endRefreshing()
    }
    
    func showSellerStuff() {
        let (insert, index) = self.sections.updateSection(title: .AuthNotifyEveryone, rows: 1)
        self.sections.setHeaderTextForSection(.AuthNotifyEveryone, "Seller Tools")
        self.tableView.beginUpdates()
        if insert {
            self.tableView.insertSections(IndexSet.init(integer: index), with: .fade)
        } else {
            self.tableView.reloadSections(IndexSet.init(integer: index), with: .fade)
        }
        
        self.tableView.endUpdates()
    }
    
    func organizeTable() {
        
        self.tableView.reloadData()
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
        if identifier == .AuthPhone || identifier == .AuthCode {
            return 60
        }
        
        return UITableView.automaticDimension
    }
    
    var activeTextField:UITextField?
    var phone:String?
    var code:String?

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "cell")
        let identifier = self.sections.identiferForSectionAtIndex(indexPath.section)
        switch identifier {
        case .AuthPhone:
            let textfield = UITextField.init(frame: CGRect.init(x: 15, y: 10, width: self.view.frame.size.width-70, height: 40))
            textfield.autocapitalizationType = .none
            textfield.font = buttonFont
            textfield.text = phone == nil ? formattedNumber(number: "1") : phone
            textfield.keyboardType = .phonePad
            let dismiss = UIButton.init(frame: CGRect.init(x: 0, y: 10, width: 30, height: 30))
            dismiss.setImage(UIImage.init(systemName: "keyboard.chevron.compact.down"), for: .normal)
            dismiss.tintColor = .secondaryLabel
            dismiss.addTarget(self, action: #selector(dismissTextField), for: .touchUpInside)
            textfield.rightView = dismiss
            textfield.rightViewMode = .whileEditing
            textfield.delegate = self
            textfield.tag = indexPath.section
            cell.addSubview(textfield)
        case .AuthCode:
            let textfield = UITextField.init(frame: CGRect.init(x: 15, y: 10, width: self.view.frame.size.width-70, height: 40))
            textfield.autocapitalizationType = .none
            textfield.font = buttonFont
            textfield.text = code
            textfield.addTarget(self, action: #selector(codeFieldDidChange(sender:)), for: .editingChanged)
            textfield.keyboardType = .phonePad
            let dismiss = UIButton.init(frame: CGRect.init(x: 0, y: 10, width: 30, height: 30))
            dismiss.setImage(UIImage.init(systemName: "keyboard.chevron.compact.down"), for: .normal)
            dismiss.tintColor = .secondaryLabel
            dismiss.addTarget(self, action: #selector(dismissTextField), for: .touchUpInside)
            textfield.rightView = dismiss
            textfield.rightViewMode = .whileEditing
            textfield.delegate = self
            textfield.tag = indexPath.section
            cell.addSubview(textfield)
        case .AuthContinue:
            cell.textLabel?.text = "Continue"
            cell.textLabel?.font = buttonFont
        case .AccountSellerSummary:
            if let tx = self.salesTransactions?[indexPath.row] {
                cell.textLabel?.text = "$\(tx.amount)"
                cell.detailTextLabel?.text = RootViewController.dfm.string(from: tx.date!).replacingOccurrences(of: "_", with: " at ")
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
        case .AccountProfile:
            cell.textLabel?.font = buttonFont
            if indexPath.row == 0 {
                if let uid = Auth.auth().currentUser?.uid {
                    cell.textLabel?.text = uid
                }
            } else {
                cell.textLabel?.text = "Sign Out"
                cell.textLabel?.textColor = .systemRed
            }
        case .AuthNotifyEveryone:
            cell.textLabel?.text = "Send Notification To All"
            cell.textLabel?.textColor = .systemRed
            cell.textLabel?.font = buttonFont
            cell.imageView?.image = UIImage.init(systemName: "paperplane.fill")
        default:
            break
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let identifier = self.sections.identiferForSectionAtIndex(indexPath.section)
        if identifier == .AuthContinue {
            if verificationID == nil {
                self.sendVerificationCode()
            } else {
                authentifyUser()
            }
        }
        else if identifier == .AccountSellerSummary {
            let transactionViewController = IndividualTransactionViewController.init(self.salesTransactions![indexPath.row])
            self.present(transactionViewController, animated: true, completion: nil)
        }
        else if identifier == .AccountProfile {
            if indexPath.row == self.tableView.numberOfRows(inSection: indexPath.section)-1 {
                signOut()
            }
        } else if identifier == .AuthNotifyEveryone {
            let notifyEveryone = NotifyEveryoneViewController.init(style: .insetGrouped)
            self.present(notifyEveryone, animated: true, completion: nil)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func authentifyUser() {
        if let vID = verificationID, let vCode = self.code {
            let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: vID,
            verificationCode: vCode)
            Auth.auth().signIn(with: credential) { (result, error) in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                self.delegate?.authenticationChanged()
                self.sections.removeSection(title: .AuthPhone)
                self.sections.removeSection(title: .AuthCode)
                self.sections.removeSection(title: .AuthContinue)
                self.sections.updateSection(title: .AccountProfile, rows: 2)
                self.sections.setHeaderTextForSection(.AccountProfile, "Profile details")
                self.tableView.beginUpdates()
                self.tableView.deleteSections(IndexSet.init(integersIn: 0...2), with: .fade)
                self.tableView.insertSections(IndexSet.init(integer: 0), with: .fade)
                self.tableView.endUpdates()
                self.getCustomerTransactions()
                self.getPastSales()
                
            }
        }
        
    }
    
    var verificationID:String?
    
    func sendVerificationCode() {
        if let phoneNumber = phone {
            PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { (verificationID, error) in
              if let error = error {
                print(error.localizedDescription)
                return
              }
                UserDefaults.standard.set(verificationID, forKey: "verificationCode")
                self.verificationID = verificationID
                let (insert, _) = self.sections.updateSection(title: .AuthCode, rows: 1)
                self.sections.setHeaderTextForSection(.AuthCode, "Verification code")
                self.sections.orderSections([.AuthPhone,.AuthCode,.AuthContinue])
                if insert {
                    self.tableView.beginUpdates()
                    self.tableView.insertSections(IndexSet.init(integer: 1), with: .fade)
                    self.tableView.endUpdates()
                } else {
                     self.tableView.reloadData()
                }
            }
        }
        
    }
    
    @objc func signOut() {
        do {
            try Auth.auth().signOut()
            self.delegate?.authenticationChanged()
            self.sections.sections.removeAll()
            self.sections.updateSection(title: .AuthPhone, rows: 1)
            self.sections.setHeaderTextForSection(.AuthPhone, "Phone number")
            self.sections.updateSection(title: .AuthContinue, rows: 1)
            
            self.tableView.beginUpdates()
            self.tableView.deleteSections(IndexSet.init(integersIn: 0...self.tableView.numberOfSections-1), with: .fade)
            self.tableView.insertSections(IndexSet.init(integersIn: 0...1), with: .fade)
            self.tableView.endUpdates()
        } catch {
            print(error.localizedDescription)
        }
    }
    

    
    func getPastSales() {
        if UserDefaults.standard.bool(forKey: "seller") == true {
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
                            let (insert, index) = self.sections.updateSection(title: .AccountSellerSummary, rows: count)
                            self.sections.setHeaderTextForSection(.AccountSellerSummary, "Recent Card Sales")
                            self.tableView.beginUpdates()
                            if insert {
                                self.tableView.insertSections(IndexSet.init(integer: index), with: .fade)
                            } else {
                                self.tableView.reloadSections(IndexSet.init(integer: index), with: .fade)
                            }
                            self.tableView.endUpdates()
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
                                    let (insert, index) = self.sections.updateSection(title: .AccountCustomerSummary, rows: count)
                                    self.sections.setHeaderTextForSection(.AccountCustomerSummary, "Card Purchases")
                                    self.tableView.beginUpdates()
                                    if insert {
                                        self.tableView.insertSections(IndexSet.init(integer: index), with: .fade)
                                    } else {
                                        self.tableView.reloadSections(IndexSet.init(integer: index), with: .fade)
                                    }
                                    self.tableView.endUpdates()
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
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeTextField = textField
    }
    
    @objc func dismissTextField() {
        activeTextField?.resignFirstResponder()
    }
    
    func formattedNumber(number: String) -> String {
        let cleanPhoneNumber = number.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        let mask = "+X XXX XXX-XXXX"

        var result = ""
        var index = cleanPhoneNumber.startIndex
        for ch in mask where index < cleanPhoneNumber.endIndex {
            if ch == "X" {
                result.append(cleanPhoneNumber[index])
                index = cleanPhoneNumber.index(after: index)
            } else {
                result.append(ch)
            }
        }
        return result
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField.tag == 0 {
            guard let text = textField.text else { return false }
            let newString = (text as NSString).replacingCharacters(in: range, with: string)
            textField.text = formattedNumber(number: newString)
            phone = textField.text!
            return false
        } else {
            if let text = textField.text {
                if text.count == 6 {
                    return false
                }
            }
        }
        return true
    }
    
    @objc func codeFieldDidChange(sender: UITextField) {
        if let text = sender.text {
            if text.count == 6 {
                self.code = text
            }
        }
    }
    
//    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
//        if let current = textField.text {
//            let text = current + string
//            switch textField.tag {
//            case 0:
//                self.email = text
//            case 1:
//                self.password = text
//            case 3:
//                self.username = text
//            default:
//                break
//            }
//        }
//        return true
//    }
    
//    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//        if let text = textField.text {
//            switch textField.tag {
//            case 0:
//                self.email = text
//                if self.password?.isEmpty ?? true {
//                    if let next = self.tableView.cellForRow(at: IndexPath.init(row: 1, section: 0)) {
//                        for view in next.subviews {
//                            if let tf = view as? UITextField {
//                                tf.becomeFirstResponder()
//                            }
//                        }
//                    }
//                }
//            case 1:
//                self.password = text
//            case 3:
//                self.username = text
//            default:
//                break
//            }
//        }
//        textField.resignFirstResponder()
//        return true
//    }
}
