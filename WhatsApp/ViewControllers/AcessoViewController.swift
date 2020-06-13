//
//  AcessoViewController.swift
//  WhatsApp
//
//  Created by Fagner Caetano on 28/05/20.
//  Copyright © 2020 Fagner Caetano. All rights reserved.
//

import UIKit
import FirebaseAuth

class AcessoViewController: UIViewController {
    
    var auth: Auth!
    var handle: AuthStateDidChangeListenerHandle!
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var senhaTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        auth = Auth.auth()
        
        handle = auth.addStateDidChangeListener { (autenticacao, usuario) in
            if usuario != nil {
                self.performSegue(withIdentifier: "loginAutomaticoSegue", sender: nil)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        guard let handleUnwrapped = handle else { return }
        Auth.auth().removeStateDidChangeListener(handleUnwrapped)
    }
    
    @IBAction func loginButton(_ sender: Any) {
        let email = emailTextField.text
        let senha = senhaTextField.text
        
        if email == "" || senha == ""{
            let alerta = Alerta(title: "Verifique os campos.", message: "Usuário ou senha não foram preenchidos.")
            self.present(alerta.getAlert(), animated: true, completion: nil)
        } else {
            auth.signIn(withEmail: email!, password: senha!) { (usuario, erro) in
                if erro == nil {
                    if usuario == nil {
                        let alerta = Alerta(title: "Erro de autenticação.", message: "Ocorreu um erro inesperado. Tente novamente.")
                        self.present(alerta.getAlert(), animated: true, completion: nil)
                    }
                } else {
                    //
                    let erroRecuperado = erro! as NSError
                    guard let erroCodigo = erroRecuperado.userInfo["FIRAuthErrorUserInfoNameKey"] else { return }
                    let erroTexto = erroCodigo as! String
                    var erroMensagem = ""
                    switch erroTexto {
                    case "ERROR_INVALID_EMAIL" :
                        erroMensagem = "Digite um email válido."
                        break
                    case "ERROR_USER_NOT_FOUND" :
                        erroMensagem = "Usuário não encontrado."
                        break
                    case "ERROR_MISSING_EMAIL" :
                        erroMensagem =  "Email vazio. Digite um email para confluir o cadastro"
                        break
                    case "ERROR_EMAIL_ALREADY_IN_USE" :
                        erroMensagem = "Email já cadastrado. Utilize um novo email."
                    default:
                        erroMensagem = "Dados inválidos."
                    }
                    let alerta = Alerta(title: "Verifique os dados", message: erroMensagem)
                    self.present(alerta.getAlert(), animated: true, completion: nil)
                }
            }
        }
    }
    
    @IBAction func unwindToAcessoViewcontroller(_ unwindSegue: UIStoryboardSegue) {
        //let sourceViewController = unwindSegue.source
        // Use data from the view controller which initiated the unwind segue
    }
    
}
