//
//  AccountClass.swift
//  Exmoney
//
//  Created by Galina Gainetdinova on 02/03/2017.
//  Copyright © 2017 Galina Gainetdinova. All rights reserved.
//

import UIKit
import RealmSwift


class Account:Object {
    
    dynamic var Balance_millicents:Int = 0
    dynamic var CurrencyCode: String = ""
    dynamic var Name: String = ""
    dynamic var ShowOnDashboard:Bool = false
    dynamic var SaltedgeAccountId:Bool = false
    dynamic var id_acc:Int = 0
    
    override static func primaryKey() -> String? {
        return "id_acc"
    }
    
    convenience required init(jsonArray: [String : AnyObject]) {
        
        self.init()
        
        Name = (jsonArray["name"] as? String)!
        Balance_millicents = (jsonArray["balance_millicents"] as? Int)!
        CurrencyCode = (jsonArray["currency_code"] as? String)!
        id_acc = (jsonArray["id"] as? Int)!
        
        if let showOnDashboard = jsonArray["show_on_dashboard"] as? Bool {
             ShowOnDashboard = true
        } else {
            ShowOnDashboard = false
        }
        
       if let saltage = jsonArray["saltedge_account_id"] as? Int {
            SaltedgeAccountId = true
        } else {
            SaltedgeAccountId = false
        }
    }
}

class AccountsList:Object {
    let ListAccount = List<Account>()
}


class Transaction: Object{

    dynamic var MadeOn:Date?
    dynamic var Description:String?
    dynamic var Amount_millicents:Int = 0
    dynamic var CurrencyCode:String?
    dynamic var Category: CategoryTransaction? = nil
    dynamic var Information: String?
    dynamic var id:Int = 0
    dynamic var Payee:String?
    dynamic var account_id:Int = 0
    
    override static func primaryKey() -> String? {
        return "id"
    }
    let dateFormatt = DateFormatter()
    
    
    convenience required init(jsonArray: [String : AnyObject] ) {
        
        self.init()
        
        dateFormatt.dateFormat = "yyyy-MM-dd"
        Amount_millicents = (jsonArray["amount_millicents"] as? Int)!
        account_id = (jsonArray["account_id"] as? Int)!
        MadeOn = dateFormatt.date(from: (jsonArray["made_on"] as? String)!)
        id = (jsonArray["id"] as? Int)!
        
        let category = jsonArray["category"] as! [String:Any]
        Category = CategoryTransaction()
        Category?.id = (category["id"] as? Int)!
        Category?.name = (category["name"] as? String)!
        
        if let descr = jsonArray["description"] as? String {
            Description = descr
        } else {
            Description = ""
        }
        
        if let cur = jsonArray["currency_code"] as? String {
            CurrencyCode = cur
        } else {
            CurrencyCode = ""
        }
        
        if let description = jsonArray["extra"] as? [String:Any] {
            let description1 = description["payee"] as? String
            Payee = description1
            Information = description["information"] as? String
        }
        else{
            Payee = ""
            Information = ""
        }

    }
    
}

class CategoryTransaction:Object{
    dynamic var id:Int = 0
    dynamic var name:String = ""
    dynamic var parent_id: Int = 0
    dynamic var parent:Bool = false
    
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
        }
        else{
            parent = true
            parent_id = id
        }
    }
}

class UpdatingTransaction: Object{
    
    dynamic var id:Int = 1
    dynamic var uuid: String?
    dynamic var actionClass: myActionClass?
    dynamic var entity:String?
    dynamic var insertedAtDate:Date?
    dynamic var payload:Transaction? = nil
    dynamic var checkFlag:Bool = false
    
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
        payload?.MadeOn = dateFormatt.date(from: (payloadTransaction["made_on"] as? String)!)
        payload?.account_id = (payloadTransaction["account_id"] as? Int)!
        payload?.Amount_millicents = (payloadTransaction["amount_millicents"] as? Int)!
        payload?.id = (payloadTransaction["id"] as? Int)!
        
        payload?.Category = CategoryTransaction()
        payload?.Category?.id = (payloadTransaction["category_id"] as? Int)!
        //payload?.Category?.name = (category["name"] as? String)!
        
        if let descr = payloadTransaction["description"] as? String {
            payload?.Description = descr
        } else {
            payload?.Description = ""
        }
        
        if let cur = payloadTransaction["currency_code"] as? String {
            payload?.CurrencyCode = cur
        } else {
            payload?.CurrencyCode = ""
        }
        
        if let description = payloadTransaction["extra"] as? [String:Any] {
            let description1 = description["payee"] as? String
            payload?.Payee = description1
            payload?.Information = description["information"] as? String
        }
        else{
            payload?.Payee = ""
            payload?.Information = ""
        }
    }
}

class SectionList:Object{
   let Sections = List<Section>()
}

class Section:Object {
    let heading : String = ""
    let ListTransaction = List<Transaction>()
}

class TransactionsList:Object{
    let ListTransaction = List<Transaction>()
}

class CategoryTransactionList:Object{
    let ListCategoryTransactions = List<CategoryTransaction>()
}

class UpdatingTransactionList:Object{
    let ListUpdatingResults = List<UpdatingTransaction>()
}

/*class LogInfo:Object{
    
    dynamic var id = 0
    dynamic var Transaction = ""
    dynamic var status:Bool = false
    dynamic var time: NSDate? = nil
    override static func primaryKey() -> String? {
        return "id"
    }
}

class LogInfoList:Object {
    let ListLogInfo = List<LogInfo>()
}*/

enum Action:String{
    case Delete
    case Update
    case Create
}

class myActionClass: Object {
    dynamic var id = 0
    dynamic var action = Action.Create.rawValue
    var actionEnum: Action {
        get {
            return Action(rawValue: action)!
        }
        set {
            action = newValue.rawValue
        }
    }
}

struct CellData{
    let text1:String!
    var text2:Any!
}


class MainCategoryHeaderTableViewCell: UITableViewCell {
    
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var expandCollapseImageView: UIImageView!
    @IBOutlet weak var headerCellButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }    
}


class CategoryTableViewCell: UITableViewCell {
    
    @IBOutlet weak var categoryListContainerView: UIView!
    @IBOutlet weak var moduleListTitleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        categoryListContainerView.layer.cornerRadius =  3.0

    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
}
    
    class DatePickerTableViewCell:UITableViewCell{
        
        var DatePicker: UIDatePicker!
        
        required init(coder aDecoder: NSCoder) {
            fatalError("init(coder:)")
        }
        
        override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            
            let gapX : CGFloat = 0
            let gapY :CGFloat = 0
            let labelHeight: CGFloat = 200
            DatePicker = UIDatePicker()
            DatePicker.datePickerMode = UIDatePickerMode.date
            DatePicker.frame = CGRect(x: gapX, y: gapY, width: frame.width, height: labelHeight)
            contentView.addSubview(DatePicker)
        }
        
    }


