//
//  ContatosViewController.swift
//  WhatsApp
//
//  Created by Fagner Caetano on 30/05/20.
//  Copyright © 2020 Fagner Caetano. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import SDWebImage
import IQKeyboardManagerSwift

class ContatosViewController: UIViewController {
    
    var firestore: Firestore!
    var auth: Auth!
    var idUsuarioLogado: String!
    var listaContatos: [Dictionary <String, Any>] = []
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBarContatos: UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        auth = Auth.auth()
        firestore = Firestore.firestore()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        
        guard let id = auth.currentUser?.uid else { return }
        self.idUsuarioLogado = id
        tableView.keyboardDismissMode = UIScrollView.KeyboardDismissMode.onDrag
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        recuperarContatos()
    }
    
    @IBAction func unwindToContatosView(_ unwindSegue: UIStoryboardSegue) {
        //let sourceViewController = unwindSegue.source
        // Use data from the view controller which initiated the unwind segue
    }
    
    func recuperarContatos() {
        self.listaContatos.removeAll()
        firestore.collection("usuarios").document(idUsuarioLogado).collection("contatos").getDocuments { (snapshotResultado, erro) in
            guard let snapshot = snapshotResultado else { return }
            for document in snapshot.documents {
                let dadosContatos = document.data()
                self.listaContatos.append(dadosContatos)
            }
            self.tableView.reloadData()
        }
        
    }
    
}

extension ContatosViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let totalContatos = self.listaContatos.count
        
        if totalContatos == 0 {
            return 1
        }
        return totalContatos
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let celula = tableView.dequeueReusableCell(withIdentifier: "celulaContatos", for: indexPath) as! ContatoTableViewCell
        
        let totalContatos = self.listaContatos.count
        
        if totalContatos != 0 {
            celula.textLabel?.isHidden = true
            let dadosContato = self.listaContatos[indexPath.row]
            
            celula.nomeContatoLabel.text = dadosContato["nome"] as? String
            celula.emailContatoLabel.text = dadosContato["email"] as? String
            if let imagemPerfil = dadosContato["urlImagem"] as? String {
                celula.imagemContato?.sd_setImage(with: URL(string: imagemPerfil), completed: nil)
            } else {
                celula.imagemContato.image = UIImage(named: "imagem-perfil")
            }
        } else {
            celula.textLabel?.text = "Você não possui contatos..."
        }
        return celula
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        let contatos = self.listaContatos[indexPath.row]
        self.tableView.reloadData()
        self.performSegue(withIdentifier: "segueConversa", sender: contatos)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "segueConversa" else { return }
        let viewDestino = segue.destination as! MensagensViewController
        viewDestino.contato = sender as? Dictionary
    }
    
}

extension ContatosViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard let nomeContatoPesquisado = searchBar.text else { return }
        if nomeContatoPesquisado != "" {
            pesquisarContato(textoPesquisado: nomeContatoPesquisado)
        }; if searchText == "" {
            recuperarContatos()
        }
        
    }
    
    func pesquisarContato(textoPesquisado: String) {
        let listaPesquisa: [Dictionary <String, Any>] = self.listaContatos
        self.listaContatos.removeAll()
        
        for item in listaPesquisa {
            guard let nome = item["nome"] as? String else { return }
            if nome.lowercased().contains(textoPesquisado.lowercased()) {
                self.listaContatos.append(item)
            } 
        }
        self.tableView.reloadData()
    }
    
}
