# Exmoney_ios

### Author
Galina Gainetdinova

### Description
This is an application for iOS devices, which allows user to look through all his accounts and transactions.
Also user can check new transactions, add (unfortunatelly it is availible only within application) new purchases, delete and edit them. 
It based on self-hosted web application ExMoney https://github.com/gaynetdinov/ex_money and works close with it.
Exmoney_ios takes all bank accounts and your transactions duering last 15 days from ExMoney and displays it. Periodically this iOS application checks new trancations and updates tables, if it needs to.
Exmoney_ios is my first project, which was written in Swift 4.1.2.

### Authentication
How I already said, this appications works only with a close connection with ExMoney. So if you have made registratoin there, you can use your login and password for authentication in Exmoney_ios.

### Dependencies
- Realm
- Floaty
- ReachabilitySwift
- DatePickerCell
