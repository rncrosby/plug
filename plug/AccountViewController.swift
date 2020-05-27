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

    weak var delegate:RootDelegate?
    let sections = SectionController()
    
    init() {
        super.init(style: .grouped)
        self.title = "Account"
        self.tabBarItem = UITabBarItem.init(title: nil, image: UIImage.init(systemName: "person"), selectedImage: UIImage.init(systemName: "person.fill"))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        organizeTable()
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    func organizeTable() {
        self.sections.sections.removeAll()
        if Auth.auth().currentUser == nil {
            self.sections.updateSection(title: .Authentication, rows: 4)
        } else {
            self.sections.updateSection(title: .PublicProfile, rows: 2)
            self.sections.updateSection(title: .Actions, rows: 1)
        }
        self.tableView.reloadData()
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
        let cell = UITableViewCell.init(style: .default, reuseIdentifier: "cell")
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
        case .PublicProfile:
            if indexPath.row == 0 {
                let textfield = UITextField.init(frame: CGRect.init(x: 15, y: 15, width: self.view.frame.size.width-40, height: 30))
                textfield.autocapitalizationType = .none
                textfield.font = .systemFont(ofSize: 24, weight: .bold)
                textfield.placeholder = "Display Name"
                textfield.tag = 3
                if let uid = Auth.auth().currentUser?.uid {
                    getProfileForUID(uid) { (profile) in
                        if let name = profile?.username {
                            textfield.text = name
                        }
                    }
                }
                textfield.delegate = self
                cell.addSubview(textfield)
            } else {
                cell.textLabel?.text = "Save Changes"
                cell.textLabel?.textColor = .systemRed
                cell.textLabel?.font = buttonFont
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
        } else if identifier == .PublicProfile {
            if indexPath.row == tableView.numberOfRows(inSection: indexPath.section)-1 {
                updatePublicProfile()
            }
        } else if identifier == .Actions {
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
    
    func signOut() {
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
