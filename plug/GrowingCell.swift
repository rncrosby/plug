//
//  GrowingCell.swift
//  GrowingCellTextView
//
//  Created by SwiftDevCenter on 12/03/19.
//  Copyright © 2019 SwiftDevCenter. All rights reserved.
//

import UIKit

protocol GrowingCellProtocol: class {
    func updateHeightOfRow(_ cell: GrowingCell, _ textView: UITextView)
}

class GrowingCell: UITableViewCell {
    
    weak var cellDelegate: GrowingCellProtocol?
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var placeholder: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        textView.delegate = self
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

extension GrowingCell: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        if let delegate = cellDelegate {
            delegate.updateHeightOfRow(self, textView)
        }
    }
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        self.placeholder.isHidden = true
        return true
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            self.placeholder.isHidden = !(textView.text.isEmpty)
            textView.resignFirstResponder()
            return false
        }
        return true
    }
}
