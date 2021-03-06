//
//  VideoCellTableViewCell.swift
//  slide
//
//  Created by Justin Zollars on 1/31/15.
//  Copyright (c) 2015 rmb. All rights reserved.
//

import UIKit

class VideoCellTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var videoPreview: UIImageView!
    @IBOutlet weak var commentCount: UILabel!
    @IBOutlet weak var starImage: UIImageView!
    @IBOutlet weak var voteCount: UILabel!
    
    @IBOutlet weak var userVote: UIButton!
    var video: NSString!
    var videoModel: VideoModel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    

}
