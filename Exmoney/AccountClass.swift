//
//  AccountClass.swift
//  Exmoney
//
//  Created by Galina Gainetdinova on 02/03/2017.
//  Copyright © 2017 Galina Gainetdinova. All rights reserved.
//

import UIKit
import RealmSwift


class Account: Object {
    dynamic var balance_millicents = 0
    dynamic var currencyCode = ""
    dynamic var name = ""
    dynamic var isAccountShow = false
    dynamic var isSaltedgeAccountIdShow = false
    dynamic var id_acc = 0
    dynamic var balanceString: String{
        get {
            return String(describing: Decimal(balance_millicents).doubleValue/1000)
        }
    }
    dynamic var symbolForCurrencyCode: String {
        get {
            if (currencyCode == "RUB") {
                return "₽"
            } else {
                return NSLocale(localeIdentifier: currencyCode).displayName(forKey: NSLocale.Key.currencySymbol, value: currencyCode)!
            }
        }
    }
    
    override static func primaryKey() -> String? {
        return "id_acc"
    }
    convenience required init(jsonArray: [String : AnyObject]) {
        self.init()
        name = (jsonArray["name"] as? String)!
        balance_millicents = (jsonArray["balance_millicents"] as? Int)!
        currencyCode = (jsonArray["currency_code"] as? String)!
        id_acc = (jsonArray["id"] as? Int)!
        
        if (jsonArray["show_on_dashboard"] as? Bool) != nil {
             isAccountShow = true
        } else {
            isAccountShow = false 
        }
        
        if (jsonArray["saltedge_account_id"] as? Int) != nil {
            isSaltedgeAccountIdShow = true
        } else {
            isSaltedgeAccountIdShow = false
        }
    }
}

class AccountsList: Object {
    let listAccount = List<Account>()
}

class Transaction: Object {
    dynamic var madeOn: Date?
    dynamic var descriptionOfTransaction: String?
    dynamic var amount_millicents = 0
    dynamic var currencyCode = ""
    dynamic var category: CategoryTransaction? = nil
    dynamic var information: String?
    dynamic var id = 0
    dynamic var payee: String?
    dynamic var account_id = 0
    dynamic var amountString: String {
        get {
             return String(describing: Decimal(amount_millicents).doubleValue/1000)
        }
    }
    dynamic var symbolForCurrencyCode: String {
        get {
            if (currencyCode == "RUB") {
                return "₽"
            } else {
                return NSLocale(localeIdentifier: currencyCode).displayName(forKey: NSLocale.Key.currencySymbol, value: currencyCode)!
            }
        }
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
    let dateFormatt = DateFormatter()
    
    convenience required init(jsonArray: [String : AnyObject] ) {
        self.init()
        dateFormatt.dateFormat = "yyyy-MM-dd"
        amount_millicents = (jsonArray["amount_millicents"] as? Int)!
        account_id = (jsonArray["account_id"] as? Int)!
        madeOn = dateFormatt.date(from: (jsonArray["made_on"] as? String)!)
        id = (jsonArray["id"] as? Int)!
        
        let categoryValue = jsonArray["category"] as! [String:Any]
        category = CategoryTransaction()
        category?.id = (categoryValue["id"] as? Int)!
        category?.name = (categoryValue["name"] as? String)!
        
        if let descr = jsonArray["description"] as? String {
            descriptionOfTransaction = descr
        } else {
            descriptionOfTransaction = ""
        }
        
        if let cur = jsonArray["currency_code"] as? String {
            currencyCode = cur
        } else {
            currencyCode = ""
        }
        
        if let description = jsonArray["extra"] as? [String:Any] {
            let description1 = description["payee"] as? String
            payee = description1
            information = description["information"] as? String
        } else {
            payee = ""
            information = ""
        }
    }
}

class CategoryTransaction: Object {
    dynamic var id = 0
    dynamic var name = ""
    dynamic var parent_id = 0
    dynamic var parent = false
    override static func primaryKey() -> String? {
        return "id"
    }
    convenience required init(jsonArray: [String : AnyObject] ) {
        self.init()
        id = (jsonArray["id"] as? Int)!
        name = (jsonArray["human_name"] as? String)!
        if let par = jsonArray["parent_id"] as? Int
        {
            parent_id = par
            parent = false
        } else {
            parent = true
            parent_id = id
        }
    }
}

class UpdatingTransaction: Object {
    dynamic var id = 1
    dynamic var uuid: String?
    dynamic var actionClass: myActionClass?
    dynamic var entity: String?
    dynamic var insertedAtDate: Date?
    dynamic var payload: Transaction? = nil
    dynamic var checkFlag = false
    override static func primaryKey() -> String? {
        return "uuid"
    }
    let dateFormatt = DateFormatter()
    let dateFormatt_aqur = DateFormatter()
    
