//
//  AccountTableViewCell.swift
//  Exmoney
//
//  Created by Damir Gaynetdinov on 05/03/2018.
//  Copyright © 2018 Damir Gaynetdinov. All rights reserved.
//

import UIKit

class AccountTableViewCell: UITableViewCell {

    @IBOutlet weak var AccountLbl: UILabel!
    @IBOutlet weak var BalanceLbl: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
