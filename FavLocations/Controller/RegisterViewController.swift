//
//  RegisterViewController.swift
//  FavLocations
//
//  Created by ivan on 2021/12/15.
//

import UIKit
import Firebase
import SwiftSpinner

class RegisterViewController: UIViewController {

    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var warningLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        warningLabel.text = ""
        warningLabel.textColor = .systemRed

        // Do any additional setup after loading the view.
    }
    
    @IBAction func registerButtonAction(_ sender: Any) {
        // get username and password input
        let username = usernameTextField.text
        let password = passwordTextField.text
        
        // validate username
        if username?.count == 0 || username?.isValidEmail == false {
            warningLabel.text = "Please enter a valid Email"
            return
        }
        
        // validate password
        if password?.count ?? 0 < 5 {
            warningLabel.text = "Please enter a valid password"
            return
        }
        SwiftSpinner.show("Signing up...")
        Auth.auth().createUser(withEmail: username!, password: password!) { authResult, error in
            SwiftSpinner.hide()
            if error != nil {
                self.warningLabel.text =  error?.localizedDescription
                return
            }
            self.passwordTextField.text = ""
            self.navigationController?.popToRootViewController(animated: true)
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
// help to validate username
extension String{
    var isValidEmail : Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: self)
    }
}
