//
//  AccountClassTest.swift
//  Exmoney
//
//  Created by Galina Gainetdinova on 17/05/2017.
//  Copyright © 2017 Galina Gainetdinova. All rights reserved.
//

import XCTest
@testable import Exmoney

class AccountClassTest: XCTestCase {
    
    var accountViewController: AccountAndTransactionsViewController!
    
    override func setUp() {
        super.setUp()
        accountViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AccountAndTransactionsViewController") as! AccountAndTransactionsViewController
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    /*func testCalculateHightOfTableView(){
        //
        let count = 10
        let rowHeight = CGFloat(5)
        let numberOfSections = 2
        let sectionHeaderHeight = CGFloat(1)
        let height = CGFloat(count) * rowHeight + 1100 + CGFloat(numberOfSections) * sectionHeaderHeight
        XCTAssertEqual(accountViewController..calculateHightOfTableView(rowCount:count, rowHeight:rowHeight, numberOfSections:numberOfSections, sectionHeaderHeight:sectionHeaderHeight), CGFloat(height))
        
        //accountViewController.viewDidLoad()
        //let tableView = accountViewController.tableView2 as UITableView
        
        //XCTAssertNotNil(accountViewController.calculateHightOfTableView(rowCount: accountViewController.AllTransaction.count, rowHeight: tableView.rowHeight, numberOfSections: tableView.numberOfSections, sectionHeaderHeight: tableView.sectionHeaderHeight))
    }*/
    
    func testWriteValueBack(){
        let category = CategoryTransaction()
        category.id = 1
        category.name = "Category"
        
        let note = "Note"
        
        XCTAssertNotNil(category)
        XCTAssertNotNil(note)
        
    }
    
    func testGetAccounts(){

        //let bundle = Bundle(for: type(of: self))
        //let path = bundle.path(forResource: "search-AccountsResponse", ofType: "json")
        //let data = NSData(contentsOfFile: path!)    
    }
    
}
