//
//  PopUpListViewController.swift
//  Exmoney
//
//  Created by Galina Gainetdinova on 23/03/2017.
//  Copyright © 2017 Galina Gainetdinova. All rights reserved.
//

import UIKit
import RealmSwift

protocol CategoryToRefreshDelegate: class {
    func sendingCategoryToHomePageViewController(_ categoryToRefresh: CategoryTransaction) //This function will send the data back to origin viewcontroller.
}

extension Results {
    func toArray<T>(ofType: T.Type) -> [T] {
        var array = [T]()
        for i in 0 ..< count {
            if let result = self[i] as? T {
                array.append(result)
            }
        }
        return array
    }
}

class PopUpListViewController: UIViewController {
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var popUpNavigationItem: UINavigationItem!
    var mainCategory: Array<CategoryTransaction>!
    var childrenCategory: Array<CategoryTransaction>!
    var category:String = "Uncategorized >"
    var categoryChange: CategoryTransaction!
    weak var customDelegateForDataReturn: CategoryToRefreshDelegate?
    var categorySearchResults: Array<CategoryTransaction>?
    var arrayOfSpecies:Array<CategoryTransaction>?
    var selectedIndexPathSection:Int = -1
    var sectionNames: [String] {
        return Set(realm.objects(CategoryTransaction.self).filter("parent == 1").sorted(byKeyPath: "name").value(forKeyPath: "name") as! [String]).sorted(by: { $0.compare($1) == .orderedAscending})
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mainCategory = (getParentCategoryTransaction())!.sorted { $0.name < $1.name }
        self.view.backgroundColor = UIColor.white.withAlphaComponent(0.8)
        popUpNavigationItem.leftBarButtonItem = UIBarButtonItem(title: "← Close", style: .plain, target: nil, action: #selector(backAction))
        self.automaticallyAdjustsScrollViewInsets =  false
        tableView.tableFooterView = UIView(frame: CGRect.zero)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.showAnimation()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        self.removeAnimation()
    }
    
    func showAnimation() {
        self.view.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        self.view.alpha = 0.0;
        UIView.animate(withDuration: 0.25, animations: {
            self.view.alpha = 1.0
            self.view.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        })
    }
    
    func removeAnimation() {
        UIView.animate(withDuration: 0.25, animations: {
            self.view.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            self.view.alpha = 0.0;
        }, completion:{(finished : Bool)  in
            if (finished) {
                self.view.removeFromSuperview()
            }
        })
    }
    
    func getParentCategoryTransaction() -> [CategoryTransaction]? {
        let objects = realm.objects(CategoryTransaction.self).filter("parent = true").toArray(ofType: CategoryTransaction.self) as [CategoryTransaction]
        return objects.count > 0 ? objects : nil
    }
    
    func getAllCategoryTransaction() -> [CategoryTransaction]? {
        let objects = realm.objects(CategoryTransaction.self).toArray(ofType: CategoryTransaction.self) as [CategoryTransaction]
        return objects.count > 0 ? objects : nil
    }
    
    func getChildrenCategory(id: Int) -> [CategoryTransaction]{
        let objects = realm.objects(CategoryTransaction.self).filter("parent_id == %@", id).toArray(ofType: CategoryTransaction.self) as [CategoryTransaction]
        return objects
    }
    
    func filterContentForSearchText(searchText: String) {
        // Filter the array using the filter method
        if self.mainCategory == nil {
            self.categorySearchResults = nil
            return
        }
        self.categorySearchResults = self.mainCategory!.filter({( aSpecies: CategoryTransaction) -> Bool in
            // to start, let's just search by name
            return aSpecies.name.lowercased().range(of: searchText.lowercased()) != nil
        })
    }
    
    func backAction(){
        self.removeAnimation()
    }
}

//MARK: - UITableViewDelegate
extension PopUpListViewController: UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let tableViewWidth = self.tableView.bounds
        
