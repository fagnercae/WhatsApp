//
//  Alerta.swift
//  WhatsApp
//
//  Created by Fagner Caetano on 28/05/20.
//  Copyright © 2020 Fagner Caetano. All rights reserved.
//

import UIKit

class Alerta {
    
    var title: String
    var message: String
    
    init(title: String, message: String) {
        self.title = title
        self.message = message
        
    }
    
    func getAlert() -> UIAlertController {
        let alerta = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let acaoAlerta = UIAlertAction(title: "Cancelar", style: .cancel, handler: nil)
        
        alerta.addAction(acaoAlerta)
        return alerta
    }
    
    
}


