//
//  URLLoginViewController.swift
//  Exmoney
//
//  Created by Galina Gainetdinova on 03/02/2017.
//  Copyright © 2017 Galina Gainetdinova. All rights reserved.
//

import UIKit
import RealmSwift


class URLLoginViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var URLTextField: UITextField!
    
    //var flagToken:Bool = false
    var tokenKey:String = ""
    
    @IBAction func urlEditingChanged(_ sender: Any) {
        //Make LoginButton enable
        flagURL = true
        if (flagEmail && flagPassword && flagURL)
        {
            self.LoginButton.isEnabled = true
        }
    }
    
    @IBOutlet weak var EmailTextField: UITextField!
    
    @IBAction func passwordEditingChanged(_ sender: Any) {
        //Make LoginButton enable
        flagPassword = true
        if (flagEmail && flagPassword && flagURL)
        {
            self.LoginButton.isEnabled = true
        }
    }
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBAction func emailEditingChanged(_ sender: Any) {
        //Make LoginButton enable
        flagEmail = true
        if (flagEmail && flagPassword && flagURL)
        {
            self.LoginButton.isEnabled = true
        }
    }
    
    @IBOutlet weak var LoginButton: UIButton!
    
    public var flagURL:Bool = false
    public var flagEmail:Bool = false
    public var flagPassword:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // for me
        // self.URLTextField.text =
        self.EmailTextField.delegate = self
        self.passwordTextField.delegate = self
        self.URLTextField.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        //self.view.endEditing(true)
        textField.resignFirstResponder()
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }

    @IBAction func loginButton(_ sender: Any) {
        email = EmailTextField.text!
        password = passwordTextField.text!
        url = URLTextField.text!
        
        //check the Textfields
        if (email != nil && password != nil && url != nil) {

        //Post Method, get Token
        postToken()
        
        if (flagAccount)
        {
            //self.performSegue(withIdentifier: "ViewTableView", sender: self)
            self.performSegue(withIdentifier: "ViewTableView1", sender: self)
        }
        else {
            // Message empty fields
            let message:String = "You have empty fields"
            let alert = UIAlertController(title: "Alert", message: message, preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
            }
        }
    }
    var flagAccount:Bool = false
    
    func postToken()
    {
        DispatchQueue.global(qos: .userInitiated).async { }
        let urlPost = url + "/api/v2/login"
        let myUrl=URL(string:urlPost)
        
        userDefaults.set(url, forKey: "URLKey")
        
        //async
        let semaphore = DispatchSemaphore(value: 0)
        
        let postString = "email=\(email)&password=\(password)"
        
        var request = URLRequest(url:myUrl!)
        
        request.httpMethod = "POST"
        
        request.httpBody=postString.data(using: String.Encoding.utf8)
        
        let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            
            
            if error != nil
            {
                let messagePost:String = "It's somthing wrong: error " + error.debugDescription
                let alert = UIAlertController(title: "Alert", message: messagePost, preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }
            
            //Convert response
            do {
               let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                
                if let parseJSON = json {
                    
                    let jwtValue = parseJSON["jwt"] as? String
                    if (jwtValue != nil){
                        //save token
                        self.tokenKey = jwtValue!
                        userDefaults.set(jwtValue, forKey: "TokenKey")
                        //seve flag -> next time use only password and name
                        userDefaults.set(true, forKey:"flagToken")
                        // set flag to show tableView
                    }
                }
            } catch {
                let messageConvert:String = "Try it again"
                let alert = UIAlertController(title: "Alert", message: messageConvert, preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }
            semaphore.signal()
        }
        task.resume()
        semaphore.wait(timeout: .distantFuture)
        
        if (tokenKey == "")//(userDefaults.string(forKey: "TokenKey") == nil)
        {
            let messageConvert:String = "Pass or Email is incorrect"
            let alert = UIAlertController(title: "Alert", message: messageConvert, preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            self.flagAccount = false
        }
        else {
            self.flagAccount = true
        }
        //return
    }
    
    
    
    var url:String = ""
    var email:String = ""
    var password:String = ""

        
    
}



