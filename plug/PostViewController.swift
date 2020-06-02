//
//  PostViewController.swift
//  plug
//
//  Created by Robert Crosby on 5/23/20.
//  Copyright © 2020 Robert Crosby. All rights reserved.
//
import Firebase
import UIKit

class PostViewController: UITableViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    
    weak var delegate:RootDelegate?
    var sizes = [String]()

    
    let sections = SectionController()
    var item = Item()
    
    init() {
        super.init(style: .grouped)
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.title = "Post"
        self.tabBarItem = UITabBarItem.init(title: nil, image: UIImage.init(systemName: "tag"), selectedImage: UIImage.init(systemName: "tag.fill"))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        
        self.tableView.register(UINib(nibName: "GrowingCell", bundle: nil), forCellReuseIdentifier: "GrowingCell")
        
        self.sections.updateSection(title: .ItemNaming, rows: 1)
        self.sections.updateSection(title: .ItemImages, rows: 1)
        self.sections.updateSection(title: .ItemClassification, rows: 1)
        self.sections.updateSection(title: .ItemSizing, rows: 1)
        self.sections.updateSection(title: .ItemPricing, rows: 1)
        self.sections.updateSection(title: .Actions, rows: 1)
        item.delegate = self
        super.viewDidLoad()
        self.tableView.backgroundColor = .secondarySystemGroupedBackground
        
        let refresh = UIRefreshControl.init()
        refresh.largeContentTitle = "Clear Table"
        refresh.attributedTitle = NSAttributedString.init(string: "Clear Table")
        refresh.addTarget(self, action: #selector(clearInput(sender:)), for: .valueChanged)
        self.tableView.refreshControl = refresh
    }
    
    @objc func clearInput(sender: UIRefreshControl) {
        item = .init()
        self.imagesUploaded = 0
        item.delegate = self
        self.tableView.beginUpdates()
        self.tableView.reloadSections(IndexSet.init(0..<self.sections.count), with: .fade)
        self.tableView.endUpdates()
        sender.endRefreshing()
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
        if identifier == .ItemClassification {
            return 80
        }
        if (identifier == .ItemSizing) || (identifier == .ItemPricing) || (identifier == .Actions) {
            return 60
        } else if identifier == .ItemImages && indexPath.row == 0 {
            return self.item.getImageCollectionContentHeight()
        }
        return UITableView.automaticDimension
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let identifier = self.sections.identiferForSectionAtIndex(indexPath.section)
        let cell = UITableViewCell.init(style: .default, reuseIdentifier: nil)
        cell.backgroundColor = .systemGroupedBackground
        switch identifier {
        case .ItemNaming:
            let cell = tableView.dequeueReusableCell(withIdentifier: "GrowingCell", for: indexPath) as! GrowingCell
            cell.backgroundColor = .systemGroupedBackground
            cell.textView.font = .systemFont(ofSize: 24, weight: .bold)
            cell.textView.autocapitalizationType = .words
            cell.textView.autocorrectionType = .no
            cell.placeholder.font = cell.textView.font
            cell.textView.text = self.item.name
            cell.placeholder.isHidden = !(cell.textView.text.isEmpty)
            cell.cellDelegate = self
            return cell
        case .ItemClassification:
            let segment = UISegmentedControl.init(items: ["👟","👕","🧥","👖","🕶"])
            segment.backgroundColor = .clear
            segment.setTitleTextAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 23)], for: .normal)
            segment.selectedSegmentIndex = Item.Kind.allCases.firstIndex(of: self.item.kind) ?? 0
            segment.addTarget(self, action: #selector(changeKind(_:)), for: .valueChanged)
            segment.frame = CGRect.init(x: 15, y: 15, width: self.view.frame.size.width-30, height: 50)
            cell.addSubview(segment)
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
                sizes = ["Small","Medium","Large","XL","XXL"]
            }
            setInputSizePicker(textfield: textfield)
            textfield.font = .systemFont(ofSize: 24, weight: .bold)
            textfield.text = self.item.size
            textfield.textAlignment = .right
            textfield.delegate = self
            textfield.tag = 2
            cell.accessoryView = textfield
            cell.textLabel?.text = "SIZE"
            cell.textLabel?.font = textfield.font
            cell.textLabel?.textColor = .systemGray
            cell.textLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        case .ItemPricing:
            if indexPath.row == 0 {
                let textfield = UITextField.init(frame: CGRect.init(x: 0, y: 0, width: 100, height: 50))
                textfield.placeholder = "$90"
                textfield.keyboardType = .numbersAndPunctuation
                textfield.textAlignment = .right
                textfield.font = .systemFont(ofSize: 24, weight: .bold)
                textfield.delegate = self
                textfield.tag = 3
                cell.accessoryView = textfield
                cell.textLabel?.text = "ASKING PRICE"
                cell.textLabel?.textColor = .systemGray
                cell.textLabel?.font = .systemFont(ofSize: 16, weight: .bold)
            } else if indexPath.row == 1 {
                let toggle = UISwitch.init()
                toggle.setOn(self.item.instant, animated: false)
                toggle.addTarget(self, action: #selector(toggleInstant(sender:)), for: .valueChanged)
                cell.accessoryView = toggle
                cell.textLabel?.text = "ACCEPT FIRST OFFER"
                cell.textLabel?.textColor = .systemGray
                cell.textLabel?.font = .systemFont(ofSize: 16, weight: .bold)
            }
        case .ItemImages:
            let collection = self.item.getPostImageCollection(frame: CGRect.init(origin: CGPoint.init(x: 15, y: 15), size: CGSize.init(width: self.view.frame.size.width-30, height: 130)))
            cell.addSubview(collection)
        case .Actions:
            cell.textLabel?.text = "POST ITEM"
            cell.textLabel?.font = .systemFont(ofSize: 16, weight: .bold)
            cell.textLabel?.textColor = UIApplication.shared.windows.first!.tintColor
        default:
            break
        }
        return cell
    }
    
    @objc func changeKind(_ sender: UISegmentedControl) {
        let current = self.item.kind
        self.item.kind = Item.Kind.allCases[sender.selectedSegmentIndex]
        if (current == .Shoes && self.item.kind != .Shoes) || (current != .Shoes && self.item.kind == .Shoes) {
            self.item.size = nil
            if let index = self.sections.indexForIdentifier(.ItemSizing) {
                self.tableView.beginUpdates()
                self.tableView.reloadSections(IndexSet.init(integer: index), with: .fade)
                self.tableView.endUpdates()
            }
        }
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
        case .ItemPricing:
            if indexPath.row == 0 {
                if let subviews = tableView.cellForRow(at: indexPath)?.subviews {
                    for view in subviews {
                        if let tf = view as? UITextField {
                            tf.becomeFirstResponder()
                        }
                    }
                }
            }
        case .ItemImages:
            break
        case .Actions:
            self.initiatePosting()
        default:
            break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    @objc func toggleInstant(sender: UISwitch) {
        self.item.instant.toggle()
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)

        guard let image = info[.editedImage] as? UIImage else {
            print("No image found")
            return
        }
        
        self.item.attachImage(image)
        self.tableView.beginUpdates()
        if let index = self.sections.indexForIdentifier(.ItemImages) {
            self.tableView.reloadSections(IndexSet.init(integer: index), with: .fade)
        }
        self.tableView.endUpdates()
    }
    
    var sizeField:UITextField?
    
    var loadingView:UIAlertController?
    var imagesUploaded = Int(0)
    
    func initiatePosting() {
        if let notReady = self.item.readyToPost() {
            self.delegate?.showAlert(title: nil, message: notReady)
        } else {
            loadingView = UIAlertController.init(title: nil, message: "Uploading Pictures...", preferredStyle: .alert)
            self.present(loadingView!, animated: true) {
                self.item.uploadImages()
            }
        }
        
    }
}

