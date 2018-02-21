  //
//  AccountViewController.swift
//  Exmoney
//
//  Created by Damir Gaynetdinov on 09/02/2017.
//  Copyright © 2017 Damir Gaynetdinov. All rights reserved.
//

import UIKit
import RealmSwift
import Floaty
import Reachability

 
 class TransactionViewCell: UITableViewCell{
    
    var Category: UILabel!
    var Amount: UILabel!
    var Description: UILabel!

  }

class AccountViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, writeValueBackDelegate, addingTransactionDelegate {
    

    @IBOutlet weak var viewHeightConatraint: NSLayoutConstraint!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var accountBarItem: UINavigationItem!
    
    let floaty = Floaty()
    
    var elements = AccountsList()
    var transactions = TransactionsList()
    var categoryList = CategoryTransactionList()
    
    var DashboardElement : Results<Account>!
    var AllTransaction : Results<Transaction>!
    var AllCategory : Results<CategoryTransaction>!
    
    //let userDefaults = Foundation.UserDefaults.standard
    var isEditingMode = false
    
    var dateFormatt:DateFormatter = DateFormatter()
    
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
    var logInfoId = 0
    
    var flagConnectionChanged = false
    
    var reachability = Reachability()!
    
    func calculateHightOfTableView(rowCount:Int, rowHeight:CGFloat, numberOfSections:Int, sectionHeaderHeight:CGFloat) -> CGFloat{
        //let topHeight = tableView.frame.maxY
        let height:CGFloat = (CGFloat(rowCount) + 25) * rowHeight + CGFloat(numberOfSections) * sectionHeaderHeight + 500
        return height
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView2.isScrollEnabled = false
        
        dateFormatt.dateFormat = "yyyy-MM-dd"

        accountBarItem.title = "ExMoney"
        
        //add floating button
        floaty.buttonColor = UIColor.orange
        let item = FloatyItem()
        item.buttonColor = UIColor.orange
        item.title = "Add"
        item.icon = UIImage(named: "Image-2")!
        item.handler = {item in
            let VC = self.storyboard?.instantiateViewController(withIdentifier: "AddTransactionViewController") as! AddTransactionViewController
            VC.delegateTransaction = self
            self.present(VC, animated: true, completion: nil)
            
        }
        floaty.addItem(item: item)
        /*floaty.addItem("Add", buttonColor: UIColor.orange, icon: UIImage(named: "Image")!, handler: {item in
            let VC = self.storyboard?.instantiateViewController(withIdentifier: "AddTransactionViewController") as! AddTransactionViewController
            VC.delegateTransaction = self
            self.present(VC, animated: true, completion: nil)

        })*/
        //fab.sticky = true
        self.view.addSubview(floaty)

        // Reachability of WIFi and Cellular with listening
        do {
            reachability = try Reachability.init()!
        } catch {
            let messageGet:String = "Reachability can't be created"
            let alert = UIAlertController(title: "Alert", message: messageGet, preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        DispatchQueue(label: "background").async {
        NotificationCenter.default.addObserver(self, selector: #selector(self.reachabilityChanged),name: Notification.Name.reachabilityChanged,object: self.reachability)
        do{
            try self.reachability.startNotifier()
        }catch{
            let messageGet:String = "Could not start Reachabilty Notificater"
            let alert = UIAlertController(title: "Alert", message: messageGet, preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        }
        
        try! realm.write {
            realm.deleteAll()
        }
        
        //Get Accounts. method Get and save it to Realm
        getAccount()
        saveAccounts()
        
        //Get Category with method Get
        getCategory()

        //Get Transactions with method Get
        getTransactions()
 
        saveTransactionAndCategory()// save Transactions and Categories to Realm
    
        //print(realm.objects(CategoryTransaction))
        //Make an array with dashboard = true
        self.makeArray()
        self.makeSectionsArray()
        
        
        //Make empty rows in TableView invisible
        tableView.isEditing = false
        tableView.tableFooterView = UIView.init(frame: CGRect.zero)
        //self.tableView.reloadData()
        
        tableViewHeightConstraint.constant = calculateHightOfTableView(rowCount: AllTransaction.count, rowHeight: tableView2.rowHeight, numberOfSections: tableView2.numberOfSections, sectionHeaderHeight: tableView2.sectionHeaderHeight)
        viewHeightConatraint.constant =  tableViewHeightConstraint.constant
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
            let messageGet:String = "Network not reachable"
            flagConnectionChanged = true
            let alert = UIAlertController(title: "Alert", message: messageGet, preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
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
            tableView2.beginUpdates()
            tableView2.reloadRows(at: [indexPath], with: .top)
            tableView2.endUpdates()
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
    
    func chooseCategory(id:Int)->CategoryTransaction{
        let predicate = NSPredicate(format: "id == %@", id)
        let ct:CategoryTransaction = realm.objects(CategoryTransaction).filter(predicate).first!
        //let nameCategory:String = ct.name!
        return ct
    }
    
    //adding Transaction
    func addingDelegate(addTransaction: Transaction) {
        // Subtracten from Accounts
        let id:Int = addTransaction.account_id
        let acc:Account = realm.object(ofType: Account.self, forPrimaryKey: id)!
        let acc_currencyCode = acc.CurrencyCode
        addTransaction.CurrencyCode = acc.CurrencyCode
        try! realm.write {
            acc.setValue(acc.Balance_millicents - addTransaction.Amount_millicents, forKeyPath: "Balance_millicents")
        }
        var cellIndex:IndexPath!
        //update TableView (Accounts)
        for i in 0...DashboardElement.count-1{
            let indexPath = IndexPath(item: i, section: 0)
            let cell:UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "cellAccount", for:indexPath )
            if cell.textLabel?.text == acc.Name {
                cellIndex = indexPath
                return
            }
            
        }
        //tableView.beginUpdates()
        //tableView.reloadRows(at: [cellIndex], with: .top)
        //tableView.endUpdates()
        
        //save in DateBase
        try! realm.write({
            realm.add(addTransaction)
        })
        tableView2.reloadData()
        
        tableViewHeightConstraint.constant = calculateHightOfTableView(rowCount: AllTransaction.count, rowHeight: tableView2.rowHeight, numberOfSections: tableView2.numberOfSections, sectionHeaderHeight: tableView2.sectionHeaderHeight)
        viewHeightConatraint.constant = tableViewHeightConstraint.constant
        
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
        print(realm.objects(LogInfo.self))

    }
    
    
    func getAccount(){
        //DispatchQueue.global(qos: .userInitiated).async { }
        //get Token and url
        let token = userDefaults.string(forKey: "TokenKey")
        let url = userDefaults.string(forKey: "URLKey")
        
        //Methog Get with header Token
        let urlGet = url! + "/api/v2/accounts"
        
        let myUrl=URL(string:urlGet)
        var request = URLRequest(url:myUrl!)
        
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Token \(token!)", forHTTPHeaderField: "Authorization")
        
        request.httpMethod = "GET"
        let semaphore = DispatchSemaphore(value: 0)
        //http get
        URLSession.shared.dataTask(with: request){ data, response, error in
            guard(error == nil) else {
                
                let messageGet:String = "Error: " + error.debugDescription
                let alert = UIAlertController(title: "Alert", message: messageGet, preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                self.performSegue(withIdentifier: "passwordSeque", sender: self)
                return
            }
            
            let parseResult: NSArray
            do{
                parseResult = try JSONSerialization.jsonObject(with: data!, options: []) as! NSArray
                //print(parseResult)
                
                //parsing json and make an array of accounts
                
                for index in 0...parseResult.count-1{
                    var aObject = parseResult[index] as! [String : AnyObject]
                    let name1 = aObject["name"] as? String
                    let balance1 = aObject["balance_millicents"] as? Int
                    let currency_code1 = aObject["currency_code"] as? String
                    let show_on_dashboard1 = aObject["show_on_dashboard"] as? Bool
                    let saltage1 = aObject["saltedge_account_id"] as? Bool
                    let idAcc1 = aObject["id"] as? Int
                    let ac = Account()
                    
                    ac.Balance_millicents = balance1!
                    ac.Name = name1!
                    ac.CurrencyCode = currency_code1!
                    ac.id_acc = idAcc1!
                    if show_on_dashboard1 == true { ac.ShowOnDashboard = true}
                    else {ac.ShowOnDashboard = false}
                    if saltage1 == true { ac.SaltedgeAccountId = true}
                    else {ac.SaltedgeAccountId = false}
                    
                    //self.realm.add(ac)
                    self.elements.ListAccount.append(ac)
                    //self.elements.append(ac)
                }
                
            } catch {
                let messagePost:String = "Could not parse data as Json "
                let alert = UIAlertController(title: "Alert", message: messagePost, preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }
            semaphore.signal()
            }.resume()
        
        semaphore.wait(timeout: .distantFuture)
    }
    
    func getTransactions(){
        //DispatchQueue.global(qos: .userInitiated).async { }
        //get Token and url
        let token = userDefaults.string(forKey: "TokenKey")
        let url = userDefaults.string(forKey: "URLKey")
        
        //Methog Get with header Token
        let urlGet = url! + "/api/v2/transactions/recent"
        
        let myUrl=URL(string:urlGet)
        var request = URLRequest(url:myUrl!)
        
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Token \(token!)", forHTTPHeaderField: "Authorization")
        
        request.httpMethod = "GET"
        let semaphore = DispatchSemaphore(value: 0)
        //http get
        URLSession.shared.dataTask(with: request){ data, response, error in
            guard(error == nil) else {
                
                let messageGet:String = "Error: " + error.debugDescription
                let alert = UIAlertController(title: "Alert", message: messageGet, preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }
            
            let parseResult: NSArray
            do{
                parseResult = try JSONSerialization.jsonObject(with: data!, options: []) as! NSArray
                //print(parseResult)
                
                //parsing json and make an array of transactions
                
                for index in 0...parseResult.count-1{

                    let tr = Transaction()
                    
                    var aObject = parseResult[index] as! [String : Any]
                    
                    if let description1 = aObject["description"] as? String {tr.Description = description1} else {tr.Description = ""}
                    
                    let amount1 = aObject["amount_millicents"] as? Int //amount_millicents

                    let accountId1 = aObject["account_id"] as? Int
                    tr.account_id = accountId1!
                    
                    if let currency_code1 = aObject["currency_code"] as? String {tr.CurrencyCode = currency_code1}
                    else {
                        tr.CurrencyCode = ""
                        //let account = realm.objects(Account).filter("id_acc = 'account_id'")
                        //tr.CurrencyCode = account.first?.CurrencyCode
                    }

                    let madeOn1 = self.dateFormatt.date(from: (aObject["made_on"] as? String)!)
                    
                    let category1 = aObject["category"] as! [String:Any]
                    
                    let categoryTr = CategoryTransaction()
                    categoryTr.id = (category1["id"] as? Int)!
                    categoryTr.name = (category1["name"] as? String)!
                    
                    tr.Category = categoryTr
                    
                    let info1 = aObject["transaction_info"] as? [String:Any]
                    if (info1 == nil){
                        tr.Payee = ""
                        tr.Information = ""
                        
                    }
                    else{
                        let description1 = info1?["payee"] as? String
                        tr.Payee = description1
                        let information1 = info1?["information"] as? String
                        tr.Information = information1
                    }
                    tr.Amount_millicents = amount1!
                    tr.MadeOn = madeOn1
                    tr.id = (aObject["id"] as? Int)!
                    self.transactions.ListTransaction.append(tr)
                }
                
            } catch {
                let messagePost:String = "Could not parse data as Json "
                let alert = UIAlertController(title: "Alert", message: messagePost, preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }
            semaphore.signal()
            }.resume()
        
        semaphore.wait(timeout: .distantFuture)
    }
    
    func getCategory(){
        //DispatchQueue.global(qos: .userInitiated).async { }
        //get Token and url
        let token = userDefaults.string(forKey: "TokenKey")
        let url = userDefaults.string(forKey: "URLKey")
        
        //Methog Get with header Token
        let urlGet = url! + "/api/v2/categories"
        
        let myUrl=URL(string:urlGet)
        var request = URLRequest(url:myUrl!)
        
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Token \(token!)", forHTTPHeaderField: "Authorization")
        
        request.httpMethod = "GET"
        let semaphore = DispatchSemaphore(value: 0)
        //http get
        URLSession.shared.dataTask(with: request){ data, response, error in
            guard(error == nil) else {
                
                let messageGet:String = "Error: " + error.debugDescription
                let alert = UIAlertController(title: "Alert", message: messageGet, preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }
            
            let categoryResult: NSArray
            do{
                categoryResult = try JSONSerialization.jsonObject(with: data!, options: []) as! NSArray
                //print(categoryResult.count)
                
                //parsing json and make an array of categories
                
                for index in 0...categoryResult.count-1{
                    
                    let category = CategoryTransaction()
                    
                    var aObject = categoryResult[index] as! [String:AnyObject]
                    
                    let id1 = aObject["id"] as? Int
                    category.id = id1!
                    let name1 = aObject["name"] as? String
                    category.name = name1!
                    self.categoryList.ListCategoryTransactions.append(category)
                }
                
            } catch {
                let messagePost:String = "Could not parse data as Json "
                let alert = UIAlertController(title: "Alert", message: messagePost, preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }
            semaphore.signal()
            }.resume()
        
        semaphore.wait(timeout: .distantFuture)
        //print(categoryList.ListCategoryTransactions.count)
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
    
    
        let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in

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

    }
    
    //Sending failed Transaction
    func sendTransactionToDashboard() -> Results<LogInfo>{
        let notSendedTransaction = realm.objects(LogInfo.self).filter("status = 'false'")
        notSendedTransaction.sorted(byKeyPath: "time")
        print(notSendedTransaction)
        return notSendedTransaction
    }
    
    
    func makeArray(){
    
        let predicate = NSPredicate(format: "ShowOnDashboard == 1")
        DashboardElement = realm.objects(Account.self).filter(predicate)
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
    
    func reloadTableView()
    {
        AllTransaction = realm.objects(Transaction.self)
        tableView.setEditing(false, animated: true)
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if (tableView == tableView2){
            return true
        }
        else {return false}
    }
    
    func getNewTransactionID() -> Int{
        let allEntries = realm.objects(LogInfo.self)
        if allEntries.count > 0 {
            let lastId = allEntries.max(ofProperty: "id") as Int?
            return lastId! + 1
        }
        else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        if (tableView == tableView2){
        let show = UITableViewRowAction(style: .destructive, title: "Show") { (action, indexPath) in
            let showViewController = self.storyboard?.instantiateViewController(withIdentifier: "ShowViewController") as! ShowViewController
            //self.performSegue(withIdentifier: "showSeque", sender: self)
            
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
             //+++delete sections if there is no item
            let madeOnItem = self.AllTransaction.filter("MadeOn == %@", deletedSectionName)
            if (!madeOnItem.isEmpty){
                self.tableView2.beginUpdates()
                self.tableView2.deleteRows(at: [indexPath], with: .automatic)
                self.tableView2.endUpdates()
                }
            else {
                self.tableView2.beginUpdates()
                let indexSet = NSMutableIndexSet()
                indexSet.add(indexPath.section-1)
                //self.tableView2.deleteRows(at: [indexPath], with: .automatic)
                self.tableView2.deleteSections(indexSet as IndexSet, with: .automatic)
                self.tableView2.endUpdates()

                //change reloadData to begin and endUpdate()
            //self.tableView2.reloadData()
            }
            self.tableViewHeightConstraint.constant = self.calculateHightOfTableView(rowCount: self.AllTransaction.count, rowHeight: self.tableView2.rowHeight, numberOfSections: self.tableView2.numberOfSections, sectionHeaderHeight: self.tableView2.sectionHeaderHeight)
            
            self.viewHeightConatraint.constant = self.tableViewHeightConstraint.constant

        }
        
        edit.backgroundColor = UIColor.orange
        
        return [delete, edit, show]
        }
        else{
            tableView.isEditing = false
            return nil
            
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        reloadTableView()
        ///??? what for?
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if (tableView == tableView2){
            return sectionNames.count}
        else {return 1}
    }
    
    /*func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if (tableView == tableView2){
            return sectionNames as [String]}
        else {return nil}
    }*/
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        var count:Int?
        
        if tableView == self.tableView {
            count = DashboardElement.count
        }
        
        if tableView == self.tableView2 {
            count = AllTransaction.filter("MadeOn == %@", sectionNames[section]).count
        }
        
        return count!
        
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var item:String?
        if tableView == self.tableView {
            item = ""
        }
        if tableView == self.tableView2 {
            item = dateFormatt.string(from: self.sectionNames[section])//formatter.stringFromDate(self.sortedArray![section] as! NSDate)
        }
        return item!
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
       if tableView == self.tableView {
            let cell:UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "cellAccount", for:indexPath )
            let acc = DashboardElement[indexPath.row]
            cell.textLabel?.font = UIFont(name: "Georgia", size: 15.0)
            cell.detailTextLabel?.font = UIFont(name: "Helvetica Neue", size: 15.0)
            cell.textLabel?.text = acc.Name
            cell.detailTextLabel?.text = amountToString(amount_millic: acc.Balance_millicents) + " " + getSymbolForCurrencyCode(code: acc.CurrencyCode)!
            return cell
        }
        
        else {
            let cell = tableView2.dequeueReusableCell(withIdentifier:"cellTransaction", for: indexPath) as! TransactionViewCell
            cell.Category.font = UIFont(name: "Georgia", size: 15.0)
            cell.Amount.font = UIFont(name: "Helvetica Neue", size: 14.0)
            cell.Description.font = UIFont.boldSystemFont(ofSize: 14.0)
        
            cell.Category?.text = AllTransaction.filter("MadeOn == %@", sectionNames[indexPath.section])[indexPath.row].Category?.name
        
        
            cell.Amount?.text = amountToString(amount_millic: AllTransaction.filter("MadeOn == %@", sectionNames[indexPath.section])[indexPath.row].Amount_millicents) + " " + getSymbolForCurrencyCode(code: AllTransaction.filter("MadeOn == %@", sectionNames[indexPath.section])[indexPath.row].CurrencyCode!)!
        
        if (AllTransaction.filter("MadeOn == %@", sectionNames[indexPath.section])[indexPath.row].Payee != nil){
            cell.Description?.text = self.AllTransaction.filter("MadeOn == %@", self.sectionNames[indexPath.section])[indexPath.row].Payee!}
        else {cell.Description?.text = "Cash"}
        return cell
        }
            //
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        var headerView: UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
        headerView.textLabel?.textColor = UIColor.lightGray
    }
    
    
    
    func amountToString(amount_millic: Int) ->String
    {
        let stringAmount:String
        let decimalAmount:Decimal
        decimalAmount = Decimal(amount_millic)
        stringAmount = String(describing: decimalAmount/1000)
        return stringAmount
    }
    
    
    func saveAccounts()
    {
        try! realm.write {
            
            //add Accounts to Realm
            for i in 0...elements.ListAccount.count-1{
            realm.add(elements.ListAccount[i])
            }
        }
    }
    
    
    func saveTransactionAndCategory()
    {
        try! realm.write {
        //add Transactions to Realm
        for i in 0...transactions.ListTransaction.count-1{
            if (transactions.ListTransaction[i].CurrencyCode == "")
            {
                let account = realm.object(ofType: Account.self, forPrimaryKey: transactions.ListTransaction[i].account_id) 
                transactions.ListTransaction[i].CurrencyCode = account?.CurrencyCode
            }
            realm.add(transactions.ListTransaction[i], update:true)
        }

        //add Category to Realm
        for i in 0...categoryList.ListCategoryTransactions.count-1{
            realm.add(categoryList.ListCategoryTransactions[i], update: true)
        }
        }

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

    @IBOutlet weak var tableView2: UITableView!
    
    @IBOutlet weak var tableView: UITableView! 
}


