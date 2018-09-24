//
//  ShowTransactionViewController.swift
//  Exmoney
//
//  Created by Galina Gaynetdinova on 30/08/2017.
//  Copyright © 2017 Galina Gaynetdinova. All rights reserved.
//

import UIKit

class ShowTransactionViewController: UIViewController {

    var showTransaction = Transaction()
    
    @IBOutlet weak var showNavigationItem: UINavigationItem!

    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        showNavigationItem.title = "Transaction"
        showNavigationItem.leftBarButtonItem = UIBarButtonItem(title: "← Back", style: .plain, target: self, action: #selector(backAction))
        tableView.tableFooterView = UIView(frame: CGRect.zero)
    }
    
    func backAction(){
        dismiss(animated: true, completion: nil)
    }
}

//MARK: - UITableViewDelegate
extension ShowTransactionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 3 && indexPath.section == 0 {
            return 80
        } else {
            if (indexPath.section == 1) {
                return 80
            } else {
                return 40
            }
        }
    }
}

//MARK: - UITableViewDataSource
extension ShowTransactionViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == 0) {
            return 4
        } else {
            return 1//2
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Transaction"
        } else {
            return "Transaction Info"}
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "transactionCell", for: indexPath)
        if (indexPath.section == 0) {
            switch indexPath.row {
            case 0:
                let account = realm.objects(Account.self).filter("id_acc = %@ AND isAccountShow == 1", showTransaction.account_id)
                cell.detailTextLabel?.text = account.first?.name
                cell.textLabel?.text = "Account"
                
            case 1:
                if (showTransaction.category == nil){
                    cell.detailTextLabel?.text = ""}
                else {
                    cell.detailTextLabel?.text = showTransaction.category?.name}
                cell.textLabel?.text = "Category"
            case 2:
                if (showTransaction.currencyCode == ""){
                    cell.detailTextLabel?.text = ""}
                else {
                    cell.detailTextLabel?.text = showTransaction.currencyCode}
                cell.textLabel?.text = "Currency"
            default:
                if (showTransaction.descriptionOfTransaction == nil) {
                    cell.detailTextLabel?.text = ""}
                else{
                    cell.detailTextLabel?.text = showTransaction.descriptionOfTransaction}
                cell.textLabel?.text = "Description"
            }
        } else {
            if (showTransaction.payee == nil) {
                cell.detailTextLabel?.text = ""
            } else {
                cell.detailTextLabel?.text = showTransaction.payee
            }
            cell.textLabel?.text = "Payee"
            cell.detailTextLabel?.numberOfLines = 0
            cell.detailTextLabel?.text = showTransaction.payee

        }
        return cell
    }
}
