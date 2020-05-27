
import UIKit
import Firebase

protocol OfferDelegate: class {
    func offerUpdated()
    func messageInserted(index: Int?)
}

class Offer: NSObject {
    
    weak var delegate:OfferDelegate?
    
    var reference:DocumentReference
    var listener:ListenerRegistration?
    var messageListener:ListenerRegistration?
    
    var date:Date?
    var item:String?
    var customer:String?
    var seller:String?
    var amount:Int?
    var local:Bool?
    
    init(preliminary: DocumentReference, amount: Int) {
        self.reference = preliminary
        self.offerComposerAmount = amount
    }
    
    init(_ reference: DocumentReference) {
        self.reference = reference
    }
    
    init(fromQuery: QueryDocumentSnapshot) {
        self.reference = fromQuery.reference
        self.date = (fromQuery.data()["date"] as? Timestamp)?.dateValue()
        self.item = fromQuery.data()["item"] as? String
        self.customer = fromQuery.data()["customer"] as? String
        self.seller = fromQuery.data()["seller"] as? String
        self.amount = fromQuery.data()["amount"] as? Int
        self.local = fromQuery.data()["local"] as? Bool
    }

    func updateData() {
        if self.listener == nil {
            self.listener = self.reference.addSnapshotListener { (snapshot, error) in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                if let data = snapshot?.data() {
                    self.date = (data["date"] as? Timestamp)?.dateValue()
                    self.item = data["item"] as? String
                    self.customer = data["customer"] as? String
                    self.seller = data["seller"] as? String
                    self.amount = data["amount"] as? Int
                    self.local = data["local"] as? Bool
                    self.delegate?.offerUpdated()
                }
            }
        }
    }
    
    func submitOffer(_ amount: Int, _ local: Bool) {
        self.reference.updateData([
            "amount"    : amount,
            "local"     : local
        ]) { (error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
        }
    }
    
    var messages:[Message]?
    
    func updateMessages() {
        if self.messageListener == nil {
            self.messageListener = self.reference.collection("messages").order(by: "timestamp", descending: false).addSnapshotListener({ (snapshot, error) in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                if let data = snapshot?.documentChanges {
                    if self.messages == nil {
                        print("first fetch of messages")
                        self.messages = data.map({ (message) -> Message in
                            return Message.init(qds: message.document)
                        })
                        self.delegate?.messageInserted(index: nil)
                    } else {
                        print("new messages")
                        for message in data {
                            if message.type == .added {
                                self.messages!.append(Message.init(qds: message.document))
                                self.delegate?.messageInserted(index: self.messages!.count-1)
                            }
                        }
                    }
                }
            })
        }
    }
    
    func sendMessage(_ text: String) {
        if let uid = Auth.auth().currentUser?.uid {
            self.reference.collection("messages").document().setData([
                "timestamp" : FieldValue.serverTimestamp(),
                "sender"    : uid,
                "text"      : text
            ]) { (error) in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
            }
        }
    }
    
    
    var offerComposerAmount:Int?
    var offerComposerIsLocal:Bool?
    
    var summarySections:SectionController?
    var summaryView:UITableView?
}

extension Offer: UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate {
    
    func createSummaryView(width: CGFloat) {
        if summaryView == nil {
            summarySections = SectionController()
            summaryView = UITableView.init(frame: CGRect.init(origin: .zero, size: CGSize.init(width: width, height: CGFloat(0))), style: .insetGrouped)
            summaryView?.isScrollEnabled = false
            summaryView?.contentInset = .zero
            summaryView?.delegate = self
            summaryView?.dataSource = self
            summaryView?.separatorInset = UIEdgeInsets.zero
        }
        updateSummaryView()
    }
    
