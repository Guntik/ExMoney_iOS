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
//import ReachabilitySwift
    
extension Decimal {
    var doubleValue:Double {
        return NSDecimalNumber(decimal:self).doubleValue
    }
}

class AccountAndTransactionsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, writeValueBackDelegate, addingTransactionDelegate {

    var tableViewAccounts: UITableView!
    let floaty = Floaty()
    
    var accountList = AccountsList()
    var transactions = TransactionsList()
    var categoryList = CategoryTransactionList()
    
    var AllAccounts : Results<Account>!
    var AllTransaction : Results<Transaction>!
    var AllCategory : Results<CategoryTransaction>!
    
    //let userDefaults = Foundation.UserDefaults.standard
    var isEditingMode = false
    
    var editRow:Int = 0
    var editSection:Int = 0
    
    // for sections in TableView
    var sectionNames: [Date] {
        return Set(AllTransaction.value(forKeyPath: "MadeOn") as! [Date]).sorted(by: { $0.compare($1) == .orderedDescending})}
    
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
    
    var activityIndicator = UIActivityIndicatorView()
    let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        try! realm.write {
            realm.deleteAll()
        }
 
        createFloatButton()
        setReachability()
        //Getting accounts and save them to Realm
        getAccount()
        saveAccounts()
        //Get Category
        getCategory()
        //Get Transactions
        getTransactions()
        saveTransaction() //save Transactions
        saveCategory() //save Category
        
        //Make an array with dashboard = true
        self.makeArray()
        self.makeSectionsArray()
        //makeExpendedCategories()
        
        tableViewTransactions.estimatedSectionHeaderHeight = 40
        self.automaticallyAdjustsScrollViewInsets = false
        
        dateFormatt.dateFormat = "yyyy-MM-dd"
        
        tableViewAccounts = UITableView()

        let header = UIView(frame: CGRect(x: 0, y: 0, width: Int(tableViewTransactions.frame.width), height: heightOfTableView()))
        tableViewTransactions.tableHeaderView = header
        includTableViewInHeader(view: header, tableView: tableViewAccounts)
        
