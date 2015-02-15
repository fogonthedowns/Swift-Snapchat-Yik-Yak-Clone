//
//  DistrictTableViewCell.swift
//  slide
//
//  Created by Justin Zollars on 2/13/15.
//  Copyright (c) 2015 rmb. All rights reserved.
//

import UIKit

class DistrictTableViewCell: UITableViewCell {
    var hood:NSString = ""
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var coverPhoto: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
