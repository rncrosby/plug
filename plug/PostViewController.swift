//
//  PostViewController.swift
//  plug
//
//  Created by Robert Crosby on 5/23/20.
//  Copyright © 2020 Robert Crosby. All rights reserved.
//

import UIKit

class PostViewController: UITableViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    var sizes = [String]()

    
    let sections = SectionController()
    var item = Item()
    
    init() {
        super.init(style: .grouped)
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.title = "Post"
        self.tabBarItem = UITabBarItem.init(title: "Post", image: UIImage.init(systemName: "dollarsign.circle"), tag: 0)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        
        self.sections.updateSection(title: .ItemImages, rows: 3)
        self.sections.updateSection(title: .ItemNaming, rows: 2)
        self.sections.updateSection(title: .ItemClassification, rows: Item.Kind.allCases.count)
        self.sections.updateSection(title: .ItemSizing, rows: 1)
        self.sections.updateSection(title: .ItemPricing, rows: 2)
        self.sections.updateSection(title: .Actions, rows: 1)
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
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
        if (identifier == .ItemNaming) || (identifier == .ItemSizing) || (identifier == .ItemPricing && indexPath.row == 0) {
            return 60
        } else if identifier == .ItemImages && indexPath.row == 0 {
            return 130
        }
        return UITableView.automaticDimension
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let identifier = self.sections.identiferForSectionAtIndex(indexPath.section)
        let cell = UITableViewCell.init(style: .default, reuseIdentifier: identifier.rawValue)
        switch identifier {
        case .ItemNaming:
            let textfield = UITextField.init(frame: CGRect.init(x: 15, y: 5, width: self.view.frame.size.width-30, height: 50))
            textfield.delegate = self
            switch indexPath.row {
            case 0:
                textfield.placeholder = "Brand"
                textfield.tag = 0
            case 1:
                textfield.placeholder = "Name"
                textfield.tag = 1
            default:
                break
            }
            cell.addSubview(textfield)
            cell.selectionStyle = .none
        case .ItemClassification:
            let indexKind = Item.Kind.allCases[indexPath.row]
            cell.textLabel?.text = indexKind.rawValue.capitalizingFirstLetter()
            if self.item.kind == indexKind {
                cell.imageView?.image = UIImage.init(systemName: "square.fill")
            } else {
                cell.imageView?.image = UIImage.init(systemName: "square")
            }
        case .ItemSizing:
            let textfield = UITextField.init(frame: CGRect.init(x: 0, y: 0, width: 200, height: 50))
            self.sizes.removeAll()
            if self.item.kind == .Shoes {
                textfield.placeholder = "10"
                var size = Float(5)
                while size < Float(20) {
                    self.sizes.append(size.clean)
                    size+=0.5
                }
            } else {
                textfield.placeholder = "Medium"
                sizes = ["Small","Medium","Large","X-Large","XX-Large"]
            }
            setInputSizePicker(textfield: textfield)
            textfield.text = self.item.size
            textfield.textAlignment = .right
            textfield.delegate = self
            textfield.tag = 2
            cell.accessoryView = textfield
            cell.textLabel?.text = "Size"
        case .ItemPricing:
            if indexPath.row == 0 {
                let textfield = UITextField.init(frame: CGRect.init(x: 0, y: 0, width: 100, height: 50))
                textfield.placeholder = "$90"
                textfield.textAlignment = .right
                textfield.delegate = self
                textfield.tag = 3
                cell.accessoryView = textfield
                cell.textLabel?.text = "Asking Price"
                cell.selectionStyle = .none
            } else if indexPath.row == 1 {
                let toggle = UISwitch.init()
                toggle.setOn(self.item.instant, animated: false)
                toggle.addTarget(self, action: #selector(toggleInstant(sender:)), for: .valueChanged)
                cell.accessoryView = toggle
                cell.textLabel?.text = "Accept First Offer"
            }
        case .ItemImages:
            switch indexPath.row {
            case 0:
                let collection = self.item.getImageCollection(frame: CGRect.init(origin: .zero, size: CGSize.init(width: self.view.frame.size.width, height: 130)))
                cell.addSubview(collection)
            case 1:
                cell.textLabel?.text = "Take Picture"
                cell.imageView?.image = UIImage.init(systemName: "camera")
                cell.textLabel?.textColor = UIApplication.shared.windows.first!.tintColor
            case 2:
                cell.textLabel?.text = "Choose Picture"
                cell.imageView?.image = UIImage.init(systemName: "photo")
                cell.textLabel?.textColor = UIApplication.shared.windows.first!.tintColor
                
            default:
                break
            }
        case .Actions:
            cell.textLabel?.text = "Post Item"
            cell.imageView?.image = UIImage.init(systemName: "paperplane")
            cell.textLabel?.textColor = UIApplication.shared.windows.first!.tintColor
        default:
            break
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let identifier = self.sections.identiferForSectionAtIndex(indexPath.section)
        switch identifier {
        case .ItemClassification:
            let new = Item.Kind.allCases[indexPath.row]
            if (self.item.kind == .Shoes && new != .Shoes) || (self.item.kind != .Shoes && new == .Shoes) {
                self.item.size = nil
            }
            self.item.kind = new
            self.tableView.beginUpdates()
            self.tableView.reloadSections(IndexSet.init([indexPath.section,indexPath.section+1]), with: .fade)
            self.tableView.endUpdates()
        case .ItemSizing:
            if let subviews = tableView.cellForRow(at: indexPath)?.subviews {
                for view in subviews {
                    if let tf = view as? UITextField {
                        tf.becomeFirstResponder()
                    }
                }
            }
        case .ItemImages:
            if indexPath.row > 0 {
                openImagePicker(fromCamera: indexPath.row == 1)
            }
        case .Actions:
            print(self.item.firestore)
        default:
            break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    @objc func toggleInstant(sender: UISwitch) {
        self.item.instant.toggle()
    }
    
    func openImagePicker( fromCamera: Bool) {
        let vc = UIImagePickerController()
        vc.sourceType = fromCamera ? .camera : .photoLibrary
        vc.allowsEditing = true
        vc.delegate = self
        present(vc, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)

        guard let image = info[.editedImage] as? UIImage else {
            print("No image found")
            return
        }
        
        self.item.attachImage(image)
        self.tableView.beginUpdates()
        self.tableView.reloadSections(IndexSet.init(integer: 0), with: .fade)
        self.tableView.endUpdates()
    }
    
    var sizeField:UITextField?

}

extension PostViewController: UITextFieldDelegate {
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField.tag == 2 {
            self.sizeField = textField
        }
        return true
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let text = textField.text {
            switch textField.tag {
            case 0:
                self.item.brand = text
                if self.item.name == nil {
                    if let index = self.sections.indexForIdentifier(.ItemNaming) {
                        let cell = self.tableView.cellForRow(at: IndexPath.init(row: 1, section: index))
                        if let subviews = cell?.subviews {
                            for view in subviews {
                                if let tf = view as? UITextField {
                                    tf.becomeFirstResponder()
                                }
                            }
                        }
                    }
                }
            case 1:
                self.item.name = text
            case 2:
                self.item.size = text
            case 3:
                self.item.cost = Int(text.replacingOccurrences(of: "$", with: ""))
            default:
                break
            }
        }
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField.tag == 3 {
            if !(string.isEmpty) {
                if string.isNumber {
                    if let text = textField.text {
                        if !(text.contains("$")) {
                            textField.text = "$\(text)"
                        }
                    }
                } else {
                    return false
                }
            }
        }
        return true
    }
}

extension String  {
    var isNumber: Bool {
        return !isEmpty && rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }
}

extension Float {
    var clean: String {
       return self.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(self)
    }
}

extension PostViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0 {
            return 2
        }
        return self.sizes.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if component == 0 {
            if row == 0 {
                return "Mens"
            }
            return "Womens"
        }
        return self.sizes[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let size = self.sizes[row]
        self.item.size = "\(pickerView.selectedRow(inComponent: 0) == 0 ? "Mens" : "Womens") \(size)"
        self.sizeField?.text = self.item.size
    }
    
    
    func setInputSizePicker(textfield: UITextField) {
        // Create a UIDatePicker object and assign to inputView
        let screenWidth = UIScreen.main.bounds.width
        let picker = UIPickerView.init(frame: CGRect(x: 0, y: 0, width: screenWidth, height: 216))
        picker.delegate = self
        textfield.inputView = picker //3
        
        // Create a toolbar and assign it to inputAccessoryView
        let toolBar = UIToolbar(frame: CGRect(x: 0.0, y: 0.0, width: screenWidth, height: 44.0)) //4
        let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil) //5
        let cancel = UIBarButtonItem(title: "Cancel", style: .plain, target: nil, action: #selector(tapCancel)) // 6
        let barButton = UIBarButtonItem(title: "Done", style: .plain, target: nil, action: #selector(tapDone)) //7
        toolBar.setItems([cancel, flexible, barButton], animated: false) //8
        textfield.inputAccessoryView = toolBar //9
    }
    
    @objc func tapCancel() {
        self.item.size = nil
        sizeField!.resignFirstResponder()
    }
    
    @objc func tapDone() {
        sizeField!.resignFirstResponder()
    }
    
}

