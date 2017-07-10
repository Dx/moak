//
//  SearchProductViewController.swift
//  moak
//
//  Created by Dx on 04/09/16.
//  Copyright © 2016 Dx. All rights reserved.
//

import UIKit

class SearchProductViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var productText: UITextField!
    @IBOutlet weak var searchProductsTable: UITableView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    var productDescription = ""
    var products: [SearchProduct] = []
    var detailController: DetailViewController? = nil
    
    override func viewDidLoad() {
        searchProductsTable.delegate = self
        searchProductsTable.dataSource = self
        self.searchProductsTable.tableFooterView = UIView()
        self.productText.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: UIControlEvents.editingChanged)
        self.productText.text = "\(self.detailController!.productName.text!) "
        self.searchProducts(self.productText.text!)
    }
    
    func textFieldDidChange(_ textField: UITextField) {
        let name = self.productText.text!
        self.searchProducts(name)
    }
    
    func searchProducts(_ name: String) {
        self.startActivity(true)
        let name = name.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        if name == "" {
            self.products = []
            self.searchProductsTable.reloadData()
            return
        }
        
        let search = SearchClient()
        search.retrieveProductsWithName(name) { (result:[SearchProduct], error: String?) in
            if result.count > 0 {
                DispatchQueue.main.async {
                    self.products = result
                    self.searchProductsTable.reloadData()
                }
            } else {
                self.startActivity(false)
            }
        }
    }
    
    func startActivity(_ on: Bool) {
        if on {
            self.activityIndicator.startAnimating()
            self.activityIndicator.isHidden = false
        } else {
        	self.activityIndicator.stopAnimating()
            self.activityIndicator.isHidden = true
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! SearchProductCell
        
        cell.categoryLabel.text = products[(indexPath as NSIndexPath).row].categorias.joined(separator: "-")
        cell.nameLabel.text = products[(indexPath as NSIndexPath).row].nombre
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        let number = NSNumber(value:products[(indexPath as NSIndexPath).row].precioEstimado)
        cell.priceLabel.text = formatter.string(from: number)
        self.startActivity(false)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.detailController!.productSelected(products[(indexPath as NSIndexPath).row])
    }
}
