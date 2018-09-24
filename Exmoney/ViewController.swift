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

        if (!userDefaults.bool(forKey: "flagToken")) {
        //First opening App goes to Form with URL, Pass and Email
            self.performSegue(withIdentifier: "URLView", sender: self)
        } else {
            self.performSegue(withIdentifier: "accountsSeque1", sender: self)
        }
    }
}