    func updateSummaryView() {
        self.summarySections?.sections.removeAll()
        if self.amount == nil {
            self.summarySections?.updateSection(title: .OfferComposer, rows: 3)
        } else {
            self.summarySections?.updateSection(title: .OfferPending, rows: 2)
        }
        self.summaryView?.reloadData()
        self.summaryView?.frame.size.height = self.summaryView!.contentSize.height + 15
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.summarySections?.rowsInSectionAtIndex(section) ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = self.summarySections?.identiferForSectionAtIndex(indexPath.section)
        switch identifier {
        case .OfferComposer:
            let cell = UITableViewCell.init(style: .default, reuseIdentifier: nil)
            cell.textLabel?.textColor = .systemGray
            cell.textLabel?.font = .systemFont(ofSize: 16, weight: .bold)
            if indexPath.row == 0 {
                let textfield = UITextField.init(frame: CGRect.init(x: 0, y: 0, width: 100, height: 50))
                textfield.placeholder = "$__"
                if let offerComposerAmount = self.offerComposerAmount {
                    textfield.text = "$\(offerComposerAmount)"
                }
                textfield.keyboardType = .numbersAndPunctuation
                textfield.textAlignment = .right
                textfield.font = .systemFont(ofSize: 24, weight: .bold)
                textfield.delegate = self
                textfield.tag = 1
                cell.accessoryView = textfield
                cell.textLabel?.text = "OFFER AMMOUNT"
                cell.selectionStyle = .none
            } else if indexPath.row == 1 {
                cell.textLabel?.text = "LOCAL PICKUP"
                let control = UISwitch.init()
                control.setOn(self.offerComposerIsLocal ?? false, animated: false)
                control.addTarget(self, action: #selector(toggleLocal), for: .valueChanged)
                cell.accessoryView = control
                cell.selectionStyle = .none
            } else {
                cell.textLabel?.text = "SUBMIT OFFER"
                cell.textLabel?.textAlignment = .center
                cell.backgroundColor = .systemRed
                cell.textLabel?.textColor = .white
            }
            return cell
        case .OfferPending:
            if indexPath.row == 0 {
                let cell = UITableViewCell.init(style: .subtitle, reuseIdentifier: nil)
                cell.textLabel?.text = "$\(self.amount ?? 0)"
                cell.textLabel?.font = titleFont
                cell.detailTextLabel?.text = "..."
                cell.detailTextLabel?.font = buttonFont
                justFetchItemName(self.item!) { (name) in
                    cell.detailTextLabel?.text = name
                    
                }
                return cell
            } else {
                let cell = UITableViewCell.init(style: .default, reuseIdentifier: nil)
                cell.textLabel?.text = "OFFER PENDING"
//                cell.textLabel?.textAlignment = .center
                cell.textLabel?.font = buttonFont
                cell.textLabel?.textColor = .systemGray
                return cell
            }
            
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch self.summarySections?.identiferForSectionAtIndex(indexPath.section) {
        case .OfferComposer:
            if indexPath.row == 0 {
                for view in tableView.cellForRow(at: indexPath)!.subviews {
                    if let tf = view as? UITextField {
                        tf.becomeFirstResponder()
                    }
                }
            } else if indexPath.row == 2 {
                if let offerAmount = offerComposerAmount {
                    self.submitOffer(offerAmount, offerComposerIsLocal ?? false)
                }
            }
        default:
            break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let identifier = self.summarySections?.identiferForSectionAtIndex(indexPath.section)
        if identifier == .OfferComposer && indexPath.row < 2 {
            return 60
        }
        return UITableView.automaticDimension
    }
    
    @objc func toggleLocal() {
        if self.offerComposerIsLocal == nil {
            self.offerComposerIsLocal = true
        } else {
            self.offerComposerIsLocal!.toggle()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let text = textField.text {
            switch textField.tag {
            case 1:
                self.offerComposerAmount = Int(text.replacingOccurrences(of: "$", with: ""))
            default:
                break
            }
        }
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField.tag == 1 {
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

class Message {
    
    let sender:String
    let text:String
    var timestamp:Date?
    var size:CGSize?
    
    var amSender: Bool {
        if let uid = Auth.auth().currentUser?.uid {
            return uid == sender
        }
        return false
    }
    
    init(qds: QueryDocumentSnapshot) {
        print(qds.data())
        self.sender = qds.data()["sender"] as! String
        self.text = qds.data()["text"] as! String
        if let timestamp = (qds.data()["timestamp"] as? Timestamp) {
            self.timestamp = timestamp.dateValue()
        }
    }
    
    func getFrame(width: inout CGFloat) -> CGSize {
        if size == nil {
            let calculateWidth = self.text.width(withConstrainedHeight: 100, font: UIFont.systemFont(ofSize: 14))
            let height = self.text.height(withConstrainedWidth: width, font: UIFont.systemFont(ofSize: 14))
            if calculateWidth > width {
                self.size = CGSize.init(width: width+10, height: height+10)
            } else {
                self.size = CGSize.init(width: calculateWidth+20, height: height+10)
            }
        }
        return self.size!
    }
}
