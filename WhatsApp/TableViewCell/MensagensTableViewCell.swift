//
//  MensagensTableViewCell.swift
//  WhatsApp
//
//  Created by Fagner Caetano on 01/06/20.
//  Copyright © 2020 Fagner Caetano. All rights reserved.
//

import UIKit

class MensagensTableViewCell: UITableViewCell {

    @IBOutlet weak var mensagemEnviadaLabel: UILabel!
    @IBOutlet weak var mensagemRecebidaLabel: UILabel!
    @IBOutlet weak var imagemEnviadaView: UIImageView!
    @IBOutlet weak var imagemRecebidaView: UIImageView!
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
