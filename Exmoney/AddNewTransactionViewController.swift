//
//  AddNewTransactionViewController.swift
//  Exmoney
//
//  Created by Galina Gaynetdinova on 30/08/2017.
//  Copyright © 2017 Galina Gaynetdinova. All rights reserved.
//

import UIKit
import RealmSwift
import DatePickerCell

protocol addingTransactionDelegate: class {
    func addingDelegate(addTransaction: Transaction) //This function send the data back to origin ViewController.
}

// convert string with "." and "," to float value
extension String {
    var myFloatConverter: Float {
        let converter = NumberFormatter()
        converter.decimalSeparator = ","
        if let result = converter.number(from: self) {
            return result.floatValue
            
        } else {
            converter.decimalSeparator = "."
            if let result = converter.number(from: self) {
                return result.floatValue
            }
        }
        return 0
    }
}

class AddNewTransactionViewController: UIViewController {

    weak var delegateTransaction:addingTransactionDelegate?
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var seqmentControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var navigationBarItem: UINavigationItem!

    var popUpList = PopUpListViewController()
    var newTransaction = Transaction()
    var flagIncome:Bool = false
    let titelNames:[String] = ["Account", "Category", "Date"]
    var valueNames:[String] = ["Cash >", "Uncategorized >", ""]
    
    var dateFormatterRow = DateFormatter()
    var accountArray : Results<Account>!
    var category:String!
    let date = Date()
    var strDate:String!
    let datePickerView:UIDatePicker = UIDatePicker()
    let toolBar = UIToolbar()
    var datePickerIndexPath: IndexPath?
    var cells:NSArray = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //set Account
        newTransaction.account_id = 9 //Cash
        //set Category
        let categoryTransact = CategoryTransaction()
        categoryTransact.id = 14
        categoryTransact.name = "Uncategorized >"
        newTransaction.category = categoryTransact
        newTransaction.id = getNewTransactionID()
        newTransaction.currencyCode = ""
        
        //Set Date
        dateFormatterRow.dateFormat = "yyyy-MM-dd"
        strDate = dateFormatterRow.string(from: date)
        valueNames[2] = strDate
        
