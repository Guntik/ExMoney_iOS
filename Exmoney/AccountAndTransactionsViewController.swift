//
//  AccountAndTransactionsViewController.swift
//  Exmoney
//
//  Created by Galina Gaynetdinova on 27/07/2017.
//  Copyright © 2017 Galina Gaynetdinova. All rights reserved.
//

import UIKit
import Floaty
import RealmSwift
import Reachability
    
extension Decimal {
    var doubleValue:Double {
        return NSDecimalNumber(decimal:self).doubleValue
    }
}

class AccountAndTransactionsViewController: UIViewController {

    var tableViewAccounts: UITableView!
    let floaty = Floaty()
    
    var myJson = MyJsonClass()
    
    //let userDefaults = Foundation.UserDefaults.standard
    var isEditingMode = false
    
    var editRow:Int = 0
    var editSection:Int = 0
    
    // for sections in TableView
    var sectionNames: [Date] {
        return Set(myJson.allTransaction.value(forKeyPath: "madeOn") as! [Date]).sorted(by: { $0.compare($1) == .orderedDescending})}
    
    var editCategory:String!
    var editNote:String!
    var editTransaction:Transaction!
    
    var delegate: writeValueBackDelegate?
    
    let screenHeight = UIScreen.main.bounds.height
    let lableHeight = 30
    var logInfoId = 0
    
    var flagConnectionChanged = false
    
    var reachability = Reachability()!
    var dateFormatt:DateFormatter = DateFormatter()
    
    let refreshControl = UIRefreshControl()
    
    var timer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Start Indicator
        processIndicator.startAnimating()
        UIApplication.shared.beginIgnoringInteractionEvents()

        createFloatButton()
        setReachability()
        myJson.loadAllDataFromRealm()
        //makeExpendedCategories()
        
        tableViewTransactions.estimatedSectionHeaderHeight = 40
        self.automaticallyAdjustsScrollViewInsets = false
        
        dateFormatt.dateFormat = "yyyy-MM-dd"
        
        tableViewAccounts = UITableView()

        let header = UIView(frame: CGRect(x: 0, y: 0, width: Int(tableViewTransactions.frame.width), height: heightOfTableView()))
        tableViewTransactions.tableHeaderView = header
        includingTableViewInHeader(view: header, tableView: tableViewAccounts)
        
        //Pull-to-refresh
        refreshControl.tintColor = UIColor.red
        refreshControl.addTarget(self, action: #selector(AccountAndTransactionsViewController.handleRefresh(refreshControl:)), for: UIControlEvents.valueChanged)
        self.tableViewTransactions.addSubview(self.refreshControl)
        
        setWidthOfTables()
        processIndicator.stopAnimating()
        UIApplication.shared.endIgnoringInteractionEvents()
        
        //start Timer every 3 minutes
        timer.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 20.0, target: self, selector: #selector(AccountAndTransactionsViewController.startActionTimer), userInfo: nil, repeats: true)
    }
    
    //Timer action
    func startActionTimer(){
        processIndicator.startAnimating()
        if (myJson.updatingTransactiontFromServer()) {
            //sorted list
            //updatingTransactions.ListUpdatingResults.sorted(byKeyPath: "insertedAtDate", ascending: false)
            myJson.updatingTableView()
            myJson.sendingReport()
            self.tableViewTransactions.reloadData()
        }
        print("The transactions were updated")
        processIndicator.stopAnimating()
    }
    deinit {
        timer.invalidate()
    }
    
    //to set width of AccountTable and TransactionTable as width of view
    func setWidthOfTables(){
        tableViewAccounts.frame.size.width = view.frame.size.width
        tableViewTransactions.frame.size.width = view.frame.size.width
    }
    
    func heightOfTableView() -> Int{
        var height:Int
        
        let rowHeightAccountsTableView = 30 // height of row in TableView
        let gapY = 30 //shift
        
        height = myJson.allAccounts.count * rowHeightAccountsTableView + 2 * lableHeight + 2 * gapY
        
        return height
    }
    
    //FloatyButton
    func createFloatButton(){
        floaty.buttonColor = UIColor(red: 255/155, green: 198/255, blue: 67/255, alpha: 1)
        let item = FloatyItem()
        item.buttonColor = UIColor(red: 255/255, green: 198/255, blue: 67/255, alpha: 1)
        item.title = "Add"
        item.icon = UIImage(named: "AddButton-yellow2")!
        item.handler = {item in
            let VC = self.storyboard?.instantiateViewController(withIdentifier: "AddNewTransactionView") as! AddNewTransactionViewController
            VC.delegateTransaction = self
            self.present(VC, animated: true, completion: nil)
            //self.performSegue(withIdentifier: "showAddTransactionViewSegue", sender: self)
            //self.navigationController?.pushViewController(VC, animated: true)
        }
        floaty.addItem(item: item)
        self.view.addSubview(floaty)
    }
    
