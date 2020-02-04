//
//  MasterListViewController.swift
//  ApiAIDemoWatchOSSwift
//
//  Created by Dx on 14/07/16.
//  Copyright © 2016 moak. All rights reserved.
//

import UIKit
import Firebase

class MasterHistoryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var historyViewController: HistoryViewController? = nil
    var tickets = [TicketSummary]()
    
    var selectedRow: IndexPath? = nil
    
    @IBOutlet weak var tableView: UITableView!
    
    var newWordField: UITextField?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configureList()
        
        let firebase = FirebaseClient()
        
        let userTickets = firebase.getUserTickets()
        
        _ = userTickets.observe(DataEventType.value, with: { (snapshot) in
            var newItems: [TicketSummary] = []
            if let postDict = snapshot.value as? [String : AnyObject] {
                
                for item in postDict.values {
                    let itemType = TicketSummary(parameters: item as! [String: AnyObject])
                    newItems.append(itemType)
                }
                
                self.tickets = newItems.sorted( by: { $0.ticketDate.timeIntervalSinceNow > $1.ticketDate.timeIntervalSinceNow })
                
                self.tableView.reloadData()
            }
        })
    }
    
    func configureList(){
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.separatorStyle = .singleLine
        self.tableView.tableFooterView = UIView()
    }
    
    // MARK: - Segues
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showList" {
            if let indexPath = self.selectedRow {
                
                let controller = segue.destination as! HistoryViewController
                controller.ticketSelected = tickets[(indexPath as NSIndexPath).row].id
            }
            let backItem = UIBarButtonItem()
            backItem.title = "Atrás"
			backItem.tintColor = .red
            navigationItem.backBarButtonItem = backItem
        }
    }
    
    // MARK: - Table View
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tickets.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! MasterHistoryCellView
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd"
        
        var formattedDate =  ""
        if let date = tickets[(indexPath as NSIndexPath).row].ticketDate {
            formattedDate = dateFormatter.string(from: date as Date)
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        
        cell.date.text = formattedDate
        cell.storeName.text = tickets[(indexPath as NSIndexPath).row].storeName
        cell.total.text = formatter.string(from: tickets[(indexPath as NSIndexPath).row].totalPrice as NSNumber)
        
        let bgColorView = UIView()
        bgColorView.backgroundColor = UIColor(red: 0.811, green: 0.831, blue: 0.831, alpha: 1)
        cell.selectedBackgroundView = bgColorView
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedRow = indexPath
        tableView.deselectRow(at: indexPath, animated: true)
        
        performSegue(withIdentifier: "showList", sender: self)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
        	let ticketId = tickets[indexPath.row].id
            tickets.remove(at: (indexPath as NSIndexPath).row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            let firebase = FirebaseClient()
            firebase.deleteTicket(ticketId: ticketId!)
            
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
}
