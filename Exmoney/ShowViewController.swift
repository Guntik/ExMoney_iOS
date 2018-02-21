//
//  ShowViewController.swift
//  Exmoney
//
//  Created by Damir Gaynetdinov on 28/03/2017.
//  Copyright © 2017 Damir Gaynetdinov. All rights reserved.
//

import UIKit
import Floaty

protocol ShowTransactionDelegate: class { //Setting up a Custom delegate for this class. I am using `class` here to make it weak.
    func sendTransactionViewController(categoryToRefresh: String?) //This function will send the data back to origin viewcontroller.
}

class ShowViewController: UIViewController {


    @IBOutlet weak var BackItem: UINavigationItem!
    @IBOutlet weak var DescriptionLabel: UILabel!
    @IBOutlet weak var currencyLabel: UILabel!
    @IBOutlet weak var accountLabel: UILabel!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var payeeLabel: UILabel!
    @IBOutlet weak var informarionLabel: UILabel!

    
    
    var showTransaction = Transaction()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        BackItem.title = "Transaction"
        BackItem.leftBarButtonItem = UIBarButtonItem(title: "← Back", style: .plain, target: self, action: #selector(backAction))

        if (showTransaction.Description == nil) {
            DescriptionLabel.text = ""}
        else {DescriptionLabel.text = showTransaction.Description}
        
        if (showTransaction.CurrencyCode == nil){
            currencyLabel.text = ""}
        else {currencyLabel.text = showTransaction.CurrencyCode}
        
        
        let account = realm.objects(Account).filter("id_acc = %@ AND ShowOnDashboard == 1", showTransaction.account_id)
        if (account !=  nil){
            accountLabel.text = account.first?.Name
        }
        else {
            accountLabel.text = ""
        }
        
        if (showTransaction.Category == nil){
            categoryLabel.text = ""}
        else {categoryLabel.text = showTransaction.Category?.name}
        
        
        //Transaction Info
        if (showTransaction.Payee == nil){
            payeeLabel.text = ""}
        else {payeeLabel.text = showTransaction.Payee}
        
        if (showTransaction.Information == nil){
            informarionLabel.text = ""}
        else {informarionLabel.text = showTransaction.Information}
        
        /*if (showTransaction.MadeOn == nil){
            timeLabel.text = ""}
        else {timeLabel.text = showTransaction.MadeOn}*/
        
       
    }
    
    func backAction(){
        //Floaty.global.show()
        //let ViewController = self.storyboard?.instantiateViewController(withIdentifier: "AccountViewController") as! AccountViewController
        //self.navigationController?.pushViewController(ViewController, animated:true )
        dismiss(animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