    // Reachability of WIFi and Cellular with listening
    func setReachability() {
        do {
            reachability = try Reachability.init()!
        } catch {
            myJson.showMessage(messageString: "Reachability can't be created")
            return
        }
        DispatchQueue(label: "background").async {
            NotificationCenter.default.addObserver(self, selector: #selector(self.reachabilityChanged),name: Notification.Name.reachabilityChanged,object: self.reachability)
            do {
                try self.reachability.startNotifier()
            } catch {
                self.myJson.showMessage(messageString: "Could not start Reachabilty Notificater")
                return
            }
        }

    }
    //checkind WiFi and Cellular
    func reachabilityChanged(note: Notification) {
        
        let reachability = note.object as! Reachability
        
        if reachability.isReachable {
            DispatchQueue.main.async {
                if reachability.isReachableViaWiFi {
                    print("Reachable via WiFi")
                } else {
                    print("Reachable via Cellular")
                }
                if(self.flagConnectionChanged && self.myJson.makeListOfFailedTransactions().count != 0) {
                    for i in 0 ... self.self.myJson.makeListOfFailedTransactions().count - 1{
                        self.myJson.postTransaction(SendingUUID: self.myJson.makeListOfFailedTransactions()[i].uuid!)
                    }
                }
            }
        } else {
            flagConnectionChanged = true
            self.myJson.showMessage(messageString: "Network not reachable")
            return
        }
    }
    
    //Sending failed Transaction
    //func sendTransactionToDashboard() {
        //let notSendedTransaction = realm.objects(LogInfo.self).filter("status = 'false'")
        //notSendedTransaction.sorted(byKeyPath: "time")
        //print(notSendedTransaction)
       // return
    //}

    
    func includingTableViewInHeader(view: UIView, tableView: UITableView)
    {
        tableView.dataSource = self
        tableView.delegate = self
        
        let accountsLabel: UILabel!
        let transactionsLabel: UILabel!
        
        accountsLabel = UILabel()
        accountsLabel.text = "Accounts"
        accountsLabel.frame = CGRect(x: 20, y: 10, width: Int(view.frame.width), height: lableHeight)
        accountsLabel.textColor = UIColor.black //UIColor.orange
        accountsLabel.font = UIFont.boldSystemFont(ofSize: 20.0)
        view.addSubview(accountsLabel)
        
        tableView.frame = CGRect(x: 0, y: 40, width: view.frame.width, height: view.frame.height - CGFloat(lableHeight) - 20)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "AccountCellID")
        view.addSubview(tableView)
        tableView.tableFooterView = UIView.init(frame: CGRect.zero)
        
        transactionsLabel = UILabel()
        transactionsLabel.text = "Transactions"
        transactionsLabel.frame = CGRect(x: 20, y: view.frame.height - CGFloat(lableHeight)-10, width: view.frame.width, height: CGFloat(lableHeight))
        transactionsLabel.textColor = UIColor.black//UIColor.orange
        transactionsLabel.font = UIFont.boldSystemFont(ofSize: 20.0)
        view.addSubview(transactionsLabel)
    }
    
    func handleRefresh(refreshControl: UIRefreshControl) {
        if (myJson.updatingTransactiontFromServer()) {
            //sorted list
            //updatingTransactions.ListUpdatingResults.sorted(byKeyPath: "insertedAtDate", ascending: false)
            myJson.updatingTableView()
            myJson.sendingReport()
            self.tableViewTransactions.reloadData()
        }
        refreshControl.endRefreshing()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //preparing for ShowTransactionViewControllSegue
        if (segue.identifier == "showSegue") {
            let showViewController = segue.destination as! ShowTransactionViewController
            //showViewController
        }
    }
    
    //get currency symbol from currency code
    func getSymbolForCurrencyCode(currencyCode: String) -> String? {
        if (currencyCode == "RUB") {
            let symbol:String = "₽"
            return symbol
        } else {
            let locale = NSLocale(localeIdentifier: currencyCode)
            let symbol = locale.displayName(forKey: NSLocale.Key.currencySymbol, value: currencyCode)
            return symbol
        }
    }
    
    func getNewTransactionID(objectType: Object.Type) -> Int{
        let allEntries = realm.objects(objectType)
        if allEntries.count > 0 {
            let lastId = allEntries.max(ofProperty: "id") as Int?
            return lastId! + 1
        } else {
            return 1
        }
    }
    
    func amountToString(amount_millic: Int) ->String {
        let stringAmount:String
        let decimalAmount:Decimal
        decimalAmount = Decimal(amount_millic)
        let d1:Double = decimalAmount.doubleValue
        stringAmount = String(describing: d1/1000)
        return stringAmount
    }
    
