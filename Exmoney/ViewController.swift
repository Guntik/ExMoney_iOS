//
//  ViewController.swift
//  Exmoney
//
//  Created by Galina Gaynetdinova on 03/02/2017.
//  Copyright © 2017 Galina Gaynetdinova. All rights reserved.
//

import UIKit

class ViewController: UIViewController {


    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setToolbarHidden(true, animated: false)
        navigationController?.isNavigationBarHidden = true
        
        //loginButton.isEnabled = false
        if (!userDefaults.bool(forKey: "flagToken")){ //userDefaults.bool(forKey: "flagToken") == nil ||
        
        //First opening App goes to Form with URL, Pass and Email
            self.performSegue(withIdentifier: "URLView", sender: self)
        }
        else {
            //self.performSegue(withIdentifier: "accountsSeque", sender: self)
            self.performSegue(withIdentifier: "accountsSeque1", sender: self)
        }
        
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

