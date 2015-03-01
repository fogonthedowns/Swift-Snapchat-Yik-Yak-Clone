//
//  HomeHeaderTableViewCell.swift
//  slide
//
//  Created by Justin Zollars on 2/28/15.
//  Copyright (c) 2015 rmb. All rights reserved.
//

import UIKit

class HomeHeaderTableViewCell: UITableViewCell {
    @IBOutlet weak var localButton: UIButton!

    @IBOutlet weak var myTagsButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
