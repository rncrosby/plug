//
//  TableViewCell.swift
//  plug
//
//  Created by Robert Crosby on 5/27/20.
//  Copyright © 2020 Robert Crosby. All rights reserved.
//

import UIKit

class OfferCell: UITableViewCell {
    
    @IBOutlet weak var itemImageView:UIImageView!
    
    @IBOutlet weak var itemName:UITextView!
    @IBOutlet weak var offerStatus:UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
