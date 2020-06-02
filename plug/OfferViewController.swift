//
//  MakeOfferViewController.swift
//  plug
//
//  Created by Robert Crosby on 5/26/20.
//  Copyright © 2020 Robert Crosby. All rights reserved.
//

import UIKit
import Firebase
import Stripe
import Contacts
import SafariServices

extension OfferViewController: OfferDelegate {
    
    func offerDeclined() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func presentTransactionView(_ transaction: Transaction) {
        let transactionViewController = IndividualTransactionViewController.init(transaction)
        self.present(transactionViewController, animated: true, completion: nil)
    }
    
    func showMarkShippedAddTrackingNumber(_ complete: @escaping (String?) -> ()) {
        let alert = UIAlertController.init(title: "Attach Tracking Number", message: nil, preferredStyle: .alert)
        alert.addTextField { (textfield) in
            textfield.placeholder = "Tracking Number"
        }
        alert.addAction(UIAlertAction.init(title: "Mark Shipped", style: .default, handler: { (action) in
            if let tf = alert.textFields?.first {
                complete(tf.text)
            } else {
                complete(nil)
            }
            alert.dismiss(animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func presentApplePay() {
        let merchantIdentifier = "merchant.plug.prettyboy"
        let paymentRequest = Stripe.paymentRequest(withMerchantIdentifier: merchantIdentifier, country: "US", currency: "USD")
        if  let total = self.offer?.amount,
            let local = self.offer?.local {
            if !(local) {
                paymentRequest.requiredShippingContactFields = [PKContactField.name,PKContactField.postalAddress]
            }
            paymentRequest.paymentSummaryItems = [
                // The final line should represent your company;
                // it'll be prepended with the word "Pay" (i.e. "Pay iHats, Inc $50")
                PKPaymentSummaryItem(label: "Pay PrettyBoy&Co", amount: NSDecimalNumber.init(value: total)),
            ]
            if let applePayContext = STPApplePayContext(paymentRequest: paymentRequest, delegate: self) {
                // Present Apple Pay payment sheet
                applePayContext.presentApplePay(on: self)
            } else {
                // There is a problem with your Apple Pay configuration
            }

        }
    }
    
    func offerUpdated() {
        print("offer updated")
        self.offer?.createSummaryView(width: self.view.frame.size.width)
        self.view.addSubview(self.offer!.summaryView!)
        self.view.bringSubviewToFront(self.offer!.summaryView!)
        self.table?.contentInset.top = self.offer!.summaryView!.frame.size.height
    }
    
    func messageInserted(index: Int?) {
        if let index = index {
            self.sections.updateSection(title: .OfferMessages, rows: index+1)
            let indexPath = IndexPath.init(row: index, section: 0)
            self.table?.beginUpdates()
            self.table?.insertRows(at: [indexPath], with: .fade)
            self.table?.endUpdates()
            self.table?.scrollToRow(at: indexPath, at: .bottom, animated: true)
        } else {
            if let count = self.offer?.messages?.count {
                self.sections.updateSection(title: .OfferMessages, rows: count)
                self.table?.reloadData()
                if count > 0 {
                    self.table?.scrollToRow(at: IndexPath.init(row: count-1, section: 0), at: .bottom, animated: true)
                }
                
            }
            
//            self.table?.beginUpdates()
//            self.table?.insertSections(IndexSet.init(integer: 0), with: .fade)
//            self.table?.endUpdates()
        }
    }
}

class OfferViewController: UIViewController, UIAdaptivePresentationControllerDelegate {
    
    var currentOffer = false
    var offer:Offer?
    let item:Item
    let sections = SectionController()
    var table:UITableView?
    
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        if keyboardHeight == nil {
            return true
        }
        return false
    }
    
    init(newOffer: inout Item) {
        self.item = newOffer
        super.init(nibName: nil, bundle: nil)
        createPreliminaryOffer()
    }
    
    init(presentOffer: inout Item) {
        self.item = presentOffer
        self.offer = Offer.init(self.item.offerReference!)
        super.init(nibName: nil, bundle: nil)
        self.offer?.delegate = self
    }
    
    init(offer: inout Offer) {
        self.currentOffer = true
        self.item = Item.init(offer.item!)
        self.offer = offer
        super.init(nibName: nil, bundle: nil)
        self.offer?.delegate = self
    }
    
    func createPreliminaryOffer() {
        if  let uid = Auth.auth().currentUser?.uid,
            let itemID = self.item.id,
            let itemName = self.item.name,
            let itemSeller = self.item.seller {
            let reference = Firestore.firestore().collection("offers").document()
            reference.setData([
                "itemName" : itemName,
                "date"      : FieldValue.serverTimestamp(),
                "item"      : itemID,
                "customer"  : uid,
                "seller"    : itemSeller,
                "parties"   : [uid, itemSeller],
                "complete"  : false,
                "modified"  : Timestamp.init(date: Date())
            ]) { (error) in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                self.item.offerReference = reference
                self.offer = Offer.init(preliminary: reference, amount: self.item.cost ?? 0)
                self.offer?.offerComposerIsLocal = true
                self.offer?.offerComposerIsCash = true
                self.offer?.delegate = self
                if self.isViewLoaded {
                    self.updateOffer()
                }
                
            }
        }
    }
    
    var offerListening = false
    
    func updateOffer() {
        if currentOffer && (offer?.isPopulated ?? false) && (offer?.messageListener != nil) {
            self.sections.updateSection(title: .OfferMessages, rows: self.offer?.messages?.count ?? 0)
            self.table?.reloadData()
            self.offerUpdated()
        } else if (offer != nil) && (offerListening == false){
            print("updating offer")
            self.offerListening = true
            self.offer!.updateData()
            self.offer?.updateMessages()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    var messageWidth = CGFloat(0)

    override func viewDidLoad() {
        self.view.backgroundColor = .secondarySystemGroupedBackground
        self.messageWidth = self.view.frame.size.width-100
        self.presentationController?.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        self.table = UITableView.init(frame: self.view.bounds, style: .grouped)
        self.table?.delegate = self
        self.table?.dataSource = self
        self.table?.separatorStyle = .none
        self.table?.showsVerticalScrollIndicator = false
        self.view.addSubview(self.table!)
        super.viewDidLoad()
        updateOffer()
        createBottomChatField()
        
    }
    
    var keyboardHeight:CGFloat?
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.messageComposeView.frame.origin.y == originalBottomChatY {
                keyboardHeight = keyboardSize.height
                self.messageComposeView.frame.origin.y -= keyboardHeight!
                self.table?.frame.size.height -= keyboardHeight!
                if self.offer?.messages != nil {
                    let count = self.offer!.messages?.count ?? 0
                    if count > 0 {
                        self.table?.scrollToRow(at: IndexPath.init(row: count-1, section: 0), at: .bottom, animated: true)
                    }
                }
            }
        }
    }

    @objc func keyboardWillHide(notification: NSNotification?) {
        self.messageComposeView.frame.origin.y += keyboardHeight!
//        self.table?.contentInset.bottom = self.view.safeAreaInsets.bottom + self.messageComposeView.frame.size.height
        self.table?.frame.size.height += keyboardHeight!
        self.keyboardHeight = nil
    }
    
    var textviewHeight = CGFloat(0)
    var originalBottomChatY = CGFloat(0)
    var messageComposeView = UIView()
    var messageComposeField = UITextView()
    var sendButton = UIButton()
    
    func createBottomChatField() {
        if let bottomBarHeight = UIApplication.shared.windows.first?.safeAreaInsets.bottom {
            
            let margin = CGFloat(15)
            textviewHeight = "Message".height(withConstrainedWidth: self.view.frame.size.width-30, font: UIFont.systemFont(ofSize: 18))+20
            originalBottomChatY = self.view.frame.size.height-bottomBarHeight-(margin*2)-textviewHeight-30
            messageComposeView.frame = CGRect.init(origin: CGPoint.init(x: 0, y: originalBottomChatY), size: CGSize.init(width: self.view.frame.size.width, height: self.view.frame.size.height/2))
            messageComposeField.frame = CGRect.init(origin: CGPoint.init(x: 15, y: margin), size: CGSize.init(width: messageComposeView.frame.size.width-margin-margin-30-15, height: textviewHeight))
            messageComposeField.font = UIFont.systemFont(ofSize: 18)
            messageComposeField.isScrollEnabled = false
            messageComposeField.contentInset = UIEdgeInsets.init(top: 10, left: 10, bottom: 10, right: 10)
            messageComposeField.text = "Message"
            messageComposeField.textColor = .placeholderText
            messageComposeField.backgroundColor = .secondarySystemGroupedBackground
            messageComposeField.layer.cornerRadius = messageComposeField.frame.size.height/2
            messageComposeField.delegate = self
            messageComposeField.layer.masksToBounds = true
            
            messageComposeView.addSubview(messageComposeField)
            
            sendButton.frame = CGRect.init(origin: CGPoint.init(x: messageComposeField.frame.maxX+7.5+5, y: messageComposeField.frame.origin.y+5), size: CGSize.init(width: textviewHeight-10, height: textviewHeight-10))
            sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
            sendButton.backgroundColor = .systemGray3
            sendButton.tag = 0
            sendButton.setImage(UIImage.init(systemName: "arrow.up"), for: .normal)
            sendButton.imageEdgeInsets = UIEdgeInsets.init(top: 7, left: 7, bottom: 7, right: 7)
            sendButton.imageView?.tintColor = .white
            sendButton.layer.cornerRadius = sendButton.frame.size.width/2
            sendButton.layer.masksToBounds = true
            messageComposeView.addSubview(sendButton)
            
            self.view.addSubview(messageComposeView)
            self.table?.contentInset.bottom = textviewHeight + 65
        }
    }
    
    @objc func sendMessage() {
        self.offer?.sendMessage(self.messageComposeField.text)
        self.messageComposeField.text = ""
        
    }
}

extension OfferViewController: UITableViewDataSource,UITableViewDelegate,UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == "Message" {
            textView.text = ""
        }
        textView.textColor = .label
    }
    
//    func textViewDidEndEditing(_ textView: UITextView) {
//        if textView.text.isEmpty {
//            textView.text = "Message"
//            textView.textColor = .placeholderText
//        }
//    }
    
    func textViewDidChange(_ textView: UITextView) {
        if !(textView.text.isEmpty) {
            if sendButton.tag != 1 {
                sendButton.backgroundColor = .systemRed
            }
            let height = textView.text.height(withConstrainedWidth: textView.frame.size.width-(2*textView.contentInset.left)-5, font: textView.font!)+20
            if height != textviewHeight {
                let difference = height-textviewHeight
                originalBottomChatY = originalBottomChatY-difference
                textviewHeight = height
                UIView.animate(withDuration: 0.15) {
                    textView.frame.size.height = self.textviewHeight
                    self.messageComposeView.frame.origin.y-=difference
                }
            }
        } else {
            self.messageComposeField.text = "Message"
            self.messageComposeField.textColor = .placeholderText
            let height = textView.text.height(withConstrainedWidth: textView.frame.size.width-(2*textView.contentInset.left)-5, font: textView.font!)+20
            if height != textviewHeight {
                let difference = height-textviewHeight
                originalBottomChatY = originalBottomChatY-difference
                textviewHeight = height
                UIView.animate(withDuration: 0.15) {
                    textView.frame.size.height = self.textviewHeight
                    self.messageComposeView.frame.origin.y-=difference
                }
            }
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            if textView.text.isEmpty {
                textView.text = "Message"
                textView.textColor = .placeholderText
            }
            return false
        } else if text.isEmpty && textView.text.count == 1 {
                sendButton.backgroundColor = .systemGray3
        }
        return true
    }
    
    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return self.sections.count
    }
    
    

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.sections.rowsInSectionAtIndex(section)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let message = self.offer?.messages?[indexPath.row] {
//            if indexPath.row+1 < self.offer!.messages!.count {
//                if self.offer!.messages![indexPath.row+1].amSender {
//                    return message.getFrame(width: &self.messageWidth).height+2.5
//                }
//            }
            return message.getFrame(width: &self.messageWidth).height+5
        }
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = self.sections.identiferForSectionAtIndex(indexPath.section)
        switch identifier {
        case .OfferMessages:
            let cell = UITableViewCell.init(style: .default, reuseIdentifier: nil)
            cell.selectionStyle = .none
            cell.backgroundColor = .clear
            if let message = self.offer?.messages?[indexPath.row] {
                let textview = UITextView.init(frame: CGRect.init(origin: CGPoint.init(x: 15, y: 2.5), size: message.getFrame(width: &self.messageWidth)))
                textview.textContainerInset = UIEdgeInsets.init(top: 5, left: 5, bottom: 5, right: 5)
                textview.isScrollEnabled = false
                textview.text = message.text
                textview.font = UIFont.systemFont(ofSize: 18)
                
                textview.layer.cornerRadius = 14
                textview.layer.masksToBounds = true
                
                if message.amSender {
                    textview.frame.origin.x = self.view.frame.size.width-15-textview.frame.size.width
                    textview.backgroundColor = .systemRed
                    textview.textColor = .white
                } else {
                    textview.backgroundColor = .secondarySystemGroupedBackground
                    textview.textColor = .label
                }
                
                cell.addSubview(textview)
            }
            
            return cell
        default:
            return UITableViewCell()
        }
    }
}

