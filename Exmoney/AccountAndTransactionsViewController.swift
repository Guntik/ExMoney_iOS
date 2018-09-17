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
    var isEditingMode = false
    
    var editRow = 0
    var editSection = 0
    
    // for sections in TableView
    var sectionNames: [Date] {
        return Set(myJson.allTransactions.value(forKeyPath: "madeOn") as! [Date]).sorted(by: { $0.compare($1) == .orderedDescending})
    }
    
    var editCategory:String!
    var editNote:String!
    var editTransaction:Transaction!
    
    var delegate: editedTransactionDelegate?
    
    let screenHeight = UIScreen.main.bounds.height
    let lableHeight = 30
    var logInfoId = 0
    
    var flagConnectionChanged = false
    
    var reachability = Reachability()!
    var dateFormatt = DateFormatter()
    
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
        
        tableViewTransactions.estimatedSectionHeaderHeight = 40
        self.automaticallyAdjustsScrollViewInsets = false
        
        dateFormatt.dateFormat = "yyyy-MM-dd"
        
        tableViewAccounts = UITableView()

        let header = UIView(frame: CGRect(x: 0, y: 0, width: Int(tableViewTransactions.frame.width), height: heightOfTableView()))
        tableViewTransactions.tableHeaderView = header
        includingTableViewInHeader(view: header, tableView: tableViewAccounts)
        
        //Pull-to-refresh
        refreshControl.tintColor = .red
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
    
    func includingTableViewInHeader(view: UIView, tableView: UITableView)
    {
        tableView.dataSource = self
        tableView.delegate = self
        
        let accountsLabel: UILabel!
        let transactionsLabel: UILabel!
        
        accountsLabel = UILabel()
        accountsLabel.text = "Accounts"
        accountsLabel.frame = CGRect(x: 20, y: 10, width: Int(view.frame.width), height: lableHeight)
        accountsLabel.textColor = .black //UIColor.orange
        accountsLabel.font = .boldSystemFont(ofSize: 20.0)
        view.addSubview(accountsLabel)
        
        tableView.frame = CGRect(x: 0, y: 40, width: view.frame.width, height: view.frame.height - CGFloat(lableHeight) - 20)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "AccountCellID")
        view.addSubview(tableView)
        tableView.tableFooterView = UIView.init(frame: CGRect.zero)
        
        transactionsLabel = UILabel()
        transactionsLabel.text = "Transactions"
        transactionsLabel.frame = CGRect(x: 20, y: view.frame.height - CGFloat(lableHeight)-10, width: view.frame.width, height: CGFloat(lableHeight))
        transactionsLabel.textColor = .black
        transactionsLabel.font = .boldSystemFont(ofSize: 20.0)
        view.addSubview(transactionsLabel)
    }
    
    func handleRefresh(refreshControl: UIRefreshControl) {
        if (myJson.updatingTransactiontFromServer()) {
            myJson.updatingTableView()
            myJson.sendingReport()
            self.tableViewTransactions.reloadData()
        }
        refreshControl.endRefreshing()
    }
    
    //get currency symbol from currency code
    /*func getSymbolForCurrencyCode(currencyCode: String) -> String? {
        if (currencyCode == "RUB") {
            let symbol = "₽"
            return symbol
        } else {
            let locale = NSLocale(localeIdentifier: currencyCode)
            let symbol = locale.displayName(forKey: NSLocale.Key.currencySymbol, value: currencyCode)
            return symbol
        }
    }*/
    
    func getNewTransactionID(objectType: Object.Type) -> Int{
        let allEntries = realm.objects(objectType)
        if allEntries.count > 0 {
            let lastId = allEntries.max(ofProperty: "id") as Int?
            return lastId! + 1
        } else {
            return 1
        }
    }
    
    /*func amountToString(amount_millic: Int) ->String {
        let stringAmount:String
        let decimalAmount:Decimal
        decimalAmount = Decimal(amount_millic)
        let d1:Double = decimalAmount.doubleValue
        stringAmount = String(describing: d1/1000)
        return stringAmount
    }*/
    
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
            count = myJson.allTransactions.filter("madeOn == %@", sectionNames[section]).count
        }
        return count!
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == self.tableViewTransactions {
            let cell = Bundle.main.loadNibNamed("TransactionTableViewCell", owner: self, options: nil)?.first as! TransactionTableViewCell
            if myJson.allTransactions.filter("madeOn == %@", sectionNames[indexPath.section])[indexPath.row].currencyCode != "" {
                cell.AmountLbl.text = myJson.allTransactions.filter("madeOn == %@", sectionNames[indexPath.section])[indexPath.row].amountString + " " +  myJson.allTransactions.filter("madeOn == %@", sectionNames[indexPath.section])[indexPath.row].symbolForCurrencyCode
                
            } else {
                cell.AmountLbl.text = myJson.allTransactions.filter("madeOn == %@", sectionNames[indexPath.section])[indexPath.row].amountString
            }
            
            cell.CategoryLbl.text = myJson.allTransactions.filter("madeOn == %@", sectionNames[indexPath.section])[indexPath.row].category?.name
            
            if (myJson.allTransactions.filter("madeOn == %@", sectionNames[indexPath.section])[indexPath.row].payee != nil){
                cell.DescriptionLbl.text = self.myJson.allTransactions.filter("madeOn == %@", self.sectionNames[indexPath.section])[indexPath.row].payee!
                
            } else {
                cell.DescriptionLbl.text = "Cash"
            }
            return cell
        } else {
            let cell = Bundle.main.loadNibNamed("AccountTableViewCell", owner: self, options: nil)?.first as! AccountTableViewCell
            let acc = myJson.allAccounts[indexPath.row]
            cell.AccountLbl.text = acc.name
            cell.BalanceLbl.text = acc.balanceString + " " + acc.symbolForCurrencyCode
            
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
                showViewController.showTransaction = self.myJson.allTransactions.filter("madeOn == %@", self.sectionNames[indexPath.section])[indexPath.row]
                
                self.navigationController?.pushViewController(showViewController, animated:true )
                self.present(showViewController, animated: true, completion: nil)
            }
            
            let edit = UITableViewRowAction(style: .default, title: "Edit") { (action, indexPath) in
                let editViewController = self.storyboard?.instantiateViewController(withIdentifier: "EditViewController") as! EditViewController
                editViewController.delegate = self
                self.editTransaction = self.myJson.allTransactions.filter("madeOn == %@", self.sectionNames[indexPath.section])[indexPath.row]
                editViewController.categoryToUpdate = (self.myJson.allTransactions.filter("madeOn == %@", self.sectionNames[indexPath.section])[indexPath.row]).category!
                editViewController.noteToUpdate = (self.myJson.allTransactions.filter("madeOn == %@", self.sectionNames[indexPath.section])[indexPath.row]).descriptionOfTransaction!
                editViewController.labelInformation = (self.myJson.allTransactions.filter("madeOn == %@", self.sectionNames[indexPath.section])[indexPath.row]).payee!
                
                self.editRow = indexPath.row
                self.editSection = indexPath.section
                
                self.navigationController?.pushViewController(editViewController, animated:true )
                self.present(editViewController, animated: true, completion: nil)
            }
            
            let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
                
                let deleteItem = self.myJson.allTransactions.filter("madeOn == %@", self.sectionNames[indexPath.section])[indexPath.row]
                let deletedSectionName = self.sectionNames[indexPath.section]
                
                try! realm.write({
                    realm.delete(deleteItem)
                })
                let madeOnItem = self.myJson.allTransactions.filter("madeOn == %@", deletedSectionName)
                if (!madeOnItem.isEmpty) {
                    self.tableViewTransactions.beginUpdates()
                    self.tableViewTransactions.deleteRows(at: [indexPath], with: .automatic)
                    self.tableViewTransactions.endUpdates()
                } else {
                    self.tableViewTransactions.beginUpdates()
                    let indexSet = NSMutableIndexSet()
                    indexSet.add(indexPath.section)
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
extension AccountAndTransactionsViewController: editedTransactionDelegate {
    //update Transactions
    func sendBackCategory(_ sendBackCategory: CategoryTransaction, sendBackNote: String) {
        
        let item = myJson.allTransactions.filter("madeOn == %@", sectionNames[editSection])[editRow]
        
        try! realm.write {
            realm.create(Transaction.self, value: ["id": editTransaction?.id, "Category": sendBackCategory, "Description": sendBackNote], update: true) ///???category or categoryid
            item.descriptionOfTransaction = sendBackNote
            item.category = sendBackCategory
        }
        
        let indexPath = IndexPath(item: editRow, section: editSection)
        tableViewTransactions.beginUpdates()
        tableViewTransactions.reloadRows(at: [indexPath], with: .top)
        tableViewTransactions.endUpdates()
    }
}

//MARK: - addingTransactionDelegate
extension AccountAndTransactionsViewController: addingTransactionDelegate {
    func addingDelegate(_ addTransaction: Transaction) {
        // Subtracten from Accounts
        let id = addTransaction.account_id
        let acc = realm.object(ofType: Account.self, forPrimaryKey: id)!
        addTransaction.currencyCode = acc.currencyCode
        try! realm.write {
            acc.setValue(acc.balance_millicents + addTransaction.amount_millicents, forKeyPath: "balance_millicents")
        }
        //let cellIndex:IndexPath!
        //update TableView (Accounts)
        for i in 0...myJson.allAccounts.count-1{
            let indexPath = IndexPath(item: i, section: 0)
            let cell: UITableViewCell = tableViewAccounts.dequeueReusableCell(withIdentifier: "AccountCellID", for:indexPath )
            if cell.textLabel?.text == acc.name {
                //cellIndex = indexPath
                return
            }
        }
        //save in Realm
        try! realm.write({
            realm.add(addTransaction)
        })
        tableViewTransactions.reloadData()
    }
}
