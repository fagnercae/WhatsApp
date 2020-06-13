//
//  CadastroViewController.swift
//  WhatsApp
//
//  Created by Fagner Caetano on 28/05/20.
//  Copyright © 2020 Fagner Caetano. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class CadastroViewController: UIViewController {
    
    @IBOutlet weak var nomeTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var senhaTextField: UITextField!
    @IBOutlet weak var confirmaSenhaTextField: UITextField!
    
    var auth: Auth!
    var firestore: Firestore!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        auth = Auth.auth()
        firestore = Firestore.firestore()
        
        
    }
    
    @IBAction func cadastrarButton(_ sender: Any) {
        
        guard let nome = nomeTextField.text else { return }
        guard let email = emailTextField.text else { return }
        guard let senha = senhaTextField.text else { return }
        guard let confirmaSenha = confirmaSenhaTextField.text else { return }
        
        if senha != confirmaSenha {
            let alerta = Alerta(title: "Ocorreu um erro...", message: "Senhas não correspondem")
            present(alerta.getAlert(), animated: true, completion: nil)
        } else {
            auth.createUser(withEmail: email, password: senha) { (dadoResultado, erro) in
                if erro == nil { //Não ocorreu erro - Segue em frente
                    guard let idUsuario = dadoResultado?.user.uid else { return }
                    self.firestore.collection("usuarios").document(idUsuario).setData([
                        "nome" : nome,
                        "email" : email,
                        "idUsuario" : idUsuario
                    ])
                    
                } else {
                    //Tratamento de Erro de Cadastro
                    let erroRecuperado = erro! as NSError
                    guard let erroCodigo = erroRecuperado.userInfo["FIRAuthErrorUserInfoNameKey"] else { return }
                    let erroTexto = erroCodigo as! String
                    var erroMensagem = ""
                    switch erroTexto {
                    case "ERROR_INVALID_EMAIL" :
                        erroMensagem = "Digite um email válido."
                        break
                    case "ERROR_WEAK_PASSWORD" :
                        erroMensagem = "Senha deve conter mais de 6 caracteres entre letras e números."
                        break
                    case "ERROR_MISSING_EMAIL" :
                        erroMensagem =  "Email vazio. Digite um email para confluir o cadastro"
                        break
                    case "ERROR_EMAIL_ALREADY_IN_USE" :
                        erroMensagem = "Email já cadastrado. Utilize um novo email."
                    default:
                        erroMensagem = "Dados inválidos."
                    }
                    if self.nomeTextField.text == ""{
                        erroMensagem = "Digite seu nome."
                    }
                    let alerta = Alerta(title: "Ocorreu um erro...", message: erroMensagem)
                    self.present(alerta.getAlert(), animated: true, completion: nil)
                }
                
            }
        }
        
    }
    
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: true)
        
        
    }
    
}
