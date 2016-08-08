//
//  pokemenCellTableViewCell.swift
//  PokeInfo
//
//  Created by Nicholas D'hondt on 31/07/16.
//  Copyright © 2016 Nicholas D'hondt. All rights reserved.
//

import UIKit

class pokemenCellTableViewCell: UITableViewCell {

    @IBOutlet weak var pokemonName: UILabel!
    @IBOutlet weak var ivs: UILabel!
    @IBOutlet weak var perfection: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
