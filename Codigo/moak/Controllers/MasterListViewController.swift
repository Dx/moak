//
//  MasterListViewController.swift
//  ApiAIDemoWatchOSSwift
//
//  Created by Dx on 14/07/16.
//  Copyright © 2016 moak. All rights reserved.
//

import UIKit
import Firebase
import WatchConnectivity

class MasterListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, WCSessionDelegate, MasterListCellDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptySpaceLabel: UILabel!

    let defaults = UserDefaults.standard
    
    var shoppingListIdSelected = ""
    var listViewController: ListsViewController? = nil
    var lists = [String: String]()
    var session: WCSession!
    var selectedRow: IndexPath? = nil
    
    // MARK: - View methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (WCSession.isSupported()) {
            session = WCSession.default
            session.delegate = self
            session.activate()
        } else {
            print ("Error en teléfono: No se soporta WCSession")
        }
        
        self.configureList()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let firebase = FirebaseClient()
        
        let shoppingLists = firebase.getUserShoppingLists()
        
        _ = shoppingLists.observe(DataEventType.value, with: { (snapshot) in
            self.lists = [:]
            
            if let postDict = snapshot.value as? [String : String] {
                
                let orderedList = postDict.sorted(by: { $0.0 < $1.0 })
                for element in orderedList {
                    self.lists[element.key] = element.value
                }
                    
                if self.session != nil {
                    self.session.sendMessage(self.lists, replyHandler: nil, errorHandler: {(error) in
                        print ("Error en teléfono al enviar el mensaje: \(error.localizedDescription)")
                    })
                }
                
                self.tableView.reloadData()
            }
        })
    }
    
    // MARK: - Segues
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.identifier! {
        case "showShoppingList":
            if shoppingListIdSelected != "" {
                
            	let controller = segue.destination as! ShoppingListViewController
                controller.shoppingListIdSelected = shoppingListIdSelected
                let backItem = UIBarButtonItem()
                backItem.title = "Atrás"
                navigationItem.backBarButtonItem = backItem
            }
        //case "editShoppingList":
            
        default:
            print("dev/null")
        }
    }
    
    // MARK: - Table View
    
    func configureList(){
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.separatorStyle = .singleLine
        self.tableView.tableFooterView = UIView()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        tableView.isHidden = lists.count <= 0
        self.emptySpaceLabel.isHidden = lists.count > 0
        
        return lists.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! MasterListViewCell
        
        let index = lists.index(lists.startIndex, offsetBy: (indexPath as NSIndexPath).row)
        let key = lists.keys[index]
        cell.shoppingListId = key
        cell.listNameLabel!.text = lists[key]
        cell.delegate = self
        
        let bgColorView = UIView()
        bgColorView.backgroundColor = UIColor(red: 0.811, green: 0.831, blue: 0.831, alpha: 1)
        cell.selectedBackgroundView = bgColorView
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedRow = indexPath
        tableView.deselectRow(at: indexPath, animated: true)
        let index = lists.index(lists.startIndex, offsetBy: (indexPath as NSIndexPath).row)
        self.defaults.set(lists.keys[index], forKey: defaultKeys.listId)
        self.defaults.set(lists.values[index], forKey: defaultKeys.listDescription)
        let nc = NotificationCenter.default
        
        nc.post(name:Notification.Name(rawValue:"RefreshList"),
                object: nil,
                userInfo: nil)
        dismiss(animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
        } else if editingStyle == .insert {
            
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let edit = UITableViewRowAction(style: .normal, title: "Editar") { action, index in
            self.selectedRow = indexPath
            self.performSegue(withIdentifier: "showShoppingList", sender: self)
        }
        edit.backgroundColor = UIColor(red: 0.29, green: 0.42, blue: 0.54, alpha: 0.65)
        
        let delete = UITableViewRowAction(style: .normal, title: "Borrar") { action, index in
            let index = self.lists.index(self.lists.startIndex, offsetBy: indexPath.row)
            let key = self.lists.keys[index]
            self.lists[key] = nil
            tableView.deleteRows(at: [indexPath], with: .fade)
            let firebase = FirebaseClient()
            firebase.deleteShoppingList(key)
        }
        
        delete.backgroundColor = UIColor(red: 0.95, green: 0.27, blue: 0.27, alpha: 0.65)
        
        return [delete, edit]
        
    }
    
    // MARK: - MasterListCellDelegate
    func shoppingListToEdit(_ shoppingListId: String) {
        self.shoppingListIdSelected = shoppingListId
        performSegue(withIdentifier: "showShoppingList", sender: self)
    }
    
    // MARK: - Session
    
    private func session(_ session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        
        var result = ""
        
        
        
        if let messageReceived = message["message"] as? [String: String] {
            if let first = messageReceived.first {
            	print(first.value)
            	if first.value == "PasameLaBotella"
            	{
                	self.session.sendMessage(self.lists, replyHandler: nil, errorHandler: nil)
            	}
            }
            
        } else  {
            result = "Error 1 on phone"
        }
        replyHandler(["result": result as AnyObject])
        
    }
    
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
        if error != nil {
        	print("Error en teléfono \(String(describing: error?.localizedDescription))")
        }
    }
    
    public func sessionDidBecomeInactive(_ session: WCSession) {
    }
    
    public func sessionDidDeactivate(_ session: WCSession){
    }
}
