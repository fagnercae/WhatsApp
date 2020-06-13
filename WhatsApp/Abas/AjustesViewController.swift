//
//  AjustesViewController.swift
//  WhatsApp
//
//  Created by Fagner Caetano on 30/05/20.
//  Copyright © 2020 Fagner Caetano. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import SDWebImage


class AjustesViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var auth: Auth!
    var storage: Storage!
    var firestore: Firestore!
    
    var imagePicker = UIImagePickerController()
    var idUsuario: String!
    
    @IBOutlet weak var imagemView: UIImageView!
    @IBOutlet weak var nomeLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        auth = Auth.auth()
        storage = Storage.storage()
        firestore = Firestore.firestore()
        
        imagePicker.delegate = self
        
        //recuperar id usuario
        if let id = auth.currentUser?.uid {
            self.idUsuario = id
        }
        
        recuperaDados()
        
    }
    
    func recuperaDados() {
        let usuarioRef = firestore.collection("usuarios").document(idUsuario)
        usuarioRef.getDocument { (snapshot, erro) in
            guard let dados = snapshot?.data() else { return }
            let nomeUsuario = dados["nome"] as? String
            let emailUsuario = dados["email"] as? String
            guard let imagemPerfil = dados["urlImagem"] as? String else { return }
            
            self.nomeLabel.text = nomeUsuario
            self.emailLabel.text = emailUsuario
            self.imagemView.sd_setImage(with: URL(string: imagemPerfil))
        }
    
    }
    
    @IBAction func alteraImagemButton(_ sender: Any) {
        showActionSheet()
    }
    
    @IBAction func logoutButton(_ sender: Any) {
        do {
            try auth.signOut()
        } catch {
            let alerta = Alerta(title: "Feito", message: "Deslogado com sucesso.")
            present(alerta.getAlert(), animated: true, completion: nil)
        }
        
    }
    
    func camera()
    {
        
        imagePicker.delegate = self;
        imagePicker.sourceType = UIImagePickerController.SourceType.camera
        
        self.present(imagePicker, animated: true, completion: nil)
        
    }
    
    func photoLibrary()
    {
        
        imagePicker.delegate = self;
        imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
        
        self.present(imagePicker, animated: true, completion: nil)
        
    }
    
    func showActionSheet() {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertController.Style.actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: UIAlertAction.Style.default, handler: { (alert:UIAlertAction!) -> Void in
            self.camera()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Galeria", style: UIAlertAction.Style.default, handler: { (alert:UIAlertAction!) -> Void in
            self.photoLibrary()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancelar", style: UIAlertAction.Style.cancel, handler: nil))
        
        self.present(actionSheet, animated: true, completion: nil)
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let imagemSelecionada = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        
        self.imagemView.image = imagemSelecionada
        
        let imagens = storage.reference().child("imagens")
        if let imagemUpload = imagemSelecionada.jpegData(compressionQuality: 0.1) {
            
            if let usuarioLogado = auth.currentUser {
                let idUsuario = usuarioLogado.uid
                let nomeImagem = "\(idUsuario).jpg"
                let imagemPerfilReferencia = imagens.child("perfil").child(nomeImagem)
                imagemPerfilReferencia.putData(imagemUpload, metadata: nil) { (metaData, erro) in
                    if erro == nil {
                        imagemPerfilReferencia.downloadURL { (url, erro) in
                            if let urlImagem = url?.absoluteString {
                                self.firestore.collection("usuarios").document(idUsuario).updateData([
                                    "urlImagem" : urlImagem
                                ])
                                print(urlImagem)
                            }
                        }
                        print("Sucesso ao upar imagem")
                    } else {
                        print("Erro ao upar imagem")
                    }
                }
                
            }
        }
        
        self.imagePicker.dismiss(animated: true, completion: nil)
        
        
    }
}
