//
//  EditViewController.swift
//  Exmoney
//
//  Created by Galina Gaynetdinova on 28/03/2017.
//  Copyright © 2017 Galina Gaynetdinova. All rights reserved.
//

import UIKit
import Floaty

protocol writeValueBackDelegate:class {
    func writeValueBack(sendBackCategory: CategoryTransaction, sendBackNote: String)
}


class EditViewController: UIViewController {
    
    @IBOutlet weak var labelText: UILabel!
    
    @IBOutlet weak var tableView: UITableView!

    
    @IBOutlet weak var BarItem: UINavigationItem!
    weak var delegate: writeValueBackDelegate?

    
    var editCategory:String!
    var editNote:String!
 
    var categoryToUpdate:CategoryTransaction!
    var noteToUpdate:String?
    var labelInformation:String?

    @IBAction func updateButtonAction(_ sender: Any) {
        let indexPath = IndexPath(row: 1, section: 0)
        editNote = (tableView.cellForRow(at: indexPath) as? TextFieldTableViewCell)?.TextFieldCell.text
        if (categoryToUpdate != nil && !editNote.isEmpty) {
            delegate?.writeValueBack(sendBackCategory: categoryToUpdate , sendBackNote: editNote!)
        }
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        BarItem.title = "Editing Transaction"
        BarItem.leftBarButtonItem = UIBarButtonItem(title: "← Back", style: .plain, target: self, action: #selector(backAction))
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        labelText.text = labelInformation
        labelText.textColor = UIColor(red: 255/155, green: 198/255, blue: 67/255, alpha: 1)
        
        //tableView.register(TextFieldTableViewCell.self, forCellReuseIdentifier: "textCell")
        
        //tableView.estimatedRowHeight = 70
        //tableView.rowHeight = UITableViewAutomaticDimension
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 50
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func backAction(){
        dismiss(animated: true, completion: nil)
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    /*func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath.row != 1){
            return UITableViewAutomaticDimension }
        else {
            return 50
        }
    }*/
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
}

//MARK: - UITableViewDelegate
extension EditViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath.row != 1){
            return UITableViewAutomaticDimension
        } else {
            return 55
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let indexPath = tableView.indexPathForSelectedRow
        if (indexPath?.row == 0){
            let popOverVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "popUpListID") as! PopUpListViewController
            //self.present(popOverVC, animated: true, completion: nil)
            popOverVC.customDelegateForDataReturn = self
            self.addChildViewController(popOverVC)
            popOverVC.view.frame = self.view.frame
            self.view.addSubview(popOverVC.view)
            popOverVC.didMove(toParentViewController: self)
        }
    }
}

//MARK: - UITableViewDataSource
extension EditViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath.row == 1) {
            let cell = Bundle.main.loadNibNamed("TextFieldTableViewCell", owner: self, options: nil)?.first as! TextFieldTableViewCell
            //let cell = tableView.dequeueReusableCell(withIdentifier: "textCell", for: indexPath) as! TextFiledTableViewCell
            cell.NameLbl.text = "Note"
            cell.TextFieldCell.text = noteToUpdate
            cell.TextFieldCell.font = UIFont(name: "Helvetica Neue", size: 14.0)
            cell.TextFieldCell.textColor = UIColor.gray
            
            //cell.detailTextLabel?.numberOfLines = 0
            if (noteToUpdate == "") {
                cell.TextFieldCell.text = "Note"
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! UITableViewCell
            cell.textLabel?.text = "Category"
            cell.detailTextLabel?.text = categoryToUpdate.name + " >"
            cell.detailTextLabel?.textColor = UIColor.gray
            cell.textLabel?.font = UIFont(name:"Helvetica Neue", size: 15.0)
            return cell
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
}

//MARK: - TrendingProductsCustomDelegate
extension EditViewController: TrendingProductsCustomDelegate {
    func sendingCategoryToHomePageViewController(categoryToRefresh: CategoryTransaction) { //Custom delegate function which was defined inside child class to get the data and do the other stuffs.
        categoryToUpdate = categoryToRefresh
        let indexPath = IndexPath(row: 0, section:0)
        tableView.beginUpdates()
        tableView.reloadRows(at: [indexPath], with: .top)
        tableView.endUpdates()
    }
}

//MARK: - UITextFieldDelegate
extension EditViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
