
import UIKit
import Firebase
import PassKit

protocol OfferDelegate: class {
    func offerDeclined()
    func offerUpdated()
    func presentTransactionView(_ transaction: Transaction)
    func messageInserted(index: Int?)
    func presentApplePay()
    func showMarkShippedAddTrackingNumber(_ complete: @escaping (String?) -> ())
}

class Offer: NSObject {
    
    var isPopulated = false
    
    weak var delegate:OfferDelegate?
    
    var id:String {
        return reference.documentID
    }
    
    var reference:DocumentReference
    var listener:ListenerRegistration?
    var messageListener:ListenerRegistration?
    
    var date:Date?
    var item:String?
    var customer:String?
    var seller:String?
    var complete:Bool
    
    var amount:Int?
    var local:Bool?
    var cash:Bool?
    var payment:String?
    var shipping_name:String?
    var shipping_address:String?
    var shipped:Bool?
    var tracking_number:String?
    
    var statusText: String {
        if complete {
            return "Sale complete"
        }
        if accepted ?? false {
            if cash ?? false {
                return "Organize meetup to complete sale"
            }
            if payment == nil {
                return "Waiting for payment"
            }
            if shipped ?? false {
                return "Item Shipped, waiting to be recieved"
            } else {
                return "Waiting for shipment"
            }
        } else {
            return "Waiting for seller to accept offer"
        }
        
    }
    
    var accepted:Bool?
    
    var paymentIntent:Transaction?
    
    init(preliminary: DocumentReference, amount: Int) {
        self.reference = preliminary
        self.offerComposerAmount = amount
        self.complete = false
    }
    
    init(_ reference: DocumentReference) {
        self.reference = reference
        self.complete = false
    }
    
