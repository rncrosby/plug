//
//  MakeOfferViewController.swift
//  plug
//
//  Created by Robert Crosby on 5/26/20.
//  Copyright © 2020 Robert Crosby. All rights reserved.
//

import UIKit
import Firebase

extension OfferViewController: OfferDelegate {
    
    
    func offerUpdated() {
        self.offer?.createSummaryView(width: self.view.frame.size.width)
        self.table?.reloadData()
    }
    
    func messageInserted(index: Int?) {
        if let index = index {
            self.sections.updateSection(title: .OfferMessages, rows: index+1)
            self.table?.beginUpdates()
            self.table?.insertRows(at: [IndexPath.init(row: index, section: 0)], with: .fade)
            self.table?.endUpdates()
        } else {
            self.sections.updateSection(title: .OfferMessages, rows: self.offer!.messages!.count)
            self.table?.beginUpdates()
            self.table?.insertSections(IndexSet.init(integer: 0), with: .fade)
            self.table?.endUpdates()
        }
    }
}

class OfferViewController: UIViewController, UIAdaptivePresentationControllerDelegate {
    
    var offer:Offer?
    let item:Item
    let sections = SectionController()
    var table:UITableView?
    
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        if keyboardHeight == nil {
            self.offer?.listener?.remove()
            self.offer?.listener = nil
            self.offer?.messageListener?.remove()
            self.offer?.messageListener = nil
            self.offer?.delegate = nil
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
        self.item = Item.init(offer.item!)
        self.offer = offer
        super.init(nibName: nil, bundle: nil)
        self.offer?.delegate = self
    }
    
    func createPreliminaryOffer() {
        if  let uid = Auth.auth().currentUser?.uid,
            let itemID = self.item.id,
            let itemSeller = self.item.seller {
            let reference = Firestore.firestore().collection("offers").document()
            reference.setData([
                "date"      : FieldValue.serverTimestamp(),
                "item"      : itemID,
                "customer"  : uid,
                "seller"    : itemSeller
            ]) { (error) in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                self.item.offerReference = reference
                self.offer = Offer.init(preliminary: reference, amount: self.item.cost ?? 0)
                self.offer?.delegate = self
                if self.isViewLoaded {
                    self.updateOffer()
                }
                
            }
        }
    }
    
    var offerListening = false
    
    func updateOffer() {
        if (offer != nil) && (offerListening == false) {
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
//                self.table?.contentInset.bottom = self.table!.contentInset.bottom + keyboardSize.height + messageComposeView.frame.size.height
                self.table?.frame.size.height -= keyboardHeight!
                if let maxIndex = self.offer?.messages?.count {
                    self.table?.scrollToRow(at: IndexPath.init(row: maxIndex-1, section: 0), at: .bottom, animated: true)
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
            textviewHeight = "Message".height(withConstrainedWidth: self.view.frame.size.width-30, font: UIFont.systemFont(ofSize: 14))+20
            originalBottomChatY = self.view.frame.size.height-bottomBarHeight-(margin*2)-textviewHeight-30
            messageComposeView.frame = CGRect.init(origin: CGPoint.init(x: 0, y: originalBottomChatY), size: CGSize.init(width: self.view.frame.size.width, height: self.view.frame.size.height/2))
            let blur = UIVisualEffectView.init(effect: UIBlurEffect.init(style: .prominent))
            blur.frame = messageComposeView.bounds
            messageComposeView.addSubview(blur)
            messageComposeField.frame = CGRect.init(origin: CGPoint.init(x: 15, y: margin), size: CGSize.init(width: messageComposeView.frame.size.width-margin-margin-30-15, height: textviewHeight))
            messageComposeField.font = UIFont.systemFont(ofSize: 14)
            messageComposeField.isScrollEnabled = false
            messageComposeField.contentInset = UIEdgeInsets.init(top: 10, left: 10, bottom: 10, right: 10)
            messageComposeField.text = "Message"
            messageComposeField.textColor = .placeholderText
            messageComposeField.backgroundColor = .secondarySystemGroupedBackground
            messageComposeField.layer.cornerRadius = 10
            messageComposeField.delegate = self
            messageComposeField.layer.masksToBounds = true
            
            messageComposeView.addSubview(messageComposeField)
            
            sendButton.frame = CGRect.init(origin: CGPoint.init(x: messageComposeField.frame.maxX+7.5+5, y: messageComposeField.frame.origin.y+5), size: CGSize.init(width: textviewHeight-10, height: textviewHeight-10))
            sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
            sendButton.backgroundColor = .systemGray3
            sendButton.tag = 0
            sendButton.setImage(UIImage.init(systemName: "paperplane.fill"), for: .normal)
            sendButton.imageEdgeInsets = UIEdgeInsets.init(top: 7, left: 7, bottom: 7, right: 7)
            sendButton.imageView?.tintColor = .white
            sendButton.layer.cornerRadius = sendButton.frame.size.width/2
            sendButton.layer.masksToBounds = true
            messageComposeView.addSubview(sendButton)
            
            self.view.addSubview(messageComposeView)
            self.table?.contentInset.bottom = textviewHeight + 75
            self.table?.verticalScrollIndicatorInsets.bottom = self.table!.contentInset.bottom + 20
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
            textView.textColor = .label
        }
    }
    
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
            if indexPath.row + 1 < self.offer!.messages!.count {
                if self.offer!.messages![indexPath.row+1].amSender {
                    return message.getFrame(width: &self.messageWidth).height+2.5
                }
            }
            return message.getFrame(width: &self.messageWidth).height+10
        }
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = self.sections.identiferForSectionAtIndex(indexPath.section)
        switch identifier {
        case .OfferMessages:
            let cell = UITableViewCell.init(style: .default, reuseIdentifier: nil)
            cell.backgroundColor = .clear
            if let message = self.offer?.messages?[indexPath.row] {
                let textview = UITextView.init(frame: CGRect.init(origin: CGPoint.init(x: 15, y: 2.5), size: message.getFrame(width: &self.messageWidth)))
                textview.textContainerInset = UIEdgeInsets.init(top: 5, left: 5, bottom: 5, right: 5)
                textview.isScrollEnabled = false
                textview.text = message.text
                textview.font = UIFont.systemFont(ofSize: 14)
                
                textview.layer.cornerRadius = 12
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
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            return offer?.summaryView
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return offer?.summaryView?.frame.size.height ?? 0
        }
        return 0
    }
}