        //register customCell
        //tableViewTransactions.register(TransactionCell.self, forCellReuseIdentifier: "CellID")
        
        
        //Pull-to-refresh
        refreshControl.tintColor = UIColor.red
        refreshControl.addTarget(self, action: #selector(AccountAndTransactionsViewController.handleRefresh(refreshControl:)), for: UIControlEvents.valueChanged)
        self.tableViewTransactions.addSubview(self.refreshControl)
        
        setWidthOfTables()
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
        
        height = AllAccounts.count * rowHeightAccountsTableView + 2 * lableHeight + 2 * gapY
        
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
    func setReachability(){
        do {
            reachability = try Reachability.init()!
        } catch {
            self.showMessage(messageString: "Reachability can't be created")
            return
        }
        
        DispatchQueue(label: "background").async {
            NotificationCenter.default.addObserver(self, selector: #selector(self.reachabilityChanged),name: Notification.Name.reachabilityChanged,object: self.reachability)
            do{
                try self.reachability.startNotifier()
            }catch{
                self.showMessage(messageString: "Could not start Reachabilty Notificater")
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
                if(self.flagConnectionChanged && self.sendTransactionToDashboard().count != nil){
                    for i in 0 ... self.sendTransactionToDashboard().count - 1{
                        self.postTransaction(SendingTransaction: self.sendTransactionToDashboard()[i])
                    }
                }
            }
            
        } else {
            flagConnectionChanged = true
            showMessage(messageString: "Network not reachable")
            return
        }
    }

    
    //update Transactions
    func writeValueBack(sendBackCategory: CategoryTransaction, sendBackNote: String) {
        if (sendBackCategory != nil && sendBackNote != nil) {
            let item = AllTransaction.filter("MadeOn == %@", sectionNames[editSection])[editRow]
            
            try! realm.write {
                realm.create(Transaction.self, value: ["id": editTransaction?.id, "Category": sendBackCategory, "Description": sendBackNote], update: true) ///???category or categoryid
                item.Description = sendBackNote
                item.Category = sendBackCategory
            }
            
            let indexPath = IndexPath(item: editRow, section: editSection)
            tableViewTransactions.beginUpdates()
            tableViewTransactions.reloadRows(at: [indexPath], with: .top)
            tableViewTransactions.endUpdates()
            //tableView2.reloadData()
            
            //write updated Transaction in Log
            let updateTransaction = realm.object(ofType: Transaction.self, forPrimaryKey: self.editTransaction.id) as! Transaction
            let updateLogTransaction = LogInfo()
            
            //
            let date = NSDate()
            
            let data = "{\"id\": \(updateTransaction.id), \"description\": \"\(updateTransaction.Description!)\", \"category\": \((updateTransaction.Category?.id)!), \"action\": \"update\"}"//.data(using: .utf8)!
            let logItem = LogInfo()
            logItem.Transaction = data
            logItem.status = false
            logItem.time = date
            logItem.id = logInfoId + 1
            logInfoId = logItem.id
            
            try! realm.write {
                //let json = try! JSONSerialization.jsonObject(with: data, options: [])
                realm.add(logItem)
            }
        }
        
    }

    func addingDelegate(addTransaction: Transaction) {
        // Subtracten from Accounts
        let id:Int = addTransaction.account_id
        let acc:Account = realm.object(ofType: Account.self, forPrimaryKey: id)!
        let acc_currencyCode = acc.CurrencyCode
        addTransaction.CurrencyCode = acc.CurrencyCode
        try! realm.write {
            acc.setValue(acc.Balance_millicents + addTransaction.Amount_millicents, forKeyPath: "Balance_millicents")
        }
        var cellIndex:IndexPath!
        //update TableView (Accounts)
        for i in 0...AllAccounts.count-1{
            let indexPath = IndexPath(item: i, section: 0)
            let cell: UITableViewCell = tableViewAccounts.dequeueReusableCell(withIdentifier: "AccountCellID", for:indexPath )
            if cell.textLabel?.text == acc.Name {
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
        
        let data = "{\"account_id\": \(addTransaction.account_id), \"id\": \(addTransaction.id), \"amount_millicents\":\(addTransaction.Amount_millicents), \"category\": \((addTransaction.Category?.id)!), \"made_on\": \"\(String(describing: addTransaction.MadeOn!))\", \"currency_code\": \"\(addTransaction.CurrencyCode!)\", \"payee\": \"\(addTransaction.Description!)\", \"description\": \"\(addTransaction.Description!)\", \"action\": \"add\"}"//.data(using: .utf8)!
        let logItem = LogInfo()
        logItem.Transaction = data
        logItem.time = date
        logItem.status = false
        logItem.id = logInfoId + 1
        logInfoId = logItem.id
        
        try! realm.write {
            //let json = try! JSONSerialization.jsonObject(with: data, options: [])
            realm.add(logItem)
        }
        
    }
    func setRequest(urlAddition: String) -> URLRequest {
        //get Token and url
        let token = userDefaults.string(forKey: "TokenKey")
        let url = userDefaults.string(forKey: "URLKey")
        
        //Methog Get with header Token
        let urlGet = url! + urlAddition
        
        let myUrl=URL(string:urlGet)
        var request = URLRequest(url:myUrl!)
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Token \(token!)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        
        return request
    }
    
    func getAccount(){
        let request = self.setRequest(urlAddition: "/api/v2/accounts")
        let semaphore = DispatchSemaphore(value: 0)
        
        URLSession.shared.dataTask(with: request){
            data, response, error in
            guard(error == nil) else {
                self.showMessage(messageString: "Error: " + error.debugDescription)
                self.performSegue(withIdentifier: "passwordSeque1", sender: self)
                //self.performSegue(withIdentifier: "passwordSeque", sender: self)
                return
            }
            let parseResult: NSArray
            do{
                
                parseResult = try JSONSerialization.jsonObject(with: data!, options: []) as! NSArray
                for index in 0...parseResult.count-1{
                    let account = Account(jsonArray: parseResult[index] as! [String : AnyObject])
                    self.accountList.ListAccount.append(account)
                }
            } catch {
                
                self.showMessage(messageString: "Could not parse data as Json")
                return
            }
            semaphore.signal()
            }.resume()
        
        semaphore.wait(timeout: .distantFuture)
    }
    
    func getTransactions(){
        let request = setRequest(urlAddition: "/api/v2/transactions/recent")
        
        let semaphore = DispatchSemaphore(value: 0)
        //http get
        URLSession.shared.dataTask(with: request){
            data, response, error in
            guard(error == nil) else {
                self.showMessage(messageString: "Error: " + error.debugDescription)
                self.performSegue(withIdentifier: "passwordSeque", sender: self)
                return
            }
            
            let parseResult: NSArray
            do{
                parseResult = try JSONSerialization.jsonObject(with: data!, options: []) as! NSArray
                //parsing json and make an array of transactions
                for index in 0...parseResult.count-1{
                    let transaction = Transaction(jsonArray: parseResult[index] as! [String : AnyObject])
                    self.transactions.ListTransaction.append(transaction)
                }
                
            } catch {
                self.showMessage(messageString: "Could not parse data as Json")
                return
            }
            semaphore.signal()
            }.resume()
        
        semaphore.wait(timeout: .distantFuture)
    }
    
    func getCategory(){
        //DispatchQueue.global(qos: .userInitiated).async { }
        let request = setRequest(urlAddition: "/api/v2/categories")
        
        let semaphore = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: request){
            data, response, error in
            guard(error == nil) else {

                self.showMessage(messageString: "Error: " + error.debugDescription)
                return
            }
            
            let categoryResult: NSArray
            do{
                
                categoryResult = try JSONSerialization.jsonObject(with: data!, options: []) as! NSArray
                
                //parsing json and make an array of categories
                for index in 0...categoryResult.count-1{
                    
                    let category = CategoryTransaction(jsonArray: categoryResult[index] as! [String : AnyObject])
                    self.categoryList.ListCategoryTransactions.append(category)
                }
                
            } catch {
                self.showMessage(messageString: "Could not parse data as Json")
                return
            }
            semaphore.signal()
            }.resume()
        
        semaphore.wait(timeout: .distantFuture)
    }
    
    // Sending Transaction
    func postTransaction(SendingTransaction:LogInfo){
        
        let url = userDefaults.string(forKey: "URLKey")
        //Method Post
        let urlPost = url! + "/api/v2/categories"
        let myUrl=URL(string:urlPost)
        
        //async
        let semaphore = DispatchSemaphore(value: 0)
        
        var request = URLRequest(url:myUrl!)
        
        request.httpMethod = "POST"
        
        request.httpBody=SendingTransaction.Transaction.data(using: String.Encoding.utf8)
        
        
        let task = URLSession.shared.dataTask(with: request) {
            (data: Data?, response: URLResponse?, error: Error?) in
            
            guard error == nil && data != nil else {
                
                print("error=\(error)")
                return
            }
            
            //Convert response
            do {
                let responseJSON = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String:AnyObject]
                
                print(responseJSON)
                print(responseJSON?["status"]!)
                
                let responseStatus = responseJSON?["status"] as? Int
                
                print(responseStatus)
                
                
                //Check response from the sever
                if responseStatus! == 200
                {
                    OperationQueue.main.addOperation {
                        realm.delete(SendingTransaction)
                        //API call Successful and can perform other operatios
                        print("Transaction send successfully")
                    }
                }
                    
                else
                {
                    print("Sending Failed")
                }
                
            } catch {
                self.showMessage(messageString: "Try it again")
                return
            }
            semaphore.signal()
        }
        task.resume()
        semaphore.wait(timeout: .distantFuture)
        
    }
    
    //Sending failed Transaction
    func sendTransactionToDashboard() -> Results<LogInfo>{
        let notSendedTransaction = realm.objects(LogInfo.self).filter("status = 'false'")
        notSendedTransaction.sorted(byKeyPath: "time")
        print(notSendedTransaction)
        return notSendedTransaction
    }

    
    func showMessage(messageString: String){
        let alert = UIAlertController(title: "Alert", message: messageString, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func includTableViewInHeader(view: UIView, tableView: UITableView)
    {
        tableView.dataSource = self
        tableView.delegate = self
        
        let AccountsLabel: UILabel!
        let TransactionsLabel: UILabel!
        
        AccountsLabel = UILabel()
        AccountsLabel.text = "Accounts"
        AccountsLabel.frame = CGRect(x: 20, y: 10, width: Int(view.frame.width), height: lableHeight)
        AccountsLabel.textColor = UIColor.black //UIColor.orange
        AccountsLabel.font = UIFont.boldSystemFont(ofSize: 20.0)
        view.addSubview(AccountsLabel)
        
        tableView.frame = CGRect(x: 0, y: 40, width: view.frame.width, height: view.frame.height - CGFloat(lableHeight) - 20)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "AccountCellID")
        view.addSubview(tableView)
        tableView.tableFooterView = UIView.init(frame: CGRect.zero)
        
        TransactionsLabel = UILabel()
        TransactionsLabel.text = "Transactions"
        TransactionsLabel.frame = CGRect(x: 20, y: view.frame.height - CGFloat(lableHeight)-10, width: view.frame.width, height: CGFloat(lableHeight))
        TransactionsLabel.textColor = UIColor.black//UIColor.orange
        TransactionsLabel.font = UIFont.boldSystemFont(ofSize: 20.0)
        view.addSubview(TransactionsLabel)
    }
    
    func handleRefresh(refreshControl: UIRefreshControl) {

        
        self.tableViewTransactions.reloadData()
        refreshControl.endRefreshing()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count:Int?
        
        if tableView == self.tableViewAccounts {
            count = AllAccounts.count
        }
        
        if tableView == self.tableViewTransactions {
            count = AllTransaction.filter("MadeOn == %@", sectionNames[section]).count
        }
        
        return count!
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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if (tableView == tableViewTransactions){
            return sectionNames.count}
        else {return 1}
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == self.tableViewTransactions {
            let cell = Bundle.main.loadNibNamed("TransactionTableViewCell", owner: self, options: nil)?.first as! TransactionTableViewCell
            //let cell = TransactionCell(style: UITableViewCellStyle.default, reuseIdentifier: "CellID")
            if let code1 = AllTransaction.filter("MadeOn == %@", sectionNames[indexPath.section])[indexPath.row].CurrencyCode {
                cell.AmountLbl.text = amountToString(amount_millic: AllTransaction.filter("MadeOn == %@", sectionNames[indexPath.section])[indexPath.row].Amount_millicents) + " " + getSymbolForCurrencyCode(code: AllTransaction.filter("MadeOn == %@", sectionNames[indexPath.section])[indexPath.row].CurrencyCode!)!}
                //cell.Amount.text = amountToString(amount_millic: AllTransaction.filter("MadeOn == %@", sectionNames[indexPath.section])[indexPath.row].Amount_millicents) + " " + getSymbolForCurrencyCode(code: AllTransaction.filter("MadeOn == %@", sectionNames[indexPath.section])[indexPath.row].CurrencyCode!)!}
            else {
                cell.AmountLbl.text = amountToString(amount_millic: AllTransaction.filter("MadeOn == %@", sectionNames[indexPath.section])[indexPath.row].Amount_millicents)
                //cell.Amount.text = amountToString(amount_millic: AllTransaction.filter("MadeOn == %@", sectionNames[indexPath.section])[indexPath.row].Amount_millicents)*/
            }
            
            cell.CategoryLbl.text = AllTransaction.filter("MadeOn == %@", sectionNames[indexPath.section])[indexPath.row].Category?.name
            //cell.Category.text = AllTransaction.filter("MadeOn == %@", sectionNames[indexPath.section])[indexPath.row].Category?.name
            
            if (AllTransaction.filter("MadeOn == %@", sectionNames[indexPath.section])[indexPath.row].Payee != nil){
                cell.DescriptionLbl.text = self.AllTransaction.filter("MadeOn == %@", self.sectionNames[indexPath.section])[indexPath.row].Payee!}
                //cell.Description?.text = self.AllTransaction.filter("MadeOn == %@", self.sectionNames[indexPath.section])[indexPath.row].Payee!}
            else {
                cell.DescriptionLbl.text = "Cash"
                //cell.Description?.text = "Cash"
            }
            
            return cell
        }
        else{
            let cell = Bundle.main.loadNibNamed("AccountTableViewCell", owner: self, options: nil)?.first as! AccountTableViewCell
            let acc = AllAccounts[indexPath.row]
            cell.AccountLbl.text = acc.Name
            cell.BalanceLbl.text = amountToString(amount_millic: Int(acc.Balance_millicents)) + " " + getSymbolForCurrencyCode(code: acc.CurrencyCode)!

            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if tableView == self.tableViewTransactions{
            return true
        } else{
            return false
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        if (tableView == tableViewTransactions){
            let show = UITableViewRowAction(style: .destructive, title: "Show") { (action, indexPath) in
                let showViewController = self.storyboard?.instantiateViewController(withIdentifier: "ShowTransactionView") as! ShowTransactionViewController
                showViewController.showTransaction = self.AllTransaction.filter("MadeOn == %@", self.sectionNames[indexPath.section])[indexPath.row]
                
                self.navigationController?.pushViewController(showViewController, animated:true )
                self.present(showViewController, animated: true, completion: nil)
            }
            
            let edit = UITableViewRowAction(style: .default, title: "Edit") { (action, indexPath) in
                let editViewController = self.storyboard?.instantiateViewController(withIdentifier: "EditViewController") as! EditViewController
                editViewController.delegate = self
                self.editTransaction = self.AllTransaction.filter("MadeOn == %@", self.sectionNames[indexPath.section])[indexPath.row]
                editViewController.categoryToUpdate = (self.AllTransaction.filter("MadeOn == %@", self.sectionNames[indexPath.section])[indexPath.row]).Category!
                editViewController.noteToUpdate = (self.AllTransaction.filter("MadeOn == %@", self.sectionNames[indexPath.section])[indexPath.row]).Description!
                editViewController.labelInformation = (self.AllTransaction.filter("MadeOn == %@", self.sectionNames[indexPath.section])[indexPath.row]).Payee!
                
                self.editRow = indexPath.row
                self.editSection = indexPath.section
                
                self.navigationController?.pushViewController(editViewController, animated:true )
                self.present(editViewController, animated: true, completion: nil)
            }
            
            let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
                
                let deleteItem = self.AllTransaction.filter("MadeOn == %@", self.sectionNames[indexPath.section])[indexPath.row]
                let deletedSectionName = self.sectionNames[indexPath.section]
                
                let date = NSDate()
                let data = "{\"id\": \(deleteItem.id), \"action\": \"delete\"}"//.data(using: .utf8)!
                let logItem = LogInfo()
                logItem.Transaction = data
                logItem.status = false
                logItem.time = date
                logItem.id = self.logInfoId + 1
                self.logInfoId = logItem.id
                
                try! realm.write {
                    //let json = try! JSONSerialization.jsonObject(with: data, options: [])
                    realm.add(logItem)
                }
                
                try! realm.write({
                    realm.delete(deleteItem)
                })
                //self.tableView2.beginUpdates()
                let madeOnItem = self.AllTransaction.filter("MadeOn == %@", deletedSectionName)
                if (!madeOnItem.isEmpty){
                    self.tableViewTransactions.beginUpdates()
                    self.tableViewTransactions.deleteRows(at: [indexPath], with: .automatic)
                    self.tableViewTransactions.endUpdates()
                }
                else {
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
        }
        else{
            tableView.isEditing = false
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == self.tableViewTransactions{
            return 70
        } else{
            return 40
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //preparing for ShowTransactionViewControllSegue
        if (segue.identifier == "showSegue"){
            let showViewController = segue.destination as! ShowTransactionViewController
            showViewController
        }
    }

    func saveAccounts()
    {
        try! realm.write {
            //add Accounts to Realm
            for i in 0...accountList.ListAccount.count-1{
                realm.add(accountList.ListAccount[i])
            }
        }
    }
    
    
    func saveTransaction()
    {
        try! realm.write {
            for i in 0...transactions.ListTransaction.count-1{
                if (transactions.ListTransaction[i].CurrencyCode == "")
                {
                    let account = realm.object(ofType: Account.self, forPrimaryKey: transactions.ListTransaction[i].account_id)
                    transactions.ListTransaction[i].CurrencyCode = account?.CurrencyCode
                }
                realm.add(transactions.ListTransaction[i], update:true)
            }
        }
    }
    
    func saveCategory(){
        try! realm.write {
            for i in 0...categoryList.ListCategoryTransactions.count-1{
                realm.add(categoryList.ListCategoryTransactions[i], update:true)
            }
        }
    }
    
    func makeArray(){
        let predicate = NSPredicate(format: "ShowOnDashboard == 1")
        AllAccounts = realm.objects(Account.self).filter(predicate)
        return
    }
    
    func makeCategoryArray(){
        AllCategory = realm.objects(CategoryTransaction.self)
    }
    
    
    func makeSectionsArray() {
        let spDate:Date = Calendar.current.date(byAdding: .day, value: -15, to: Date())!
        
        let predicate = NSPredicate(format: "MadeOn > %@", spDate as CVarArg) //+predicate 15 days
        
        AllTransaction = realm.objects(Transaction.self).filter(predicate).sorted(by: ["MadeOn", "Description"])
        //AllTransaction = realm.objects(Transaction).sorted(by: ["MadeOn"])
    }
    
    func makeExpendedCategories(){
        let resultOfCategories = realm.objects(CategoryTransaction.self).filter("parent == 1")
        for i in 0...resultOfCategories.count - 1{
            let newCategory = CategoryTransaction()
            newCategory.name = resultOfCategories[i].name
            newCategory.parent = false
            newCategory.id = getNewTransactionID(objectType: CategoryTransaction.self)
            newCategory.parent_id = resultOfCategories[i].parent_id
            try! realm.write {
                realm.add(newCategory, update: true)
            }
        }
        print("!!!")
        print(realm.objects(CategoryTransaction.self))
    }
    
    //get currency symbol from currency code
    func getSymbolForCurrencyCode(code: String) -> String? {
        if (code == "RUB"){
            let symbol:String = "₽"
            return symbol
        }
        else {
            let locale = NSLocale(localeIdentifier: code)
            let symbol = locale.displayName(forKey: NSLocale.Key.currencySymbol, value: code)
            return symbol
        }
    }
    
    func getNewTransactionID(objectType: Object.Type) -> Int{
        let allEntries = realm.objects(objectType)
        if allEntries.count > 0 {
            let lastId = allEntries.max(ofProperty: "id") as Int?
            return lastId! + 1
        }
        else {
            return 1
        }
    }
    
    func amountToString(amount_millic: Int) ->String
    {
        let stringAmount:String
        let decimalAmount:Decimal
        decimalAmount = Decimal(amount_millic)
        let d1:Double = decimalAmount.doubleValue
        stringAmount = String(describing: d1/1000)
        return stringAmount
    }



    @IBOutlet weak var tableViewTransactions: UITableView!
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}
