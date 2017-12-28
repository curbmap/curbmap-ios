//
//  GeneralTableViewCell.swift
//  curbmap
//
//  Created by Eli Selkin on 12/5/17.
//  Copyright © 2017 Eli Selkin. All rights reserved.
//

import UIKit

class GeneralMenuCell: UITableViewCell {

    @IBOutlet weak var cellImage: UIImageView!
    @IBOutlet weak var cellTitle: UILabel!
    @IBOutlet weak var cellDescription: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