    init(fromQuery: QueryDocumentSnapshot) {
        self.reference = fromQuery.reference
        self.date = (fromQuery.data()["date"] as? Timestamp)?.dateValue()
        self.item = fromQuery.data()["item"] as? String
        self.customer = fromQuery.data()["customer"] as? String
        self.seller = fromQuery.data()["seller"] as? String
        self.amount = fromQuery.data()["amount"] as? Int
        self.local = fromQuery.data()["local"] as? Bool
        self.cash = fromQuery.data()["cash"] as? Bool
        self.accepted = fromQuery.data()["accepted"] as? Bool
        self.payment = fromQuery.data()["payment"] as? String
        self.shipping_name = fromQuery.data()["shipping_name"] as? String
        self.shipping_address = fromQuery.data()["shipping_address"] as? String
        self.shipped = fromQuery.data()["shipped"] as? Bool
        self.tracking_number = fromQuery.data()["tracking_number"] as? String
        self.complete = fromQuery.data()["complete"] as! Bool
        self.isPopulated = true
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
                    self.cash = data["cash"] as? Bool
                    self.accepted = data["accepted"] as? Bool
                    self.payment = data["payment"] as? String
                    self.shipping_name = data["shipping_name"] as? String
                    self.shipping_address = data["shipping_address"] as? String
                    self.shipped = data["shipped"] as? Bool
                    self.tracking_number = data["tracking_number"] as? String
                    self.complete = data["complete"] as! Bool
                    self.isPopulated = true
                    self.delegate?.offerUpdated()
                }
            }
        }
    }
    
    func submitOffer(_ amount: Int, _ local: Bool, _ cash: Bool) {
        self.reference.updateData([
            "amount"    : amount,
            "local"     : local,
            "cash"      : cash
        ]) { (error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
        }
    }
    
    func acceptOffer() {
        let batch = Firestore.firestore().batch()
        batch.updateData(["accepted" : true], forDocument: self.reference)
        batch.updateData(["sold": true], forDocument: Firestore.firestore().collection("items").document(self.item!))
        batch.commit { (error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
        }
    }
    
    func deleteOffer() {
        let batch = Firestore.firestore().batch()
        batch.deleteDocument(self.reference)
        batch.updateData(["sold": false], forDocument: Firestore.firestore().collection("items").document(self.item!))
        batch.commit { (error) in
            if let error = error {
                print(error.localizedDescription)
            }
            self.delegate?.offerDeclined()
        }
    }
    
    @objc func counterToOffer() {
        self.reference.updateData([
            "amount"    : FieldValue.delete(),
            "local"     : FieldValue.delete(),
            "cash"      : FieldValue.delete()
        ]) { (error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
        }
    }
    
    func markShipped(_ updatedData: [String:Any]) {
        self.reference.updateData(updatedData) { (error) in
            if let error = error {
                print(error)
                return
            }
        }
    }
    
    func markReceived() {
        self.reference.updateData(["complete": true], completion: nil)
    }
    
    func retrievePaymentInformation(_ complete: @escaping (Transaction?) -> ()) {
        if let payment = self.payment {
            if self.paymentIntent == nil {
                Functions.functions().httpsCallable("getSingleCharge").call(["payment":payment]) { (result, error) in
                    if let error = error as NSError? {
                        if error.domain == FunctionsErrorDomain {
                            let message = error.localizedDescription
                            print("ERROR: \(message)")
                            return
                        }
                    }
                    if let data = result?.data as? [String:Any] {
                        self.paymentIntent = Transaction.init(data: data)
                        complete(self.paymentIntent)
                        return
                    }
                }
            } else {
                complete(self.paymentIntent)
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
    var offerComposerIsCash:Bool?
    
    var summarySections:SectionController?
    var summaryView:UITableView?
    var summaryViewBlur:UIVisualEffectView?
}

extension Offer: UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y != 0 {
            scrollView.contentOffset.y = 0
        }
    }
    
    func createSummaryView(width: CGFloat) {
        if summaryView == nil {
            summarySections = SectionController()
            summaryView = UITableView.init(frame: CGRect.init(origin: .zero, size: CGSize.init(width: width, height: CGFloat(0))), style: .plain)
            summaryView?.backgroundColor = .clear
            summaryView?.showsVerticalScrollIndicator = false
//            self.summaryView?.separatorStyle = .none
            summaryView?.delegate = self
            summaryView?.dataSource = self
            summaryView?.separatorInset = UIEdgeInsets.zero
        }
        updateSummaryView()
    }
    
    func updateSummaryView() {
        var height = CGFloat(0)
        self.summarySections?.sections.removeAll()
        if self.amount == nil {
            if let uid = Auth.auth().currentUser?.uid {
                if uid == self.customer {
                    self.summarySections?.updateSection(title: .OfferAmount, rows: 1)
                    self.summarySections?.updateSection(title: .OfferLocal, rows: 1)
                    height+=120
                    if self.offerComposerIsLocal ?? false {
                        self.summarySections?.updateSection(title: .OfferCash, rows: 1)
                        height+=60
                    }
                    self.summarySections?.updateSection(title: .OfferSubmit, rows: 1)
                    height+=70
                } else {
                    self.summarySections?.updateSection(title: .OfferNotSubmitted, rows: 1)
                    height+=90
                }
            } else {
                height+=0
            }
        } else {
            self.summarySections?.updateSection(title: .OfferPending, rows: 1)
            height+=80
            if self.payment != nil {
                self.summarySections?.updateSection(title: .OfferRecieptPreview, rows: 1)
                height+=50
            }
            if self.complete == true {
            
            } else if self.shipped != nil {
                self.summarySections?.updateSection(title: .OfferShipped, rows: 1)
                height+=30
                self.summarySections?.updateSection(title: .OfferTrackShipped, rows: 1)
                height+=70
            } else if self.payment != nil {
                self.summarySections?.updateSection(title: .OfferPaid, rows: 1)
                height+=30
                if !(self.local!) {
                    if let uid = Auth.auth().currentUser?.uid {
                        if uid == self.seller! {
                            self.summarySections?.updateSection(title: .OfferShippingAddress, rows: 1)
                            self.summarySections?.updateSection(title: .OfferSellerMarkShipped, rows: 1)
                            height+=100+70
                        }
                    }
                }
            } else if self.accepted != nil {
                if  let cash = self.cash,
                    let uid = Auth.auth().currentUser?.uid {
                        if cash {
                            self.summarySections?.updateSection(title: .OfferCashCompletion, rows: 1)
                            height+=30
                            if self.seller! == uid {
                                self.summarySections?.updateSection(title: .OfferSellerMarkComplete, rows: 1)
                                height+=70
                            }
                        } else {
                            self.summarySections?.updateSection(title: .OfferCardCompletion, rows: 1)
                            height+=30
                            if self.customer! == uid {
                                self.summarySections?.updateSection(title: .OfferCustomerCardPayment, rows: 1)
                                height+=70
                            }
                        }
                }
                
            } else if self.accepted == nil {
                if let uid = Auth.auth().currentUser?.uid,
                    let seller = self.seller {
                    if uid == seller {
                        self.summarySections?.updateSection(title: .OfferSellerAccept, rows: 1)
                        height+=70
                    }
                }
            }
        }
        
        self.summaryView?.reloadData()
        if summaryViewBlur == nil {
            summaryViewBlur = UIVisualEffectView.init(effect: UIBlurEffect.init(style: .prominent))
            summaryView?.backgroundView = summaryViewBlur
            summaryViewBlur?.isUserInteractionEnabled = false
        }
        self.summaryView?.frame.size.height = height
        summaryViewBlur!.frame = summaryView!.bounds
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.summarySections?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell:UITableViewCell
        let identifier = self.summarySections?.identiferForSectionAtIndex(indexPath.row)
        switch identifier {
        case .OfferAmount:
            cell = UITableViewCell.init(style: .default, reuseIdentifier: nil)
            cell.textLabel?.textColor = .systemGray
            cell.textLabel?.font = buttonFont
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
            cell.textLabel?.text = "OFFER AMOUNT"
            cell.selectionStyle = .none
        case .OfferLocal:
            cell = UITableViewCell.init(style: .default, reuseIdentifier: nil)
            cell.textLabel?.textColor = .systemGray
            cell.textLabel?.font = buttonFont
            cell.textLabel?.text = "LOCAL PICKUP"
            let control = UISwitch.init()
            control.setOn(self.offerComposerIsLocal ?? false, animated: false)
            control.addTarget(self, action: #selector(toggleLocal), for: .valueChanged)
            cell.accessoryView = control
            cell.selectionStyle = .none
        case .OfferCash:
            cell = UITableViewCell.init(style: .default, reuseIdentifier: nil)
            cell.textLabel?.textColor = .systemGray
            cell.textLabel?.font = buttonFont
            cell.textLabel?.text = "CASH PAYMENT"
            let control = UISwitch.init()
            control.setOn(self.offerComposerIsCash ?? false, animated: false)
            control.addTarget(self, action: #selector(toggleCash), for: .valueChanged)
            cell.accessoryView = control
            cell.selectionStyle = .none
        case .OfferSubmit:
            cell = UITableViewCell.init(style: .default, reuseIdentifier: nil)
            let submitbutton = UIButton.init(frame: CGRect.init(x: 15, y: 15, width: self.summaryView!.frame.size.width-30, height: 40))
            submitbutton.setTitle("SUBMIT OFFER", for: .normal)
            submitbutton.titleLabel?.font = buttonFont
            submitbutton.backgroundColor = .systemRed
            submitbutton.layer.cornerRadius = 5
            submitbutton.layer.masksToBounds = true
            submitbutton.addTarget(self, action: #selector(tableSubmitOffer), for: .touchUpInside)
            cell.addSubview(submitbutton)
            cell.selectionStyle = .none
        case .OfferPending:
            cell = UITableViewCell.init(style: .subtitle, reuseIdentifier: nil)
            cell.textLabel?.text = "$\(self.amount ?? 0)"
            cell.textLabel?.font = titleFont
            
            cell.selectionStyle = .none
            cell.detailTextLabel?.text = "..."
            cell.detailTextLabel?.font = buttonFont
            cell.detailTextLabel?.adjustsFontSizeToFitWidth = true
            fetchItemDetail(self.item!) { (name, _) in
                if let name = name {
                    cell.detailTextLabel?.text = name
                }
            }
        case .OfferRecieptPreview:
            cell = UITableViewCell.init(style: .default, reuseIdentifier: nil)
            cell.textLabel?.font = buttonFont
            cell.textLabel?.text = "View Receipt"
            cell.accessoryType = .disclosureIndicator
        case .OfferNotSubmitted:
            cell = UITableViewCell.init(style: .subtitle, reuseIdentifier: nil)
            cell.textLabel?.font = titleFont
            cell.selectionStyle = .none
            cell.detailTextLabel?.text = "This offer has not been submitted."
            cell.detailTextLabel?.font = buttonFont
            fetchItemDetail(self.item!) { (name, _) in
                if let name = name {
                    cell.textLabel?.text = name
                }
            }
        case .OfferSellerAccept:
            cell = UITableViewCell.init(style: .default, reuseIdentifier: nil)
            let rejectButton = UIButton.init(frame: CGRect.init(x: 15, y: 15, width: 40, height: 40))
            rejectButton.setImage(UIImage.init(systemName: "bin.xmark"), for: .normal)
            rejectButton.addTarget(self, action: #selector(tableRespondToOffer(_:)), for: .touchUpInside)
            rejectButton.tintColor = .label
            rejectButton.layer.cornerRadius = 5
            rejectButton.layer.masksToBounds = true
            rejectButton.backgroundColor = .secondarySystemGroupedBackground

            cell.addSubview(rejectButton)
            
            let buttonWidth = (summaryView!.frame.size.width - 15 - (rejectButton.frame.maxX) - 30)/2
            let counterButton = UIButton.init(frame: CGRect.init(x: rejectButton.frame.maxX+15, y: rejectButton.frame.origin.y, width: buttonWidth, height: rejectButton.frame.size.height))
            counterButton.setTitle("COUNTER", for: .normal)
            counterButton.titleLabel?.font = buttonFont
            counterButton.addTarget(self, action: #selector(counterToOffer), for: .touchUpInside)
            counterButton.setTitleColor(.label, for: .normal)
            counterButton.layer.cornerRadius = 5
            counterButton.layer.masksToBounds = true
            counterButton.backgroundColor = .secondarySystemGroupedBackground
            cell.addSubview(counterButton)
            
            let acceptButton = UIButton.init(frame: CGRect.init(x: counterButton.frame.maxX+15, y: rejectButton.frame.origin.y, width: buttonWidth, height: rejectButton.frame.size.height))
            acceptButton.setTitle("ACCEPT", for: .normal)
            acceptButton.titleLabel?.font = buttonFont
            acceptButton.backgroundColor = .systemRed
            acceptButton.layer.cornerRadius = 5
            acceptButton.tag = 9
            acceptButton.addTarget(self, action: #selector(tableRespondToOffer(_:)), for: .touchUpInside)
            acceptButton.layer.masksToBounds = true
            cell.addSubview(acceptButton)
        case .OfferCustomerCardPayment:
            cell = UITableViewCell.init(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = "MAKE PAYMENT"
            cell.textLabel?.textColor = .systemGray
            cell.textLabel?.font = UIFont.systemFont(ofSize: 12, weight: .bold)
            let appleButton = PKPaymentButton.init(paymentButtonType: .buy, paymentButtonStyle: .black)
            appleButton.addTarget(self, action: #selector(startApplePayProcess), for: .touchUpInside)
            appleButton.frame = CGRect.init(origin: .zero, size: CGSize.init(width: 100, height: 40))
            cell.accessoryView = appleButton
            cell.selectionStyle = .none
        case .OfferSellerMarkComplete:
            cell = UITableViewCell.init(style: .default, reuseIdentifier: nil)
            let markComplete = UIButton.init(frame: CGRect.init(x: 15, y: 15, width: self.summaryView!.frame.size.width-30, height: 40))
            markComplete.setTitle("COMPLETE SALE", for: .normal)
            markComplete.titleLabel?.font = buttonFont
            markComplete.backgroundColor = .systemRed
            markComplete.layer.cornerRadius = 5
            markComplete.layer.masksToBounds = true
            markComplete.addTarget(self, action: #selector(startMarkRecieved), for: .touchUpInside)
            cell.addSubview(markComplete)
            cell.selectionStyle = .none
        case .OfferSellerMarkShipped:
            cell = UITableViewCell.init(style: .default, reuseIdentifier: nil)
            let markShipped = UIButton.init(frame: CGRect.init(x: 15, y: 15, width: self.summaryView!.frame.size.width-30, height: 40))
            markShipped.setTitle("MARK SHIPPED", for: .normal)
            markShipped.titleLabel?.font = buttonFont
            markShipped.backgroundColor = .systemRed
            markShipped.layer.cornerRadius = 5
            markShipped.layer.masksToBounds = true
            markShipped.addTarget(self, action: #selector(startShippedProcess), for: .touchUpInside)
            cell.addSubview(markShipped)
        case .OfferTrackShipped:
            
            cell = UITableViewCell.init(style: .default, reuseIdentifier: nil)
            let trackShipped = UIButton.init(frame: CGRect.init(x: 15, y: 15, width: self.summaryView!.frame.size.width-30, height: 40))
            trackShipped.setTitle("TRACK PACKAGE", for: .normal)
            trackShipped.titleLabel?.font = buttonFont
            trackShipped.backgroundColor = .secondarySystemGroupedBackground
            trackShipped.setTitleColor(.label, for: .normal)
            trackShipped.layer.cornerRadius = 5
            trackShipped.layer.masksToBounds = true
//            trackShipped.addTarget(self, action: #selector(startShippedProcess), for: .touchUpInside)
            cell.addSubview(trackShipped)
            
            if  let uid = Auth.auth().currentUser?.uid,
                let customer = self.customer {
                if uid == customer {
                    trackShipped.setTitleColor(.label, for: .normal)
                    trackShipped.frame.size.width = (self.summaryView!.frame.size.width-30-15)/2
                    let markRecieved = UIButton.init(frame: CGRect.init(x: trackShipped.frame.maxX+15, y: 15, width: trackShipped.frame.size.width, height: 40))
                    markRecieved.setTitle("MARK RECEIVED", for: .normal)
                    markRecieved.titleLabel?.font = buttonFont
                    markRecieved.backgroundColor = .systemRed
                    markRecieved.layer.cornerRadius = 5
                    markRecieved.layer.masksToBounds = true
                    markRecieved.addTarget(self, action: #selector(startMarkRecieved), for: .touchUpInside)
                    cell.addSubview(markRecieved)
                }
            }
            
        default:
            cell = UITableViewCell.init(style: .default, reuseIdentifier: nil)
            cell.textLabel?.textColor = .label
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.font = UIFont.systemFont(ofSize: 12, weight: .bold)
            if identifier! == .OfferCashCompletion {
                cell.textLabel?.text = "THIS IS A CASH SALE"
            } else if identifier! == .OfferCardCompletion {
                cell.textLabel?.text = "THIS IS A CARD TRANSACTION"
            } else if identifier! == .OfferPaid {
                cell.textLabel?.text = "PAYMENT SUCCESSFUL. AWAITING SHIPMENT"
            } else if identifier! == .OfferShippingAddress {
                cell.textLabel?.numberOfLines = 0
                cell.textLabel?.text = "\(self.shipping_name?.uppercased() ?? "UNKNOWN NAME")\n\(self.shipping_address?.uppercased() ?? " UNKNOWN ADDRESS")"
            } else if identifier! == .OfferShipped {
                cell.textLabel?.text = "PACKAGE SHIPPED"
            } else if identifier! == .OfferComplete {
                cell.textLabel?.text = "THIS SALE IS COMPLETE"
            }
            cell.selectionStyle = .none
        }
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        return cell
    }
    
    @objc func startApplePayProcess() {
        self.delegate?.presentApplePay()
    }
    
    @objc func startShippedProcess() {
        self.delegate?.showMarkShippedAddTrackingNumber({ (trackingNumber) in
            var data = [String:Any]()
            data["shipped"] = true
            if let trackingNumber = trackingNumber {
                data["tracking_number"] = trackingNumber
            }
            self.markShipped(data)
        })
    }
    
    @objc func startMarkRecieved() {
        self.markReceived()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch self.summarySections?.identiferForSectionAtIndex(indexPath.row) {
        case .OfferAmount:
            for view in tableView.cellForRow(at: indexPath)!.subviews {
                if let tf = view as? UITextField {
                    tf.becomeFirstResponder()
                }
            }
        case .OfferRecieptPreview:
            self.retrievePaymentInformation { (transaction) in
                if let tx = transaction {
                    self.delegate?.presentTransactionView(tx)
                }
                
            }
        default:
            break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    @objc func tableSubmitOffer() {
        if let offerAmount = offerComposerAmount {
            self.submitOffer(offerAmount, offerComposerIsLocal ?? false, offerComposerIsCash ?? false)
        }
    }
    
    @objc func tableRespondToOffer(_ sender: UIButton) {
        if sender.tag == 9 {
            self.acceptOffer()
        } else {
            self.deleteOffer()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let identifier = self.summarySections!.identiferForSectionAtIndex(indexPath.row)
        if identifier == .OfferAmount || identifier == .OfferLocal || identifier == .OfferCash {
            return 60
        } else if identifier == .OfferSellerAccept || identifier == .OfferSubmit || identifier == .OfferCustomerCardPayment || identifier == .OfferSellerMarkShipped || identifier == .OfferTrackShipped {
            return 70
        } else if identifier == .OfferPending || identifier == .OfferNotSubmitted {
            return 80
        } else if identifier == .OfferCashCompletion || identifier == .OfferCardCompletion || identifier == .OfferPaid || identifier == .OfferShipped || identifier == .OfferComplete {
            return 30
        } else if identifier == .OfferSellerMarkComplete {
            return 90
        } else if identifier == .OfferShippingAddress {
            return 100
        } else if identifier == .OfferRecieptPreview {
            return 50
        }
        return 0
    }
    
    @objc func toggleLocal() {
        if self.offerComposerIsLocal != nil {
            self.offerComposerIsLocal?.toggle()
        } else {
            self.offerComposerIsLocal = true
        }
        self.delegate?.offerUpdated()
    }
    
    @objc func toggleCash() {
        if self.offerComposerIsCash != nil {
            self.offerComposerIsCash?.toggle()
        } else {
            self.offerComposerIsCash = true
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
        self.sender = qds.data()["sender"] as! String
        self.text = qds.data()["text"] as! String
        if let timestamp = (qds.data()["timestamp"] as? Timestamp) {
            self.timestamp = timestamp.dateValue()
        }
    }
    
    func getFrame(width: inout CGFloat) -> CGSize {
        if size == nil {
            let calculateWidth = self.text.width(withConstrainedHeight: 100, font: UIFont.systemFont(ofSize: 18))
            let height = self.text.height(withConstrainedWidth: width, font: UIFont.systemFont(ofSize: 18))
            if calculateWidth > width {
                self.size = CGSize.init(width: width+10, height: height+10)
            } else {
                self.size = CGSize.init(width: calculateWidth+20, height: height+10)
            }
        }
        return self.size!
    }
}