    @IBOutlet weak var processIndicator: UIActivityIndicatorView!
    @IBOutlet weak var tableViewTransactions: UITableView!
}

//MARK: - UITableViewDataSource
extension AccountAndTransactionsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        if (tableView == tableViewTransactions) {
            return sectionNames.count
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count:Int?
        if tableView == self.tableViewAccounts {
            count = myJson.allAccounts.count
        }
        if tableView == self.tableViewTransactions {
            count = myJson.allTransaction.filter("madeOn == %@", sectionNames[section]).count
        }
        return count!
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == self.tableViewTransactions {
            let cell = Bundle.main.loadNibNamed("TransactionTableViewCell", owner: self, options: nil)?.first as! TransactionTableViewCell
            //let cell = TransactionCell(style: UITableViewCellStyle.default, reuseIdentifier: "CellID")
            if let code1 = myJson.allTransaction.filter("madeOn == %@", sectionNames[indexPath.section])[indexPath.row].currencyCode {
                cell.AmountLbl.text = amountToString(amount_millic: myJson.allTransaction.filter("madeOn == %@", sectionNames[indexPath.section])[indexPath.row].amount_millicents) + " " + getSymbolForCurrencyCode(currencyCode: myJson.allTransaction.filter("madeOn == %@", sectionNames[indexPath.section])[indexPath.row].currencyCode!)!
                
            } else {
                cell.AmountLbl.text = amountToString(amount_millic: myJson.allTransaction.filter("madeOn == %@", sectionNames[indexPath.section])[indexPath.row].amount_millicents)
                //cell.Amount.text = amountToString(amount_millic: allTransaction.filter("MadeOn == %@", sectionNames[indexPath.section])[indexPath.row].Amount_millicents)*/
            }
            
            cell.CategoryLbl.text = myJson.allTransaction.filter("madeOn == %@", sectionNames[indexPath.section])[indexPath.row].category?.name
            //cell.Category.text = allTransaction.filter("MadeOn == %@", sectionNames[indexPath.section])[indexPath.row].Category?.name
            
            if (myJson.allTransaction.filter("madeOn == %@", sectionNames[indexPath.section])[indexPath.row].payee != nil){
                cell.DescriptionLbl.text = self.myJson.allTransaction.filter("madeOn == %@", self.sectionNames[indexPath.section])[indexPath.row].payee!
                
            } else {
                cell.DescriptionLbl.text = "Cash"
                //cell.Description?.text = "Cash"
            }
            return cell
        } else {
            let cell = Bundle.main.loadNibNamed("AccountTableViewCell", owner: self, options: nil)?.first as! AccountTableViewCell
            let acc = myJson.allAccounts[indexPath.row]
            cell.AccountLbl.text = acc.name
            cell.BalanceLbl.text = amountToString(amount_millic: Int(acc.balance_millicents)) + " " + getSymbolForCurrencyCode(currencyCode: acc.currencyCode)!
            
            return cell
        }
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var item:String?
        if tableView == self.tableViewAccounts {
            item = ""
        }
        if tableView == self.tableViewTransactions {
            item = dateFormatt.string(from: self.sectionNames[section])
        }
        return item!
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if tableView == self.tableViewTransactions {
            return true
        } else {
            return false
        }
    }
}

//MARK: - UITableViewDelegate
extension AccountAndTransactionsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        if (tableView == tableViewTransactions) {
            let show = UITableViewRowAction(style: .destructive, title: "Show") { (action, indexPath) in
                let showViewController = self.storyboard?.instantiateViewController(withIdentifier: "ShowTransactionView") as! ShowTransactionViewController
                showViewController.showTransaction = self.myJson.allTransaction.filter("madeOn == %@", self.sectionNames[indexPath.section])[indexPath.row]
                
                self.navigationController?.pushViewController(showViewController, animated:true )
                self.present(showViewController, animated: true, completion: nil)
            }
            
            let edit = UITableViewRowAction(style: .default, title: "Edit") { (action, indexPath) in
                let editViewController = self.storyboard?.instantiateViewController(withIdentifier: "EditViewController") as! EditViewController
                editViewController.delegate = self
                self.editTransaction = self.myJson.allTransaction.filter("madeOn == %@", self.sectionNames[indexPath.section])[indexPath.row]
                editViewController.categoryToUpdate = (self.myJson.allTransaction.filter("madeOn == %@", self.sectionNames[indexPath.section])[indexPath.row]).category!
                editViewController.noteToUpdate = (self.myJson.allTransaction.filter("madeOn == %@", self.sectionNames[indexPath.section])[indexPath.row]).descriptionOfTransaction!
                editViewController.labelInformation = (self.myJson.allTransaction.filter("madeOn == %@", self.sectionNames[indexPath.section])[indexPath.row]).payee!
                
                self.editRow = indexPath.row
                self.editSection = indexPath.section
                
                self.navigationController?.pushViewController(editViewController, animated:true )
                self.present(editViewController, animated: true, completion: nil)
            }
            
