//
//  MensagensViewController.swift
//  WhatsApp
//
//  Created by Fagner Caetano on 01/06/20.
//  Copyright © 2020 Fagner Caetano. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import SDWebImage


class MensagensViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var auth: Auth!
    var storage: Storage!
    var firestore: Firestore!
    var listaMensagens: [Dictionary<String, Any>] = []
    var usuarioLogado: String!
    var contato: Dictionary<String, Any>!
    var listener: ListenerRegistration!
    var imagePicker = UIImagePickerController()
    var nameContato: String!
    var urlFotoContato: String!
    var nameContatoLogado: String!
    var urlFotoContatoLogado: String!
    
    @IBOutlet weak var tableView: UITableView!
    var mensagemTextField: UITextField!
    @IBOutlet weak var nomeContato: UILabel!
    
    lazy var bottomView: UIView = {
        
        let container: CustomView = CustomView()
        container.backgroundColor = UIColor.init(red: 0.9215, green: 0.9215, blue: 0.9215, alpha: 1)
        container.translatesAutoresizingMaskIntoConstraints = false
        
        //BOTAO ANEXO
        let anexoButton = UIButton()
        container.addSubview(anexoButton)
        anexoButton.translatesAutoresizingMaskIntoConstraints = false
        
        anexoButton.topAnchor.constraint(equalTo: container.topAnchor, constant: 8).isActive = true
        anexoButton.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8).isActive = true
        anexoButton.bottomAnchor.constraint(equalTo: container.layoutMarginsGuide.bottomAnchor, constant: 8).isActive = true
        anexoButton.widthAnchor.constraint(equalToConstant: 32).isActive = true
        anexoButton.heightAnchor.constraint(equalToConstant: 32).isActive = true
        anexoButton.setImage(UIImage(named: "arquivo_icone"), for: .normal)
        anexoButton.addTarget(self, action: #selector(showActionSheet(button:)), for: .touchUpInside)
        
        //TEXTFIELD
        let textField = UITextField()
        container.addSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.backgroundColor = .white
        
        textField.topAnchor.constraint(equalTo: container.topAnchor, constant: 8).isActive = true
        textField.leadingAnchor.constraint(equalTo: anexoButton.trailingAnchor, constant: 4).isActive = true
        textField.bottomAnchor.constraint(equalTo: container.layoutMarginsGuide.bottomAnchor, constant: 8).isActive = true
        textField.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -70).isActive = true
        
        self.mensagemTextField = textField
        
        
        
        //BOTAO ENVIAR
        let sendButton = UIButton()
        container.addSubview(sendButton)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        
        sendButton.topAnchor.constraint(equalTo: container.topAnchor, constant: 8).isActive = true
        sendButton.leadingAnchor.constraint(equalTo: textField.trailingAnchor, constant: 4).isActive = true
        sendButton.bottomAnchor.constraint(equalTo: container.layoutMarginsGuide.bottomAnchor, constant: 8).isActive = true
        sendButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8).isActive = true
        sendButton.setTitle("Enviar", for: .normal)
        sendButton.setTitleColor(.systemBlue, for: .normal)
        sendButton.addTarget(self, action: #selector(enviarButton), for: .touchUpInside)
        
        
        return container
    }()
    
    override var inputAccessoryView: UIView? {
        return bottomView
    }
    
    override var canBecomeFirstResponder: Bool {
        true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        auth = Auth.auth()
        firestore = Firestore.firestore()
        storage = Storage.storage()
        
        imagePicker.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        
        guard let id = auth.currentUser?.uid else { return }
        self.usuarioLogado = id
        
        recuperaDados()
        
        guard let nome = contato["nome"] as? String else { return }
        nameContato = nome
        self.nomeContato.text = nome
        
        guard let url = contato["urlImagem"] as? String else { return }
        self.urlFotoContato = url
        
        
        tableView.backgroundView = UIImageView(image: UIImage(named: "bg"))
        
        addObserverKeyboard()
        tableView.keyboardDismissMode = UIScrollView.KeyboardDismissMode.interactive
        
    }
    
    func updateEditBarBottomConstraint(value: CGFloat) {
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        
        //Retrieve keyboard height
        let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey]
        let keyboardFrameAsValue = keyboardFrame as? NSValue
        guard let keyboardRect = keyboardFrameAsValue?.cgRectValue else { return }
        let keyboardHeight = keyboardRect.height
        self.tableView.verticalScrollIndicatorInsets.bottom = keyboardHeight
        self.tableView.contentInset.bottom = keyboardHeight
        self.scrollToLastRow()
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        updateEditBarBottomConstraint(value: 0)
        
        //self.scrollToLastRow()
    }
    
    func addObserverKeyboard(){
        NotificationCenter.default.addObserver(self, selector: #selector(MensagensViewController.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MensagensViewController.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        guard let inputAcessoryViewHeight = inputAccessoryView?.frame.height else { return }
        self.tableView.verticalScrollIndicatorInsets.bottom = inputAcessoryViewHeight - view.safeAreaInsets.bottom
        self.tableView.contentInset.bottom = inputAcessoryViewHeight - view.safeAreaInsets.bottom
        self.scrollToLastRow()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        self.listaMensagens.removeAll()
        self.tableView.reloadData()
        addListenerRecuperarMensagens()
        
    }
    
    
    
    override func viewWillDisappear(_ animated: Bool) {
        listener.remove()
    }
    
    @IBAction func returnButton(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
        
    }
    
    func camera()
    {
        imagePicker.sourceType = UIImagePickerController.SourceType.camera
        self.present(imagePicker, animated: true, completion: nil)
        
    }
    
    func photoLibrary()
    {
        imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
        self.present(imagePicker, animated: true, completion: nil)
        
    }
    
    @objc func showActionSheet(button: UIButton) {
        
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
    
    func recuperaDados() {
        let usuarios = firestore.collection("usuarios").document(usuarioLogado)
        usuarios.getDocument { (snapshot, erro) in
            if erro == nil {
                guard let  dados = snapshot?.data() else { return }
                guard let url = dados["urlImagem"] as? String else { return }
                guard let nome = dados["nome"] as? String else { return }
                self.nameContatoLogado = nome
                self.urlFotoContatoLogado = url
                
            }
        }
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let imagemSelecionada = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        
        let imagens = storage.reference().child("imagens")
        if let imagemUpload = imagemSelecionada.jpegData(compressionQuality: 1) {
            
            if let usuarioLogado = auth.currentUser {
                let idUnicoImagem = UUID().uuidString
                let nomeImagem = "\(idUnicoImagem).jpg"
                let imagemMensagemReferencia = imagens.child("mensagens").child(nomeImagem)
                imagemMensagemReferencia.putData(imagemUpload, metadata: nil) { (metaData, erro) in
                    if erro == nil {
                        imagemMensagemReferencia.downloadURL { (url, erro) in
                            if let urlImagem = url?.absoluteString {
                                guard let usuarioDestinatario = self.contato["idUsuario"] as? String else { return }
                                
                                let mensagem: Dictionary<String, Any> = [
                                    "idUsuario" : self.usuarioLogado!,
                                    "urlImagem" : urlImagem,
                                    "data" : FieldValue.serverTimestamp()
                                ]
                                //mensagem quando enviada
                                self.salvarMensagem(idRemetente: self.usuarioLogado, idDestinatario: usuarioDestinatario, mensagem: mensagem as Dictionary<String, Any>)
                                
                                //mensagem quando recebida
                                self.salvarMensagem(idRemetente: usuarioDestinatario, idDestinatario: self.usuarioLogado, mensagem: mensagem as Dictionary<String, Any>)
                                
                                var conversa: Dictionary<String, Any> = [
                                    
                                    "ultimaMsg" : "imagem..."
                                    
                                ]
                                
                                
                                //salvando conversa pro remetente
                                conversa["idRementente"] = usuarioLogado
                                conversa["idDestinatario"] = usuarioDestinatario
                                conversa["nomeUsuario"] = self.nameContato
                                conversa["urlFotoContato"] = self.urlFotoContato
                                self.salvarConversa(idRemetente: self.usuarioLogado, idDestinatario: usuarioDestinatario, conversa: conversa)
                                
                                //salvando conversa pro destinatario
                                conversa["idRementente"] = usuarioDestinatario
                                conversa["idDestinatario"] = usuarioLogado
                                conversa["nomeUsuario"] = self.nameContatoLogado
                                conversa["urlFotoContato"] = self.urlFotoContatoLogado
                                self.salvarConversa(idRemetente: usuarioDestinatario, idDestinatario: self.usuarioLogado, conversa: conversa)
                                
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
    
    @objc func enviarButton(_ sender: Any) {
        
        guard let textoDigitado = mensagemTextField.text else { return }
        if !textoDigitado.isEmpty {
            
            guard let usuarioDestinatario = contato["idUsuario"] as? String else { return }
            
            let mensagem: Dictionary<String, Any> = [
                "idUsuario" : usuarioLogado!,
                "textoMensagem" : textoDigitado,
                "data" : FieldValue.serverTimestamp()
            ]
            //mensagem quando enviada
            salvarMensagem(idRemetente: usuarioLogado, idDestinatario: usuarioDestinatario, mensagem: mensagem as Dictionary<String, Any>)
            
            //mensagem quando recebida
            salvarMensagem(idRemetente: usuarioDestinatario, idDestinatario: usuarioLogado, mensagem: mensagem as Dictionary<String, Any>)
            
            var conversa: Dictionary<String, Any> = [
                
                "ultimaMsg" : textoDigitado
                
            ]
            //salvando conversa pro remetente
            conversa["idRementente"] = usuarioLogado
            conversa["idDestinatario"] = usuarioDestinatario
            conversa["nomeUsuario"] = self.nameContato
            conversa["urlFotoContato"] = self.urlFotoContato
            self.salvarConversa(idRemetente: self.usuarioLogado, idDestinatario: usuarioDestinatario, conversa: conversa)
            
            //salvando conversa pro destinatario
            conversa["idRementente"] = usuarioDestinatario
            conversa["idDestinatario"] = usuarioLogado
            conversa["nomeUsuario"] = self.nameContatoLogado
            conversa["urlFotoContato"] = self.urlFotoContatoLogado
            self.salvarConversa(idRemetente: usuarioDestinatario, idDestinatario: self.usuarioLogado, conversa: conversa)
            
            self.mensagemTextField.text = ""
            
        }
    }
    
    func salvarConversa(idRemetente: String, idDestinatario: String, conversa: Dictionary<String, Any>) {
        firestore.collection("conversas").document( idRemetente).collection("ultimas_conversas").document(idDestinatario).setData(conversa)
    }
    
    func salvarMensagem(idRemetente: String, idDestinatario: String, mensagem: Dictionary<String, Any>) {
        firestore.collection("mensagens").document( idRemetente).collection(idDestinatario).addDocument(data: mensagem)
    }
    
    fileprivate func scrollToLastRow() {
        if self.listaMensagens.count == 0 {
            return
        } else {
            let lastRowIndexPath = IndexPath(row: self.listaMensagens.count - 1, section: 0)
            self.tableView.scrollToRow(at: lastRowIndexPath, at: .bottom, animated: true)
        }
        
    }
    
    func addListenerRecuperarMensagens() {
        guard let idDestinatario = contato["idUsuario"] as? String else { return }
        listener = firestore.collection("mensagens").document(usuarioLogado).collection(idDestinatario).order(by: "data", descending: false).addSnapshotListener { (querySnapshot, error) in
            if error == nil {
                
                self.listaMensagens.removeAll()
                
                guard let snapshot = querySnapshot else { return }
                for document in snapshot.documents {
                    let dados = document.data()
                    self.listaMensagens.append(dados)
                }
                self.tableView.reloadData()
                self.scrollToLastRow()
            }
        }
    }
    
    
}

extension MensagensViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        //        view.resignFirstResponder()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.listaMensagens.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let celulaEnviada = tableView.dequeueReusableCell(withIdentifier: "celulaMensagemEnviada", for: indexPath) as! MensagensTableViewCell
        let celulaRecebida = tableView.dequeueReusableCell(withIdentifier: "celulaMensagemRecebida", for: indexPath) as! MensagensTableViewCell
        let celulaImagemEnviada = tableView.dequeueReusableCell(withIdentifier: "celulaImagemEnviada", for: indexPath) as! MensagensTableViewCell
        let celulaImagemRecebida = tableView.dequeueReusableCell(withIdentifier: "celulaImagemRecebida", for: indexPath) as! MensagensTableViewCell
        
        let mensagem = self.listaMensagens[indexPath.row]
        let texto = mensagem["textoMensagem"] as? String
        let idUsuario = mensagem["idUsuario"] as? String
        let urlImagem = mensagem["urlImagem"] as? String
        
        
        if usuarioLogado == idUsuario {
            if urlImagem != nil {
                celulaImagemEnviada.imagemEnviadaView.sd_setImage(with: URL(string: urlImagem!), completed: nil)
                return celulaImagemEnviada
            }
            celulaEnviada.mensagemEnviadaLabel.text = texto
            return celulaEnviada
        } else {
            if urlImagem != nil {
                celulaImagemRecebida.imagemRecebidaView.sd_setImage(with: URL(string: urlImagem!), completed: nil)
                return celulaImagemRecebida
            }
            celulaRecebida.mensagemRecebidaLabel.text = texto
            return celulaRecebida
        }
    }
}

class CustomView: UIView {
    override var intrinsicContentSize: CGSize {
        .zero
    }
}