    convenience required init(jsonArray: [String : AnyObject] ) {
        self.init()
        dateFormatt.dateFormat = "yyyy-MM-dd"
        uuid = (jsonArray["uuid"] as? String)
        entity = (jsonArray["entity"] as! String)
        
        actionClass = myActionClass()
        actionClass?.action = (jsonArray["action"] as! String)
        
        let payloadTransaction = jsonArray["payload"] as! [String:Any]
        insertedAtDate = dateFormatt_aqur.date(from: (payloadTransaction["inserted_at"] as? String)!)
        payload = Transaction()
        payload?.madeOn = dateFormatt.date(from: (payloadTransaction["made_on"] as? String)!)
        payload?.account_id = (payloadTransaction["account_id"] as? Int)!
        payload?.amount_millicents = (payloadTransaction["amount_millicents"] as? Int)!
        payload?.id = (payloadTransaction["id"] as? Int)!
        
        payload?.category = CategoryTransaction()
        payload?.category?.id = (payloadTransaction["category_id"] as? Int)!
        
        if let descr = payloadTransaction["description"] as? String {
            payload?.descriptionOfTransaction = descr
        } else {
            payload?.descriptionOfTransaction = ""
        }
        
        if let cur = payloadTransaction["currency_code"] as? String {
            payload?.currencyCode = cur
        } else {
            payload?.currencyCode = ""
        }
        
        if let description = payloadTransaction["extra"] as? [String:Any] {
            let description1 = description["payee"] as? String
            payload?.payee = description1
            payload?.information = description["information"] as? String
        } else {
            payload?.payee = ""
            payload?.information = ""
        }
    }
}

class SectionList: Object {
   let sections = List<Section>()
}

class Section: Object {
    let heading = ""
    let listTransaction = List<Transaction>()
}

class TransactionsList: Object {
    let listTransaction = List<Transaction>()
}

class CategoryTransactionList: Object {
    let listCategoryTransactions = List<CategoryTransaction>()
}

class UpdatingTransactionList: Object {
    let listUpdatingResults = List<UpdatingTransaction>()
}

enum Action: String {
    case delete, update, create
}

class myActionClass: Object {
    dynamic var id = 0
    dynamic var action = Action.create.rawValue
    var actionEnum: Action {
        get {
            return Action(rawValue: action)!
        }
        set {
            action = newValue.rawValue
        }
    }
}

struct CellData {
    let text1:String!
    var text2:Any!
}

class CategoryTableViewCell: UITableViewCell {
    
    @IBOutlet weak var categoryListContainerView: UIView!
    @IBOutlet weak var moduleListTitleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        categoryListContainerView.layer.cornerRadius =  3.0
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
}
    
    class DatePickerTableViewCell: UITableViewCell {
        var datePicker: UIDatePicker!
        required init(coder aDecoder: NSCoder) {
            fatalError("init(coder:)")
        }
        override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            let gapX : CGFloat = 0
            let gapY : CGFloat = 0
            let labelHeight: CGFloat = 200
            datePicker = UIDatePicker()
            datePicker.datePickerMode = UIDatePickerMode.date
            datePicker.frame = CGRect(x: gapX, y: gapY, width: frame.width, height: labelHeight)
            contentView.addSubview(datePicker)
        }
    }


