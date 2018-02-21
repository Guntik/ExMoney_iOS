//
//  AccountsTest.swift
//  Exmoney
//
//  Created by Galina Gainetdinova on 17/05/2017.
//  Copyright © 2017 Galina Gainetdinova. All rights reserved.
//

import XCTest
@testable import Exmoney

class AccountsTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    

    func testAccountBalance(){
        let balance = 1000
        let account = Account()
        XCTAssertNotNil(account.Balance_millicents)
        account.Balance_millicents = 1000
        XCTAssertEqual(account.Balance_millicents, balance)
    }
    
    func testAccountName(){
        let Name = "AccountName"
        let account = Account()
        XCTAssertNotNil(account.Name)
        account.Name = "AccountName"
        XCTAssertEqual(account.Name, Name)
    }
    
    func testAccountCurrencyCode(){
        let CurrecncyCode = "Code"
        let account = Account()
        XCTAssertNotNil(account.CurrencyCode)
        account.CurrencyCode = "Code"
        XCTAssertEqual(account.CurrencyCode, CurrecncyCode)
    }
    
    func testAccountId(){
        let ID = 1
        let account = Account()
        XCTAssertNotNil(account.id_acc)
        account.id_acc = 1
        XCTAssertEqual(account.id_acc, ID)
    }
    
    func testAccountShowOnDashboard(){
        let show = true
        let account = Account()
        XCTAssertNotNil(account.ShowOnDashboard)
        account.ShowOnDashboard = true
        XCTAssertEqual(account.ShowOnDashboard, show)
    }
    
    func testAccountSaltadge(){
        let saltage = false
        let account = Account()
        XCTAssertNotNil(account.SaltedgeAccountId)
        account.SaltedgeAccountId = false
        XCTAssertEqual(account.SaltedgeAccountId, saltage)
        
    }
}