        let headerView = UIView(frame: CGRect(x:0, y:0, width:tableViewWidth.size.width, height:self.tableView.sectionHeaderHeight))
        headerView.backgroundColor = UIColor(red: 255/155, green: 198/255, blue: 67/255, alpha: 1)
        let label = UILabel(frame: CGRect(x:10, y: 0, width: tableViewWidth.size.width, height:30))
        label.text = self.sectionNames[section]
        headerView.addSubview(label)
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let indexPath = tableView.indexPathForSelectedRow //optional, to get from any UIButton for example
        //let currentCell = tableView.cellForRow(at: indexPath!) as UITableViewCell?
        
        if tableView == self.searchDisplayController!.searchResultsTableView {
            categoryChange =  self.categorySearchResults![indexPath!.row]
            category = categoryChange.name
        } else {
            let categoryIsNeeded = realm.objects(CategoryTransaction.self).filter("name == %@ AND parent == true", sectionNames[(indexPath?.section)!]).first
            arrayOfSpecies = realm.objects(CategoryTransaction.self).filter("parent_id == %@", categoryIsNeeded!.id ).toArray(ofType: CategoryTransaction.self).sorted { $0.name < $1.name } as [CategoryTransaction]
            categoryChange = arrayOfSpecies?[indexPath!.row]
            category = categoryChange.name
        }
        if categoryChange != nil {
            customDelegateForDataReturn?.sendingCategoryToHomePageViewController(categoryChange)
        }
        let myVC = storyboard?.instantiateViewController(withIdentifier: "AddNewTransactionView") as! AddNewTransactionViewController
        myVC.category = category
        self.removeAnimation()
    }
}

//MARK: - UITableViewDataSource
extension PopUpListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (tableView == self.searchDisplayController!.searchResultsTableView) {
            return self.categorySearchResults?.count ?? 0
        } else {
            //return self.mainCategory?.count ?? 0
            let categoryIsNeeded = realm.objects(CategoryTransaction.self).filter("name == %@ AND parent == 1", sectionNames[section]).first
            return realm.objects(CategoryTransaction.self).filter("parent_id = %@", categoryIsNeeded?.id).count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView!.dequeueReusableCell(withIdentifier: "categoryCell") as! UITableViewCell
        //let cell = tableView.dequeueReusableCell(withIdentifier: "categoryTableViewCell", for: indexPath) as! CategoryTableViewCell
        if tableView == self.searchDisplayController!.searchResultsTableView {
            arrayOfSpecies = self.categorySearchResults
        } else {
            //arrayOfSpecies = self.mainCategory
            let categoryIsNeeded = realm.objects(CategoryTransaction.self).filter("name == %@ AND parent == true", sectionNames[indexPath.section]).first
            arrayOfSpecies = realm.objects(CategoryTransaction.self).filter("parent_id == %@", categoryIsNeeded?.id).toArray(ofType: CategoryTransaction.self).sorted { $0.name < $1.name } as [CategoryTransaction]//self.getChildrenCategory(id: parent_id) //self.mainCategory=
        }
        if arrayOfSpecies != nil && arrayOfSpecies!.count >= indexPath.row {
            //let species = arrayOfSpecies![indexPath.row]
            cell.textLabel?.text = " - " + (arrayOfSpecies?[indexPath.row].name)!
        }
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if (tableView == self.searchDisplayController!.searchResultsTableView){
            return 1
        } else {
            return sectionNames.count
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String {
        if (tableView == self.searchDisplayController!.searchResultsTableView){
            return ""
        } else {
            var item:String?
            item = self.sectionNames[section]
            return item!
        }
    }
}

//MARK: - UISearchBarDelegate
//extension PopUpListViewController: UISearchBarDelegate{
//
//}

//MARK: - UISearchDisplayDelegate
extension PopUpListViewController: UISearchDisplayDelegate{
    func searchDisplayController(_ controller: UISearchDisplayController, shouldReloadTableForSearch searchString: String?) -> Bool {
        self.filterContentForSearchText(searchText: searchString!)
        return true
    }
}
