//
//  ConversasViewController.swift
//  WhatsApp
//
//  Created by Fagner Caetano on 03/06/20.
//  Copyright © 2020 Fagner Caetano. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class ConversasViewController: UIViewController {
    
    var auth: Auth!
    var firestore: Firestore!
    var listaConversas: [Dictionary<String, Any>] = []
    var conversasListener: ListenerRegistration!

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        auth = Auth.auth()
        firestore = Firestore.firestore()


    }
    
    override func viewWillAppear(_ animated: Bool) {
        addListenerRecuperarConversa()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        conversasListener.remove()
    }
    
    func addListenerRecuperarConversa() {
        self.listaConversas.removeAll()
        guard let idUsuarioLogado = auth.currentUser?.uid else {return}
        conversasListener = firestore.collection("conversas").document(idUsuarioLogado).collection("ultimas_conversas").addSnapshotListener { (querySnapshot, erro) in
            
            
            if erro == nil {
                guard let snapshot = querySnapshot else { return }
                for document in snapshot.documents {
                    let dados = document.data()
                    self.listaConversas.append(dados)
                }
                self.tableView.reloadData()
            }
        }
    }

}

extension ConversasViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.listaConversas.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let celula = tableView.dequeueReusableCell(withIdentifier: "celulaMensagens", for: indexPath) as! ConversasTableViewCell
        let dados = listaConversas[indexPath.row]
        let nome = dados["nomeUsuario"] as? String
        let ultimaMsg = dados["ultimaMsg"] as? String
        
        if let urlFotoContato = dados["urlFotoContato"] as? String {
            celula.imagemContatoView.sd_setImage(with: URL(string: urlFotoContato), completed: nil)
        } else {
            celula.imagemContatoView.image = UIImage(named: "imagem-pefil")
        }
        
        celula.nomeContatoLabel.text = nome
        celula.ultimaMsgLabel.text = ultimaMsg
        
        return celula
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        let conversa = self.listaConversas[indexPath.row]
        
        guard let id = conversa["idDestinatario"] as? String else { return }
        guard let nomeUsuario = conversa["nomeUsuario"] as? String else { return }
        guard let urlFotoUsuario = conversa["urlFotoContato"] as? String else { return }
        
        let contato: Dictionary<String, Any> = [
            "idUsuario" : id,
            "nome" : nomeUsuario,
            "urlImagem" : urlFotoUsuario
        ]
        
        self.performSegue(withIdentifier: "iniciarConversa", sender: contato)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "iniciarConversa" else { return }
        let viewDestino = segue.destination as! MensagensViewController
        viewDestino.contato = sender as? Dictionary
    }
    
}
