//
//  CommentTableViewCell.swift
//  slide
//
//  Created by Justin Zollars on 2/17/15.
//  Copyright (c) 2015 rmb. All rights reserved.
//

import UIKit

class CommentTableViewCell: UITableViewCell {
    
    @IBOutlet weak var commentBody: UILabel!

    @IBOutlet weak var commentTime: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
println("foobar")
        // Configure the view for the selected state
    }

}
