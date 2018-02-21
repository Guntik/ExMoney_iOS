//
//  AddTransactionViewController.swift
//  Exmoney
//
//  Created by Galina Gaynetdinova on 10/03/2017.
//  Copyright © 2017 Galina Gainetdinova. All rights reserved.
//

import UIKit
import Floaty
import RealmSwift




//protocol for sending new transaction to last(previos) View.


class AddTransactionViewController: UIViewController, UITextFieldDelegate, UIPickerViewDelegate, UIToolbarDelegate, TrendingProductsCustomDelegate {
    
    weak var delegateTransaction:addingTransactionDelegate?
    
    // from the PopUpView with list Category send choice
    func sendDataBackToHomePageViewController(categoryToRefresh: CategoryTransaction) { //Custom delegate function which was defined inside child class to get the data and do the other stuffs.
        if categoryToRefresh != nil {
            categoryTextField.text = categoryToRefresh.name
            newTransaction.Category = categoryToRefresh
        }
    }

    @IBOutlet weak var transactionBarItem: UINavigationItem!
    
    @IBOutlet weak var SegmentControl: UISegmentedControl!
    @IBAction func segmentValueChange(_ sender: Any) {
        if SegmentControl.selectedSegmentIndex == 1 {
            flagIncome = true
            //newTransaction.Amount_millicents = newTransaction.Amount_millicents * -1
        }
    }
    
    var flagIncome:Bool = false
    
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var noteTextField: UITextField!
    @IBOutlet weak var dateTextField: UITextField!
    @IBOutlet weak var categoryTextField: UITextField!
    @IBOutlet weak var accountTextField: UITextField!
    
    var dateFormatter = DateFormatter()
    var AccountArray : Results<Account>!
    var category:String!
    let date = Date()