extension PostViewController: ItemDelegate {
    @objc func openImagePicker() {
        let alert = UIAlertController.init(title: "Attach Picture", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction.init(title: "Take Picture", style: .default, handler: { (action) in
            let vc = UIImagePickerController()
            vc.sourceType = .camera
            vc.allowsEditing = true
            vc.delegate = self
            self.present(vc, animated: true)
        }))
        alert.addAction(UIAlertAction.init(title: "Select Picture", style: .default, handler: { (action) in
            let vc = UIImagePickerController()
            vc.sourceType = .photoLibrary
            vc.allowsEditing = true
            vc.delegate = self
            self.present(vc, animated: true)
        }))
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
        
    }
    
    @objc func imageDoneUploading() {
        imagesUploaded+=1
        if imagesUploaded == self.item.images?.count {
            self.loadingView?.dismiss(animated: true, completion: {
                self.loadingView! = UIAlertController.init(title: nil, message: "Making Post", preferredStyle: .alert)
                self.present(self.loadingView!, animated: true) {
                    self.item.makePost { (result, error) in
                        if result == true {
                            self.loadingView?.dismiss(animated: true, completion: {
                                self.delegate?.showAlert(title: nil, message: "Sucess!")
                            })
                        } else {
                            self.loadingView?.dismiss(animated: true, completion: {
                                self.delegate?.showAlert(title: "Error", message: error!)
                            })
                        }
                    }
                }
            })
        }
    }
    
    @objc func errorUploadingImage(index: Int, message: String) {
        self.loadingView?.dismiss(animated: true, completion: {
            self.delegate?.showAlert(title: "Image \(index) Error", message: message)
        })
    }
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

extension PostViewController: GrowingCellProtocol {
    
    func updateHeightOfRow(_ cell: GrowingCell, _ textView: UITextView) {
        self.item.name = textView.text
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
