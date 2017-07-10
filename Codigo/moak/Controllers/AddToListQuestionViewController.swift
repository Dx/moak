//
//  AddToListQuestionViewController.swift
//  moak
//
//  Created by Dx on 01/05/17.
//  Copyright © 2017 moak. All rights reserved.
//

import UIKit

class AddToListQuestionViewController: UIViewController {

    @IBOutlet weak var productTitle: UILabel!
    
    var shoppingListId = ""
    var selectedProduct : Product?
    var storeId = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let product = self.selectedProduct {
        	productTitle.text = product.productName
        }
        
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func addToListClick(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func capturePriceClick(_ sender: Any) {
        performSegue(withIdentifier: "showDetailSegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "showDetailSegue":
            let detailViewController = segue.destination as! DetailViewController
            detailViewController.selectedProduct = self.selectedProduct
            detailViewController.shoppingList = self.shoppingListId
            detailViewController.comesFromList = false
            let backItem = UIBarButtonItem()
            backItem.title = "Atrás"
            navigationItem.backBarButtonItem = backItem
            if storeId != "" {
                detailViewController.storeId = storeId
            }
        default:
            print("No hay un segue aquí")
        }
    }
}