    override func viewDidLoad() {
        amountTextField.text = "0"

        //set Account
        newTransaction.account_id = 9 //Cash
        accountTextField.text = "Cash >"
        //set Category
        let categoryTransact = CategoryTransaction()
        categoryTransact.id = 14
        categoryTransact.name = "Uncategorized >"
        newTransaction.Category = categoryTransact
        categoryTextField.text = categoryTransact.name
        
        newTransaction.id = getNewTransactionID()
        
        newTransaction.CurrencyCode = ""
        
        //Set Date
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateTextField.text = dateFormatter.string(from: date)
        
        transactionBarItem.title = "New Transaction"
        transactionBarItem.leftBarButtonItem = UIBarButtonItem(title: "< Back", style: .plain, target: self, action: #selector(backAction))
        
        accountTextField.delegate = self
        amountTextField.delegate = self
        categoryTextField.delegate = self
        dateTextField.delegate = self
        noteTextField.delegate = self
    }
    
    let datePickerView:UIDatePicker = UIDatePicker()
    let toolBar = UIToolbar()
    
    //popup datePicker
    @IBAction func dateEditingDidBegin(_ sender: UITextField) {
        datePickerView.datePickerMode = UIDatePickerMode.date

        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        toolBar.tintColor = UIColor.orange
        toolBar.sizeToFit()
        toolBar.delegate = self as! UIToolbarDelegate
        
        let cancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.cancelPicker))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.donePicker))
        
        toolBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        
        
        sender.inputView = datePickerView
        sender.inputAccessoryView = toolBar
        datePickerView.addTarget(self, action: #selector(self.datePickerValueChanged), for: UIControlEvents.valueChanged)
    }
    
    func cancelPicker (sender:UIBarButtonItem)
    {
        dateTextField.text = dateFormatter.string(from: date)
        datePickerView.removeFromSuperview()
        toolBar.removeFromSuperview()
    }
    func donePicker (sender:UIBarButtonItem)
    {
        datePickerView.removeFromSuperview()
        toolBar.removeFromSuperview()
        
    }
    
    
    func datePickerValueChanged(datePicker:UIDatePicker) {
        
        //dateFormatter.dateStyle = DateFormatter.Style.short
        //dateFormatter.timeStyle = DateFormatter.Style.short
        
        var strDate = dateFormatter.string(from: datePicker.date)
        dateTextField.text = strDate
    }
    @IBAction func accountEditingDidBegin(_ sender: Any) {
        // choose "Account"
        self.view.endEditing(true)
        makeArrayOfAccounts()
        let alert = UIAlertController(title: "Account", message: "Please Choose Account", preferredStyle: .actionSheet)
        for index in 0...AccountArray.count-1{
            alert.addAction(UIAlertAction(title: AccountArray[index].Name, style: .default, handler: { (action) in
                //execute some code when this option is selected
                self.accountTextField.text = self.AccountArray[index].Name
                self.newTransaction.account_id = self.AccountArray[index].id_acc
            }))
        }
        
        self.present(alert, animated: true, completion: {
        })
    }
    var popUpList = PopUpListViewController()
    
    @IBAction func categoryEditingidBegin(_ sender: Any) {
        popUpList = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "popUpListID") as! PopUpListViewController

        //self.present(popOverVC, animated: true, completion: nil)
        self.view.endEditing(true)
        popUpList.customDelegateForDataReturn = self
        self.addChildViewController(popUpList)
        popUpList.view.frame = self.view.frame
        self.view.addSubview(popUpList.view)
        popUpList.didMove(toParentViewController: self)
    }
    
    
    
    @IBAction func addButtonAction(_ sender: Any) {
        if (amountTextField.text != nil && categoryTextField.text != nil && accountTextField.text != nil && dateTextField.text != nil) {
            
            newTransaction.Amount_millicents = -1 * stringToAmountMillicent(stringAmount: amountTextField.text!)
            
            if (flagIncome){
                newTransaction.Amount_millicents = newTransaction.Amount_millicents * -1
            }
            newTransaction.Description = noteTextField.text!
            newTransaction.MadeOn = dateFormatter.date(from: dateTextField.text!)
            
            
            delegateTransaction?.addingDelegate(addTransaction: newTransaction)
            
            self.dismiss(animated: true, completion: nil)
        }
        else {
            let messagePost:String = "Some fields have no value. Please check it"
            let alert = UIAlertController(title: "Alert", message: messagePost, preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
    }

    var newTransaction = Transaction()

    func getNewTransactionID() -> Int{
        let allEntries = realm.objects(Transaction.self)
        if allEntries.count > 0 {
            let lastId = allEntries.max(ofProperty: "id") as Int?
            return lastId! + 1
        }
        else {
            return 1
        }
    }

    func backAction(){
        dismiss(animated: true, completion: nil)
    }

    func amountToString(amount_millic: Int) ->String // make string value from amount_millicents
    {
        let stringAmount:String
        let decimalAmount:Decimal
        decimalAmount = Decimal(amount_millic)
        stringAmount = String(describing: decimalAmount/1000)
        return stringAmount
    }
    
    func stringToAmountMillicent(stringAmount: String)->Int // make amount_millicents from string value
    {
        let amountMillicent: Int
        let floatNumber: Float = stringAmount.myFloatConverter * 1000
        amountMillicent = Int(floatNumber)
        
        return amountMillicent
    }

    func makeArrayOfAccounts(){ // make list of Accounts
        let predicate = NSPredicate(format: "SaltedgeAccountId == 0")
        AccountArray = realm.objects(Account).filter(predicate)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
    /*func datePickerValueChanged(sender:UIDatePicker) { //choose date value
        
        newTransaction.MadeOn = sender.date//dateFormatter.string(from: sender.date)
        
        arrayofCells[3].text2 = dateFormatter.string(from:newTransaction.MadeOn!)

    }*/

 
    /*var Account1:String = "Cash >"
 
    var arrayofCells = [CellData]()
    var category:String!
    
 
    
    
        
        //register for keyboard change notifications
        NotificationCenter.default.addObserver(self, selector: #selector(AddTransactionViewController.keyboardWillShow), name:NSNotification.Name.UIKeyboardWillShow, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(AddTransactionViewController.keyboardWillHide), name:NSNotification.Name.UIKeyboardWillHide, object: nil);
        
     
        
        //default settings
     
        let categoryTransact = CategoryTransaction()
        categoryTransact.id = 14
        categoryTransact.name = "Uncategorized >"
        
        newTransaction.Category = categoryTransact
        //newTransaction.MadeOn = "Made on"
        newTransaction.Description = "Note"
        newTransaction.id = getNewTransactionID()
        newTransaction.CurrencyCode = ""
        //newTransaction.Information =
        newTransaction.account_id = 9 //Cash
        
        //Set Date
        let date = Date()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        newTransaction.MadeOn = date//Format.string(from: date)
        
        arrayofCells = [CellData(text1:"Amount", text2: amountToString(amount_millic: newTransaction.Amount_millicents)),
                            CellData(text1:"Account", text2:Account1),
                            CellData(text1:"Category", text2:newTransaction.Category?.name),
                            CellData(text1:"Made on", text2: dateFormatter.string(from: newTransaction.MadeOn!)),
                            CellData(text1:"Note", text2:newTransaction.Description)]
        
        //Make empty rows in TableView invisible
        self.tableView.reloadData()
    }
    // Keyboard Show and Hide Methods
    var activeField:UITextField!
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.activeField = textField
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.activeField = nil
    }

    func keyboardWillShow(notification: NSNotification)
    {
        let info = notification.userInfo! as! [String: AnyObject],
        kbSize = (info[UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue.size,
        contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: kbSize.height, right: 0)
        
        self.tableView.contentInset = contentInsets
        self.tableView.scrollIndicatorInsets = contentInsets
        
        var aRect = self.tableView.frame
        aRect.size.height -= kbSize.height

    }
    func keyboardWillHide(notification: NSNotification)
    {
        let contentInsets = UIEdgeInsets.zero
        self.tableView.contentInset = contentInsets
        self.tableView.scrollIndicatorInsets = contentInsets
    }
    

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrayofCells.count
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    var arrayOfTags = Array<Any>()
    
    /*func textFieldDidEndEditing(_ textField: UITextField, reason: UITextFieldDidEndEditingReason) {
        let currentTag = textField.tag
        self.arrayofCells[currentTag].text2 = textField.text!
    }*/

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
 
        let cell = Bundle.main.loadNibNamed("TableViewCell2", owner: self, options: nil)?.first as! TableViewCell2
        //cell.labelTableViewCell2.text = arrayofCells[indexPath.row].text1
        cell.textFieldTableViewCell2.text = arrayofCells[indexPath.row].text2 as! String
        cell.labelTableViewCell2.text = arrayofCells[indexPath.row].text1
        cell.textFieldTableViewCell2.placeholder = arrayofCells[indexPath.row].text1
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath.row == 1) {
            // choose "Account"
            makeArrayOfAccounts()
            let alert = UIAlertController(title: "Account", message: "Please Choose Account", preferredStyle: .actionSheet)
            for index in 0...AccountArray.count-1{
            alert.addAction(UIAlertAction(title: AccountArray[index].Name, style: .default, handler: { (action) in
                //execute some code when this option is selected
                self.arrayofCells[indexPath.row].text2 = self.AccountArray[index].Name
                self.newTransaction.account_id = self.AccountArray[index].id_acc
            }))
            }
            
            self.present(alert, animated: true, completion: {
            })
            return
        }
        if (indexPath.row == 2) {
            //choose "Category"
            let popOverVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "popUpListID") as! PopUpListViewController
            //self.present(popOverVC, animated: true, completion: nil)
            popOverVC.customDelegateForDataReturn = self
            self.addChildViewController(popOverVC)
            popOverVC.view.frame = self.view.frame
            self.view.addSubview(popOverVC.view)
            popOverVC.didMove(toParentViewController: self)
            
            return
        }
        if (indexPath.row == 3) {
            //choose "Made On"
            let indexPath = tableView.indexPathForSelectedRow //optional, to get from any UIButton for example
            let currentCell = tableView.cellForRow(at: indexPath!) as! TableViewCell2
            
            let datePickerView:UIDatePicker = UIDatePicker()
            datePickerView.datePickerMode = UIDatePickerMode.date

            currentCell.textFieldTableViewCell2.inputView = datePickerView //sometimes datepicker disconnects with addTarget, whats why it doesnt show
            datePickerView.addTarget(self, action: #selector(datePickerValueChanged), for: UIControlEvents.valueChanged)

            return
        }

    }*/
    
}