            let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
                
                let deleteItem = self.myJson.allTransaction.filter("madeOn == %@", self.sectionNames[indexPath.section])[indexPath.row]
                let deletedSectionName = self.sectionNames[indexPath.section]
                
                let date = NSDate()
                let data = "{\"uuid\": \(deleteItem.id), \"action\": \"delete\"}"//.data(using: .utf8)!
                // Not implementet yet. Sending Log with action to server
                /*let logItem = LogInfo()
                 logItem.Transaction = data
                 logItem.status = false
                 logItem.time = date
                 logItem.id = self.logInfoId + 1
                 self.logInfoId = logItem.id*/
                
                /*try! realm.write {
                 //let json = try! JSONSerialization.jsonObject(with: data, options: [])
                 realm.add(logItem)
                 }*/
                
                try! realm.write({
                    realm.delete(deleteItem)
                })
                let madeOnItem = self.myJson.allTransaction.filter("madeOn == %@", deletedSectionName)
                if (!madeOnItem.isEmpty) {
                    self.tableViewTransactions.beginUpdates()
                    self.tableViewTransactions.deleteRows(at: [indexPath], with: .automatic)
                    self.tableViewTransactions.endUpdates()
                } else {
                    self.tableViewTransactions.beginUpdates()
                    let indexSet = NSMutableIndexSet()
                    indexSet.add(indexPath.section)
                    //self.tableViewTransactions.deleteRows(at: [indexPath], with: .automatic)
                    self.tableViewTransactions.deleteSections(indexSet as IndexSet, with: .automatic)
                    self.tableViewTransactions.endUpdates()
                }
            }
            edit.backgroundColor = UIColor.orange
            show.backgroundColor = UIColor.blue
            
            return [delete, edit, show]
        } else {
            tableView.isEditing = false
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == self.tableViewTransactions {
            return 70
        } else {
            return 40
        }
    }
}

//MARK: - writeValueBackDelegate
extension AccountAndTransactionsViewController: writeValueBackDelegate {
    //update Transactions
    func writeValueBack(sendBackCategory: CategoryTransaction, sendBackNote: String) {
        
        let item = myJson.allTransaction.filter("madeOn == %@", sectionNames[editSection])[editRow]
        
        try! realm.write {
            realm.create(Transaction.self, value: ["id": editTransaction?.id, "Category": sendBackCategory, "Description": sendBackNote], update: true) ///???category or categoryid
            item.descriptionOfTransaction = sendBackNote
            item.category = sendBackCategory
        }
        
        let indexPath = IndexPath(item: editRow, section: editSection)
        tableViewTransactions.beginUpdates()
        tableViewTransactions.reloadRows(at: [indexPath], with: .top)
        tableViewTransactions.endUpdates()
        //tableView2.reloadData()
        
        //write updated Transaction in Log
        let updateTransaction = realm.object(ofType: Transaction.self, forPrimaryKey: self.editTransaction.id) as! Transaction
        let date = NSDate()
        let data = "{\"uuid\": \(editTransaction.account_id)}"//.data(using: .utf8)!
    }
}

//MARK: - addingTransactionDelegate
extension AccountAndTransactionsViewController: addingTransactionDelegate {
    func addingDelegate(addTransaction: Transaction) {
        // Subtracten from Accounts
        let id:Int = addTransaction.account_id
        let acc:Account = realm.object(ofType: Account.self, forPrimaryKey: id)!
        let acc_currencyCode = acc.currencyCode
        addTransaction.currencyCode = acc.currencyCode
        try! realm.write {
            acc.setValue(acc.balance_millicents + addTransaction.amount_millicents, forKeyPath: "balance_millicents")
        }
        var cellIndex:IndexPath!
        //update TableView (Accounts)
        for i in 0...myJson.allAccounts.count-1{
            let indexPath = IndexPath(item: i, section: 0)
            let cell: UITableViewCell = tableViewAccounts.dequeueReusableCell(withIdentifier: "AccountCellID", for:indexPath )
            if cell.textLabel?.text == acc.name {
                cellIndex = indexPath
                
                //let cell = UITableViewCell(style: UITableViewCellStyle.value1, reuseIdentifier: "AccountCellID")
                return
            }
        }
        //save in Realm
        try! realm.write({
            realm.add(addTransaction)
        })
        tableViewTransactions.reloadData()
        
        //write adding Transaction in Log
        let date = NSDate()
        let data = "{\"uuid\": \(addTransaction.account_id)}"//.data(using: .utf8)!
        
    }
}
