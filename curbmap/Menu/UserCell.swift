//
//  UserTableViewCell.swift
//  curbmap
//
//  Created by Eli Selkin on 12/5/17.
//  Copyright © 2017 Eli Selkin. All rights reserved.
//

import UIKit

class UserCell: UITableViewCell {
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var score: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
