//
//  ViewController.swift
//  FavLocations
//
//  Created by ivan on 2021/12/15.
//

import UIKit
import Firebase
import SwiftSpinner
import KeychainSwift
import RealmSwift

class ViewController: UIViewController {

    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var warningLabel: UILabel!
    
    override func viewDidAppear(_ animated: Bool) {

        let keychain = KeychainSwift()
        
        if keychain.get("uid") != nil {
            performSegue(withIdentifier: "goToSearch", sender: self)
            print(keychain.get("uid"))
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        warningLabel.text = ""
        warningLabel.textColor = .systemRed
        // Do any additional setup after loading the view.
    }
    // login button
    @IBAction func loginButtonAction(_ sender: Any) {
        
        let username = usernameTextField.text
        let password = passwordTextField.text
        
        if username?.count == 0 || username?.isValidEmail == false {
            // warning label
            warningLabel.text = "Please enter a valid Email"
            return
        }
        
        // validate password
        if password?.count ?? 0 < 5 {
            // warning label show text
            warningLabel.text = "Please enter a valid password"
            return
        }
        
        SwiftSpinner.show("Loggin in...")
        Auth.auth().signIn(withEmail: username!, password: password!) { authResult, error in
            SwiftSpinner.hide()
            
            if error != nil {
                self.warningLabel.text =  error?.localizedDescription
                return
            }
            
            let uid = Auth.auth().currentUser?.uid
            self.warningLabel.text = ""
            Keychain().key.set(uid!, forKey: "uid" )
            print(Keychain().key.get("uid"))
            
            if self.userExistsInDB(uid: uid!) == false {
                let userInfo = UserInfo()
                userInfo.uid = uid!
                self.addUserInfotoDB(userInfo: userInfo)
            }
            self.passwordTextField.text = ""
            self.performSegue(withIdentifier: "goToSearch", sender: self)
        }
        
    }
    // register button
    @IBAction func registerButtonAction(_ sender: Any) {
        performSegue(withIdentifier: "goToRegister", sender: self)
    }
    // create new userInfo in realm
    func addUserInfotoDB(userInfo : UserInfo) {
        do {
            let realm = try Realm()
            let keychain = Keychain().key
            try realm.write {
                print(userInfo.uid)
                realm.add(userInfo, update: .modified)
            }
        } catch {
            print("Error in getting values from DB \(error)")
        }
    }
    // check if user already exists in realm
    func userExistsInDB(uid : String) -> Bool {
        do {
            let realm = try Realm()
            let keychain = Keychain().key
            if realm.object(ofType: UserInfo.self, forPrimaryKey: uid) != nil {return true}
            return false
        } catch {
            print("Error in getting values from DB \(error)")
        }
        return true
        
    }
}
