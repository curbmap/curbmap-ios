//
//  ContributionCell.swift
//  curbmap
//
//  Created by Eli Selkin on 1/13/18.
//  Copyright © 2018 Eli Selkin. All rights reserved.
//

import UIKit

class ContributionCell: UITableViewCell {
    @IBOutlet weak var typeImage: UIImageView!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
