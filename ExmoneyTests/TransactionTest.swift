//
//  TransactionTest.swift
//  Exmoney
//
//  Created by Galina Gainetdinova on 17/05/2017.
//  Copyright © 2017 Galina Gainetdinova. All rights reserved.
//

import XCTest
@testable import Exmoney

class TransactionTest: XCTestCase {
    
    func testTransactionDescription(){
        let Description = "Description"
        let transaction = Transaction()
        transaction.Description = "Description"
        XCTAssertEqual(transaction.Description, Description)
    }
    
    func testTransactionAmount(){
        let Amount = 1000
        let transaction = Transaction()
        XCTAssertNotNil(transaction.Amount_millicents)
        transaction.Amount_millicents = 1000
        XCTAssertEqual(transaction.Amount_millicents, Amount)
    }
    
    func testTransactionCurrencyCode(){
        let CurrencyCode = "Code"
        let transaction = Transaction()
        transaction.CurrencyCode = "Code"
        XCTAssertEqual(transaction.CurrencyCode, CurrencyCode)
    }
    
    func testTransactionInformation(){
        let Information = "Information"
        let transaction = Transaction()
        //XCTAssertNotNil(transaction.Information)
        transaction.Information = "Information"
        XCTAssertEqual(transaction.Information, Information)
    }
    
    func testTransactionPayee(){
        let Payee = "Payee"
        let transaction = Transaction()
        //XCTAssertNotNil(transaction.Payee)
        transaction.Payee = "Payee"
        XCTAssertEqual(transaction.Payee, Payee)
    }
    
    func testTransactionId(){
        let Id = 1
        let transaction = Transaction()
        XCTAssertNotNil(transaction.id)
        transaction.id = 1
        XCTAssertEqual(transaction.id, Id)
    }
    
    func testTransactionAccountId(){
        let accountId = 1
        let transaction = Transaction()
        XCTAssertNotNil(transaction.account_id)
        transaction.account_id = 1
        XCTAssertEqual(transaction.account_id, accountId)
    }
    
    func testTransactionDate(){
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let transaction = Transaction()
        //XCTAssertNotNil(transaction.MadeOn)
        transaction.MadeOn = Date()
        //XCTAssertEqual(transaction.MadeOn, date)
    }
    
    func testTransactionCategory(){
        let category = CategoryTransaction()
            category.id = 1
            category.name = "Category"
        let transaction = Transaction()
        transaction.Category = CategoryTransaction()
            transaction.Category?.id = 1
            transaction.Category?.name = "Category"
        XCTAssertEqual(transaction.Category?.id, category.id)
        XCTAssertEqual(transaction.Category?.name, category.name)
    }
}
