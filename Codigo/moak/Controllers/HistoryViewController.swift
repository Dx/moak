//
//  HistoryViewController.swift
//  ApiAIDemoWatchOSSwift
//
//  Created by Dx on 10/04/16.
//  Copyright © 2016 moak. All rights reserved.
//

import UIKit
import Firebase
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}


class HistoryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addToListButton: UIButton!
    
    var products: [Product] = []
    
    var selectedProducts: [Product] = []
    
    var filteredProducts: [Product] = []
    var resultSearchController = UISearchController()
    
    var ticketSelected: String?
    
    var selectedProduct : Product?
    
    var screenWidth : CGFloat = 0.0
    var screenHeight : CGFloat = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureTableView()
		
		
        
        let screenSize: CGRect = UIScreen.main.bounds
        screenWidth = screenSize.width
        screenHeight = screenSize.height
        
        self.resultSearchController = ({
            let controller = UISearchController(searchResultsController: nil)
            controller.searchResultsUpdater = self
            controller.dimsBackgroundDuringPresentation = false
            controller.searchBar.sizeToFit()
            
            self.tableView.tableHeaderView = controller.searchBar
            
            return controller
        })()
        
        definesPresentationContext = true
    }
    
    @IBAction func closeButton(_ sender: AnyObject) {
        self.dismiss(animated: true) {
            print ("closing list")
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let firebase = FirebaseClient()
        let purchases = firebase.getProductsInTicket(self.ticketSelected!)
        
        _ = purchases.observe(DataEventType.value, with: { (snapshot) in
            var newItems: [Product] = []
            
            if let postDict = snapshot.value as? [String : AnyObject] {
                
                for item in postDict.values {
                    
                    let itemType = Product(parameters: item as! [String: AnyObject])
                    newItems.append(itemType)
                    
                    self.products = newItems
                }
                
                self.tableView.reloadData()
            }
        })
    }
    
    // MARK: - TableViewDelegate
    func configureTableView() {
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.separatorStyle = .none
        self.tableView.backgroundColor = UIColor.white
        self.tableView.rowHeight = 60
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.resultSearchController.isActive {
            return self.filteredProducts.count
        } else {
        	return self.products.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ListCellHistory
        cell.selectionStyle = .none
        
        if self.resultSearchController.isActive {
            let filterProducts = self.filteredProducts
            
            if let product = filterProducts[(indexPath as NSIndexPath).row] as Product? {
                
                cell.toDoItem = product
            }
        } else {
        
        	let filterProducts = self.products
        
        	if let product = filterProducts[(indexPath as NSIndexPath).row] as Product? {
            	
                cell.toDoItem = product
        	}
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.resultSearchController.isActive {
            let filterProducts = self.filteredProducts
            
            if let product = filterProducts[(indexPath as NSIndexPath).row] as Product? {
                if product.checked {
                    self.selectedProduct = product
                    self.performSegue(withIdentifier: "showDetail", sender: nil)
                }
            }
        } else {
            let filterProducts = self.products
            
        	if let product = filterProducts[(indexPath as NSIndexPath).row] as Product? {
            	if product.checked {
                	self.selectedProduct = product
                	self.performSegue(withIdentifier: "showDetail", sender: nil)
            	}
        	}
        }
    }

	// MARK: - Search Controller
    
	func updateSearchResults(for searchController: UISearchController)
    {
        self.filteredProducts.removeAll(keepingCapacity: false)
        
        let array = self.products.filter() { $0.productName.lowercased().contains(searchController.searchBar.text!.lowercased()) }
        
        self.filteredProducts = array
        
        self.tableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "showDetail":
            let detailViewController = segue.destination as! DetailViewController
            if self.ticketSelected != nil {
                detailViewController.ticketSelected = self.ticketSelected
            }
            detailViewController.selectedProduct = self.selectedProduct
            detailViewController.historyList = self
            let backItem = UIBarButtonItem()
            backItem.title = "Atrás"            
            navigationItem.backBarButtonItem = backItem
        case "moveToListSegue":
            let moveViewController = segue.destination as! MoveToListViewController
            moveViewController.selectedProducts = self.selectedProducts
            moveViewController.historyController = self
            let backItem = UIBarButtonItem()
            backItem.title = "Atrás"
            navigationItem.backBarButtonItem = backItem
            
        default:
            print("bad option")
        }
    }
    
    
    @IBAction func addToListClick(_ sender: AnyObject) {
        performSegue(withIdentifier: "moveToListSegue", sender: self)
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            let alertController = UIAlertController(title: "¿Deshacer borrado?", message: "Puedes evitar el borrado", preferredStyle: .alert)
            
            let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) {
                UIAlertAction in
                self.undoManager?.undo()
                NSLog("OK Undo Pressed")
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) {
                UIAlertAction in
                NSLog("Cancel Undo Pressed")
            }
            
            // Add the actions
            alertController.addAction(okAction)
            alertController.addAction(cancelAction)
            
            // Present the controller
            self.present(alertController, animated: true, completion: nil)
            
        }
    }
    
    // MARK: - TableViewCellDelegate
    func toDoItemChecked(_ toDoItem: Product) {
        let index = self.selectedProducts.firstIndex( where: { $0.productId == toDoItem.productId } )
        if  index >= 0 {
            self.selectedProducts.remove(at: index!)
        } else {
        	self.selectedProducts.append(toDoItem)
        }
        
        self.addToListButton.isEnabled = self.selectedProducts.count > 0
        
        self.tableView.reloadData()
    }
    
    func toDoItemDeleted(_ toDoItem: Product) {
        
        // There is no delete in here
    }
    
    // MARK: - Functions
    
    func addProduct(_ product: [String: AnyObject]) {
        let firebaseClient = FirebaseClient()
        
        firebaseClient.addProductInShoppingList(shoppingList: self.ticketSelected!, product: Product(parameters: product))
        
        self.tableView.reloadData()
    }
}
