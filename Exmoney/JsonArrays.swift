//
//  JsonArrays.swift
//  Exmoney
//
//  Created by Damir Gaynetdinov on 14/03/2018.
//  Copyright © 2018 Damir Gaynetdinov. All rights reserved.
//

import Foundation
import RealmSwift


class MyJsonClass{
    
    var accountList = AccountsList()
    var transactions = TransactionsList()
    var categoryList = CategoryTransactionList()
    var updatingTransactions = UpdatingTransactionList()
    
    var allAccounts : Results<Account>!
    var allTransaction : Results<Transaction>!
    var allCategory : Results<CategoryTransaction>!
    
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
    
    func showMessage(messageString: String){
        let alert = UIAlertController(title: "Alert", message: messageString, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
       // self.present(alert, animated: true, completion: nil)
    }
    
    func getAccount(){
        let request = self.setRequest(urlAddition: "/api/v2/accounts")
        let semaphore = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: request){
            data, response, error in
            guard(error == nil) else {
                self.showMessage(messageString: "Error: " + error.debugDescription)
                let vc = AccountAndTransactionsViewController()
                vc.performSegue(withIdentifier: "passwordSeque1", sender: self)
                return
            }
            let parseResult: NSArray
            do{
                parseResult = try JSONSerialization.jsonObject(with: data!, options: []) as! NSArray
                for index in 0...parseResult.count-1{
                    let account = Account(jsonArray: parseResult[index] as! [String : AnyObject])
                    self.accountList.listAccount.append(account)
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
                let vc = AccountAndTransactionsViewController() //????
                vc.performSegue(withIdentifier: "passwordSeque", sender: self)
                return
            }
            let parseResult: NSArray
            do {
                parseResult = try JSONSerialization.jsonObject(with: data!, options: []) as! NSArray
                //parsing json and make an array of transactions
                for index in 0...parseResult.count-1{
                    let transaction = Transaction(jsonArray: parseResult[index] as! [String : AnyObject])
                    self.transactions.listTransaction.append(transaction)
                }
               // print(transactions)
            } catch {
                self.showMessage(messageString: "Could not parse data as Json")
                return
            }
            semaphore.signal()
            }.resume()
        semaphore.wait(timeout: .distantFuture)
    }
    
    func getCategory(){
        let request = setRequest(urlAddition: "/api/v2/categories")
        
        let semaphore = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: request){
            data, response, error in
            guard(error == nil) else {
                self.showMessage(messageString: "Error: " + error.debugDescription)
                return
            }
            let categoryResult: NSArray
            do {
                categoryResult = try JSONSerialization.jsonObject(with: data!, options: []) as! NSArray
                //parsing json and make an array of categories
                for index in 0...categoryResult.count-1{
                    
                    let category = CategoryTransaction(jsonArray: categoryResult[index] as! [String : AnyObject])
                    self.categoryList.listCategoryTransactions.append(category)
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
    func postTransaction(SendingUUID:String){
        
        let url = userDefaults.string(forKey: "URLKey")
        let token = userDefaults.string(forKey: "TokenKey")
        //Method Post
        let urlPost = url! + "/api/v2/sync"
        let myUrl=URL(string:urlPost)
        
        //async
        //let semaphore = DispatchSemaphore(value: 0)
        
        var request = URLRequest(url:myUrl!)
        
        let jsonDict = ["uuid": SendingUUID] as [String: Any]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: jsonDict, options: .prettyPrinted) // pass dictionary to nsdata object and set it as request body
        } catch let error {
            print(error.localizedDescription)
        }
        
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Token \(token!)", forHTTPHeaderField: "Authorization")
        
        //let parameters = ["uuid": SendingUUID] as [String: String]
        //request.httpBody = jsonData as! Data
        //do {
        //request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) // pass dictionary to nsdata object and set it as request body
        
        //} catch let error {
        // print(error.localizedDescription)
        //}
        
        
        //let task = URLSession.shared.dataTask(with: request) {
        //(data: Data?, response: URLResponse?, error: Error?) in
        // guard error == nil && data != nil else {
        //    print("error=\(error)")
        //    return
        // }
        
        //Convert response
        let task = URLSession.shared.dataTask(with: request as URLRequest){ data,response,error in
            if error != nil{
                return
            }
        do {
                let result = try JSONSerialization.jsonObject(with: data!, options: []) as? [String:AnyObject]
                
            } catch {
            }
        }
        /*do {
         let responseJSON = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String:AnyObject]
         print(responseJSON)
         let responseStatus = responseJSON?["status"] as? Int
         
         print(responseStatus)
         
         //Check response from the sever
         if responseStatus! == 200
         {
         //OperationQueue.main.addOperation {
         realm.delete(self.updatingTransactions.ListUpdatingResults.filter("uuid == %@", SendingUUID))
         //API call Successful and can perform other operations
         print("Transaction send successfully")
         //}
         }
         else
         {
         print("Sending Failed")
         }
         
         } catch {
         self.showMessage(messageString: "Try it again")
         return
         }
         //semaphore.signal()
         }*/
        task.resume()
        //semaphore.wait(timeout: .distantFuture)
    }
    
    func makeListOfFailedTransactions() -> Results<UpdatingTransaction>
    {
        var FailedUpdatingTransactions = realm.objects(UpdatingTransaction).filter("checkFlag == false")
        return FailedUpdatingTransactions
    }
    
    func loadAllDataFromRealm()
    {
        allAccounts = realm.objects(Account.self)
        print(allAccounts)
        if (allAccounts.count == 0) {
            getAccount()
            if (self.accountList.listAccount.count != 0) {
                saveAccounts()
            } else {
                self.showMessage(messageString: "Error: ")
            }
        }
        allTransaction = realm.objects(Transaction.self)
        if (allTransaction.count == 0){
            getTransactions()
            if (self.transactions.listTransaction.count != 0) {
                saveTransaction()
            } else {
                self.showMessage(messageString: "Error: ")
            }
        }
        allCategory = realm.objects(CategoryTransaction.self)
        if (allCategory.count == 0){
            getCategory()
            if (self.categoryList.listCategoryTransactions.count != 0) {
                saveCategory()
            } else {
                self.showMessage(messageString: "Error: ")
            }
        }
        
        //Make an array with dashboard = true
        makeArray()
        makeSectionsArray()
    }
    
    func initiateAllArrays(){
        try! realm.write {
            realm.deleteAll()
            }
        
        //Getting accounts and saving them to Realm
        getAccount()
        saveAccounts()
 
        //Get Category
        getCategory()
 
        //Get Transactions
        getTransactions()
 
        saveTransaction() //save Transactions
        saveCategory() //save Category
    }
    
    func updatingTableView()
    {
        try! realm.write {
            for i in 0...updatingTransactions.listUpdatingResults.count-1{
                if (updatingTransactions.listUpdatingResults[i].payload?.currencyCode == "")
                {
                    let account = realm.object(ofType: Account.self, forPrimaryKey: updatingTransactions.listUpdatingResults[i].payload?.account_id)
                    updatingTransactions.listUpdatingResults[i].payload?.currencyCode = account?.currencyCode
                }
                if (updatingTransactions.listUpdatingResults[i].payload?.category?.name == "")
                {
                    let category = realm.object(ofType: CategoryTransaction.self, forPrimaryKey: updatingTransactions.listUpdatingResults[i].payload?.category?.id)
                    updatingTransactions.listUpdatingResults[i].payload?.category?.name = (category?.name)!
                }
                updatingTransactions.listUpdatingResults[i].checkFlag = true
                realm.add(updatingTransactions.listUpdatingResults[i].payload!, update:true)
            }
        }
    }
    
    func sendingReport(){
        
        for i in 0...updatingTransactions.listUpdatingResults.count-1{
            if (updatingTransactions.listUpdatingResults[i].checkFlag){
                postTransaction(SendingUUID: updatingTransactions.listUpdatingResults[i].uuid!)
            }
        }
    }
    
    func updatingTransactiontFromServer() -> Bool{
        var countOfUpdatetedTransactionsFlag = false
        let request = setRequest(urlAddition: "/api/v2/sync")
        let semaphore = DispatchSemaphore(value: 0)
        //http get
        URLSession.shared.dataTask(with: request){
            data, response, error in
            guard(error == nil) else {
                self.showMessage(messageString: "Error: " + error.debugDescription)
                return
            }
            
            let updatingResult: NSArray
            do {
                updatingResult = try JSONSerialization.jsonObject(with: data!, options: []) as! NSArray
                //parsing json and make an array of transactions
                if (updatingResult.count > 0){
                    countOfUpdatetedTransactionsFlag = true
                    for index in 0...updatingResult.count-1{
                        let updatedTransaction = UpdatingTransaction(jsonArray: updatingResult[index] as! [String : AnyObject])
                        self.updatingTransactions.listUpdatingResults.append(updatedTransaction)
                    }
                }
            } catch {
                self.showMessage(messageString: "Could not parse data as Json")
                return
            }
            semaphore.signal()
            }.resume()
        
        semaphore.wait(timeout: .distantFuture)
        return countOfUpdatetedTransactionsFlag
    }
    
    func saveAccounts()
    {
        try! realm.write {
            //add Accounts to Realm
            for i in 0...accountList.listAccount.count-1{
                realm.add(accountList.listAccount[i])
            }
        }
    }
    
    
    func saveTransaction()
    {
        try! realm.write {
            for i in 0...transactions.listTransaction.count-1{
                if (transactions.listTransaction[i].currencyCode == "")
                {
                    let account = realm.object(ofType: Account.self, forPrimaryKey: transactions.listTransaction[i].account_id)
                    transactions.listTransaction[i].currencyCode = account?.currencyCode
                }
                realm.add(transactions.listTransaction[i], update:true)
            }
        }
    }
    
    func saveCategory(){
        try! realm.write {
            for i in 0...categoryList.listCategoryTransactions.count-1{
                realm.add(categoryList.listCategoryTransactions[i], update:true)
            }
        }
    }
    
    func makeArray(){
        let predicate = NSPredicate(format: "isAccountShow == 1")
        allAccounts = realm.objects(Account.self).filter(predicate)
        return
    }
    
    func makeCategoryArray(){
        allCategory = realm.objects(CategoryTransaction.self)
    }
    
    
    func makeSectionsArray() {
        let spDate:Date = Calendar.current.date(byAdding: .day, value: -15, to: Date())!
        
        let predicate = NSPredicate(format: "madeOn > %@", spDate as CVarArg) //+predicate 15 days
        
        allTransaction = realm.objects(Transaction.self).filter(predicate).sorted(by: ["madeOn", "descriptionOfTransaction"])
        //allTransaction = realm.objects(Transaction).sorted(by: ["MadeOn"])
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
}