        navigationBarItem.title = "New Transaction"
        navigationBarItem.leftBarButtonItem = UIBarButtonItem(title: "← Back", style: .plain, target: self, action: #selector(backAction))
        
        //tableView.register(TextFiledTableViewCell.self, forCellReuseIdentifier: "textCell")
        tableView.register(DatePickerTableViewCell.self, forCellReuseIdentifier: "datePickerCell")
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        //tableView.estimatedRowHeight = 300
        addButtonToFooter()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(sender:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(sender:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    func keyboardWillShow(sender: NSNotification) {
        self.view.frame.origin.y = -150 // Move view 150 points upward
    }
    
    func keyboardWillHide(sender: NSNotification) {
        self.view.frame.origin.y = 0 // Move view to original position
    }

    
    func addButtonToFooter(){
        let footer = UIView(frame: CGRect(x: 0, y: 0, width: Int(tableView.frame.width), height: 90))
        tableView.tableFooterView = footer
        let addButton = UIButton()
        addButton.frame = CGRect(x: 0, y: 40, width: 80, height: 30)
        //addButton.center = self.view.center
        addButton.center.x = view.frame.width/2
        addButton.setTitle("Add", for: .normal)
        addButton.backgroundColor = UIColor(red: 255/255, green: 198/255, blue: 67/255, alpha: 1)
        addButton.setTitleColor(UIColor.black, for: .normal)
        addButton.layer.cornerRadius = 5
        addButton.addTarget(self, action: #selector(AddNewTransactionViewController.addButtonPressed(_:)), for: .touchUpInside)
        footer.addSubview(addButton)
        addButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func segmentValueChenged(_ sender: Any) {
        if seqmentControl.selectedSegmentIndex == 1 {
            flagIncome = true
            //newTransaction.Amount_millicents = newTransaction.Amount_millicents * -1
        }
    }
    
    func addButtonPressed(_ sender: UIButton){
        
        let cell = Bundle.main.loadNibNamed("TextFieldTableViewCell", owner: self, options: nil)?.first as! TextFieldTableViewCell
        //let cell:TextFiledTableViewCell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as! TextFiledTableViewCell
        if cell.TextFieldCell.text != "0" {
            
            newTransaction.amount_millicents = -1 * stringToAmountMillicent(stringAmount: cell.TextFieldCell.text!)
            
            if (flagIncome) {
                newTransaction.amount_millicents = newTransaction.amount_millicents * -1
            }
            newTransaction.descriptionOfTransaction = (tableView.cellForRow(at: IndexPath(row: 4, section: 0)) as! TextFieldTableViewCell).TextFieldCell.text
            newTransaction.madeOn = dateFormatterRow.date(from: ((tableView.cellForRow(at: IndexPath(row: 3, section: 0)) as! UITableViewCell).detailTextLabel?.text!)!)
            
            delegateTransaction?.addingDelegate(addTransaction: newTransaction)
            
            self.dismiss(animated: true, completion: nil)
        } else {
            let messagePost:String = "Some fields have no value. Please check it"
            let alert = UIAlertController(title: "Alert", message: messagePost, preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
    }
    
    func calculateDatePickerIndexPath(indexPathSelected: IndexPath) -> IndexPath {
        if datePickerIndexPath != nil && datePickerIndexPath!.row  < indexPathSelected.row { // case 3.2
            return IndexPath(row: indexPathSelected.row, section:0)
        } else { // case 1、3.1
            return IndexPath(row: indexPathSelected.row + 1, section:0)
        }
    }
    
    func datePickerValueChanged(datePicker:UIDatePicker) {
        let indexPath = IndexPath(row: 3, section:0)
        valueNames[2] = dateFormatterRow.string(from: datePicker.date)
        tableView.beginUpdates()
        tableView.reloadRows(at: [indexPath], with: .top)
        tableView.endUpdates()
    }
    
    func getNewTransactionID() -> Int {
        let allEntries = realm.objects(Transaction.self)
        if allEntries.count > 0 {
            let lastId = allEntries.max(ofProperty: "id") as Int?
            return lastId! + 1
        } else {
            return 1
        }
    }
    
    func backAction() {
        dismiss(animated: true, completion: nil)
    }
    
    func amountToString(amount_millic: Int) ->String {// make string value from amount_millicents
        let stringAmount:String
        let decimalAmount:Decimal
        decimalAmount = Decimal(amount_millic)
        stringAmount = String(describing: decimalAmount/1000)
        return stringAmount
    }
    
    func stringToAmountMillicent(stringAmount: String)->Int {// make amount_millicents from string value
        let amountMillicent: Int
        let floatNumber: Float = stringAmount.myFloatConverter * 1000
        amountMillicent = Int(floatNumber)
        return amountMillicent
    }
    
    func makeArrayOfAccounts() { // make list of Accounts
        print(realm.objects(Account))
        accountArray = realm.objects(Account).filter("isSaltedgeAccountIdShow = 0")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
}

//MARK: - UITableViewDataSource
extension AddNewTransactionViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (datePickerIndexPath != nil) {
            return 6
        } else {
            return 5
            
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if datePickerIndexPath != nil && datePickerIndexPath!.row == indexPath.row {
            let cell = tableView.dequeueReusableCell(withIdentifier: "datePickerCell") as! DatePickerTableViewCell
            cell.datePicker.setDate(date, animated: true)
            cell.datePicker.addTarget(self, action: #selector(AddNewTransactionViewController.datePickerValueChanged), for: .valueChanged)
            return cell
        } else {
            if (indexPath.row == 0) {
                let cell = Bundle.main.loadNibNamed("TextFieldTableViewCell", owner: self, options: nil)?.first as! TextFieldTableViewCell
                cell.NameLbl.text = "Amount"
                cell.TextFieldCell.text = "0"
                cell.TextFieldCell.textColor = UIColor.gray
                cell.TextFieldCell.keyboardType = UIKeyboardType.decimalPad
                return cell
            } else {
                if (indexPath.row == 1 || indexPath.row == 2 || indexPath.row == 3) {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "addTransactionCell", for: indexPath)
                    cell.textLabel?.text = titelNames[indexPath.row - 1]
                    cell.detailTextLabel?.text = valueNames[indexPath.row - 1]
                    cell.detailTextLabel?.textColor = UIColor.gray
                    return cell
                } else {
                    let cell = Bundle.main.loadNibNamed("TextFieldTableViewCell", owner: self, options: nil)?.first as! TextFieldTableViewCell
                    cell.NameLbl.text = "Note"
                    cell.TextFieldCell.text = "Note"
                    cell.TextFieldCell.textColor = UIColor.gray
                    //cell.TextFieldCell.delegate = self as! UITextFieldDelegate ????
                    return cell
                }
            }
        }
    }
}

//MARK: - UITableViewDelegate
extension AddNewTransactionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var rowHeight = tableView.rowHeight
        if datePickerIndexPath != nil && datePickerIndexPath!.row == indexPath.row {
            let cell = tableView.dequeueReusableCell(withIdentifier: "datePickerCell")!
            rowHeight = 200
        }
        return rowHeight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath.row == 1) {
            self.view.endEditing(true)
            makeArrayOfAccounts()
            let alert = UIAlertController(title: "Account", message: "Please Choose Account", preferredStyle: .actionSheet)
            for index in 0...accountArray.count-1 {
                alert.addAction(UIAlertAction(title: accountArray[index].name, style: .default, handler: { (action) in
                    self.valueNames[0] = self.accountArray[index].name
                    let indexPath = IndexPath(row: 1, section:0)
                    tableView.beginUpdates()
                    tableView.reloadRows(at: [indexPath], with: .top)
                    tableView.endUpdates()
                    self.newTransaction.account_id = self.accountArray[index].id_acc
                }))
            }
            self.present(alert, animated: true, completion: {
            })
        }
        
        if (indexPath.row == 2) {
            popUpList = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "popUpListID") as! PopUpListViewController
            
            //self.present(popUpList, animated: true, completion: nil)
            self.view.endEditing(true)
            popUpList.customDelegateForDataReturn = self
            self.addChildViewController(popUpList)
            popUpList.view.frame = self.view.frame
            self.view.addSubview(popUpList.view)
            popUpList.didMove(toParentViewController: self)
        }
        if (indexPath.row == 3) {
            tableView.beginUpdates()
            if datePickerIndexPath != nil && datePickerIndexPath!.row - 1 == indexPath.row { // case 2
                tableView.deleteRows(at: [datePickerIndexPath!], with: .fade)
                datePickerIndexPath = nil
            } else { // case 1、3
                if datePickerIndexPath != nil { // case 3
                    tableView.deleteRows(at: [datePickerIndexPath!], with: .fade)
                }
                datePickerIndexPath = calculateDatePickerIndexPath(indexPathSelected: indexPath)
                tableView.insertRows(at: [datePickerIndexPath!], with: .fade)
            }
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.endUpdates()
        }
    }
}

//MARK: - TrendingProductsCustomDelegate
extension AddNewTransactionViewController: TrendingProductsCustomDelegate {
    func sendingCategoryToHomePageViewController(categoryToRefresh: CategoryTransaction) { //Custom delegate function which was defined inside child class to get the data and do the other stuffs.
        newTransaction.category = categoryToRefresh
        valueNames[1] = categoryToRefresh.name
        let indexPath = IndexPath(row: 2, section:0)
        tableView.beginUpdates()
        tableView.reloadRows(at: [indexPath], with: .top)
        tableView.endUpdates()
    }
}

//MARK: - UITextViewDelegate
extension AddNewTransactionViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" { // Recognizes enter key in keyboard
            textView.resignFirstResponder()
            return false
        }
        return true
    }
}
