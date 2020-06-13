//
//  AdicionarContatosViewController.swift
//  WhatsApp
//
//  Created by Fagner Caetano on 30/05/20.
//  Copyright © 2020 Fagner Caetano. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class AdicionarContatosViewController: UIViewController {
    
    var auth: Auth!
    var firestore: Firestore!
    var idUsuarioLogado: String!
    var emailUsuarioLogado: String!
    
    
    @IBOutlet weak var buscaEmailTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        auth = Auth.auth()
        firestore = Firestore.firestore()
        
        guard let currentUser = auth.currentUser else { return }
        self.idUsuarioLogado = currentUser.uid
        self.emailUsuarioLogado = currentUser.email
        
        // Do any additional setup after loading the view.
    }
    
    @IBAction func adicionarButton(_ sender: Any) {
        guard let emailDigitado = buscaEmailTextField.text else { return }
        if emailDigitado == self.emailUsuarioLogado {
            let alerta = Alerta(title: "Ocorreu um erro", message: "Está buscando seu proprio email?")
            self.present(alerta.getAlert(), animated: true, completion: nil)
            return
        }
        firestore.collection("usuarios").whereField("email", isEqualTo: emailDigitado).getDocuments { (snapshotResultado, erro) in
            guard let totalItens = snapshotResultado?.count else { return }
            if totalItens == 0 {
                let alerta = Alerta(title: "Nada encontrado", message: "Nenhum contato encontrado com esse email.")
                self.present(alerta.getAlert(), animated: true, completion: nil)
                return
            }
            guard let snapshot = snapshotResultado else { return }
            for document in snapshot.documents {
                let dados = document.data()
                self.salvarContato(dadosContato: dados)
                
            }
        }
        
    }
    
    func salvarContato(dadosContato: Dictionary <String, Any>) {
        guard let idUsuarioContato = dadosContato["idUsuario"] else { return }
        firestore.collection("usuarios").document(idUsuarioLogado).collection("contatos")
            .document(idUsuarioContato as! String).setData(dadosContato) { (erro) in
                if erro == nil {
                    self.navigationController?.popViewController(animated: true)
                }
        }
    }
}