extension OfferViewController: STPApplePayContextDelegate {
    func applePayContext(_ context: STPApplePayContext, didCreatePaymentMethod paymentMethod: STPPaymentMethod, paymentInformation: PKPayment, completion: @escaping STPIntentClientSecretCompletionBlock) {
        if let contactName = paymentInformation.shippingContact?.name,
            let contactAddress = paymentInformation.shippingContact?.postalAddress {
            let name = PersonNameComponentsFormatter.localizedString(from: contactName, style: .default, options: [])
            let address = CNPostalAddressFormatter.string(from: contactAddress, style: .mailingAddress)
            getPaymentIntent(name: name, address: address, method: paymentMethod.stripeId) { (secret) in
                completion(secret, nil)
            }
        } else {
            getPaymentIntent(name: nil, address: nil, method: paymentMethod.stripeId) { (secret) in
                completion(secret, nil)
            }
        }
    }

    func applePayContext(_ context: STPApplePayContext, didCompleteWith status: STPPaymentStatus, error: Error?) {
          switch status {
        case .success:
            
            break
        case .error:
            // Payment failed, show the error
            break
        case .userCancellation:
            // User cancelled the payment
            break
        @unknown default:
            print("yo")
            print(error?.localizedDescription ?? "error")
//            fatalError()
        }
    }
    
    func getPaymentIntent(name: String?, address: String?, method: String, completion: @escaping (String?) -> ()) {
        var offerPaymentData = [String:Any]()
        offerPaymentData["offer"] = self.offer!.id
        offerPaymentData["item"] = self.item.id!
        offerPaymentData["method"] = method
        if  let name = name,
            let address = address {
            offerPaymentData["shipping_name"] = name
            offerPaymentData["shipping_address"] = address
        }
        Functions.functions().httpsCallable("purchaseItem").call(offerPaymentData) { (result, error) in
            if let error = error as NSError? {
                if error.domain == FunctionsErrorDomain {
                    let message = error.localizedDescription
                    print("ERROR: \(message)")
                    completion(nil)
                    return
                }
            }
            if let data = result?.data as? String {
                completion(data)
                return
            }
        }
    }
}
