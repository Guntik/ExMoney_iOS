//
//  ShowTransactionViewController.swift
//  Exmoney
//
//  Created by Galina Gaynetdinova on 30/08/2017.
//  Copyright © 2017 Galina Gaynetdinova. All rights reserved.
//

import UIKit

class ShowTransactionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var showTransaction = Transaction()
    
    @IBOutlet weak var showNavigationItem: UINavigationItem!
    
    //@IBOutlet weak var backNavigationItem: UINavigationItem!
    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        showNavigationItem.title = "Transaction"
        showNavigationItem.leftBarButtonItem = UIBarButtonItem(title: "← Back", style: .plain, target: self, action: #selector(backAction))
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        //tableView.rowHeight = UITableViewAutomaticDimension
        //tableView.estimatedRowHeight = 100
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func backAction(){
        dismiss(animated: true, completion: nil)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == 0){
            return 4
        }
        else{
            return 1//2
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 3 && indexPath.section == 0 {
            return 80
        }
        else {
            if (indexPath.section == 1)
            {
                return 80
            }
            else {
                return 40
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "transactionCell", for: indexPath)
        if (indexPath.section == 0){
        switch indexPath.row {
        case 0:
            let account = realm.objects(Account.self).filter("id_acc = %@ AND ShowOnDashboard == 1", showTransaction.account_id)
            cell.detailTextLabel?.text = account.first?.Name
            cell.textLabel?.text = "Account"
            
        case 1:
            if (showTransaction.Category == nil){
                cell.detailTextLabel?.text = ""}
            else {
                cell.detailTextLabel?.text = showTransaction.Category?.name}
            cell.textLabel?.text = "Category"
        case 2:
            if (showTransaction.CurrencyCode == nil){
                cell.detailTextLabel?.text = ""}
            else {
                cell.detailTextLabel?.text = showTransaction.CurrencyCode}
            cell.textLabel?.text = "Currency"
        default:
            if (showTransaction.Description == nil) {
                cell.detailTextLabel?.text = ""}
            else{
                cell.detailTextLabel?.text = showTransaction.Description}
            cell.textLabel?.text = "Description"
            }
        }
        else {
        //switch indexPath.row {
        //case 0:
            if (showTransaction.Payee == nil){
                cell.detailTextLabel?.text = ""}
            else {cell.detailTextLabel?.text = showTransaction.Payee}
            cell.textLabel?.text = "Payee"
            cell.detailTextLabel?.numberOfLines = 0
       /* default:
            if (showTransaction.Information == nil){
                cell.detailTextLabel?.text = ""}
            else {cell.detailTextLabel?.text = showTransaction.Information}
            cell.textLabel?.text = "Information"
            cell.detailTextLabel?.numberOfLines = 0
        }*/
        }
        return cell
    }
    
    /*func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: 30))
        //var label = UILabel(frame: CGRect(x:10, y: 0, width: tableView.bounds.size.width, height:30))
        headerView.backgroundColor = UIColor.lightGray
        //label.textColor = UIColor.orange
        /*if section == 0{
            label.text = "Transaction"}
        else {
            label.text = "Transaction Info"}
        headerView.addSubview(label)*/

        return headerView
    }*/
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0{
            return "Transaction"}
        else {
            return "Transaction Info"}
    }
        
}
