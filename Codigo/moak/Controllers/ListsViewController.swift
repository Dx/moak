//
//  ListsViewController.swift
//  Moak
//
//  Created by Dx on 01/03/16.
//  Copyright © 2016 Palmera. All rights reserved.
//

import UIKit
//import MBProgressHUD
import CoreLocation
import GooglePlaces
import Firebase
import AudioToolbox
import SideMenu
import BubbleTransition
import Lottie
import NotificationBannerSwift

class ListsViewController: UIViewController, UIViewControllerTransitioningDelegate, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, CLLocationManagerDelegate, StoreSelectorDelegate {
    
    @IBOutlet weak var totalPriceLabel: UILabel!
    @IBOutlet weak var closeListButton: UIButton!
    @IBOutlet weak var listTableView: UITableView!
    @IBOutlet weak var addProductsLabel: UILabel!
    @IBOutlet weak var storeButton: UIButton!
    @IBOutlet weak var addButton: UIButton!
    
    var locationManager = CLLocationManager()
    
    let defaults = UserDefaults.standard
    
    var lastLocation : CLLocation? = nil
    var isUpdatingLocation: Bool = false
    
    let transition = BubbleTransition()
    
    var currentList : ShoppingList? = nil
    
    var inputText: UITextField?
    
    var selectedProduct : Product!
    
    var textProducts: [String] = []
    
    var products: [Product] = []
    
    var listSelected: String = ""
    var listDescriptionSelected: String?
    
    var pointsNotification: [HistoryPoint] = []
	
	let localNotifications = Notification.Name(rawValue:"LocalNotifications")
    
    // MARK: - View methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setLocationManager()
        
        setViewControls()
		
		let nc = NotificationCenter.default
		nc.addObserver(forName:localNotifications, object:nil, queue:nil, using:catchNotification)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if self.defaults.string(forKey: "listId") == nil {
            self.getDefaultList() { (nothing: String) in
                self.loadTitle()
                self.loadShoppingList()
            }
        } else {
            loadTitle()
            loadShoppingList()
        }
		
		showPointsNotifications()
        
        becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resignFirstResponder()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == nil {
            return
        }
        
        switch segue.identifier! {
        case "showDetail":
            let detailViewController = segue.destination as! DetailViewController
            detailViewController.shoppingList = self.listSelected
            detailViewController.selectedProduct = self.selectedProduct
            detailViewController.comesFromList = true
            let backItem = UIBarButtonItem()
            backItem.title = "Atrás"
            backItem.tintColor = .red
            navigationItem.backBarButtonItem = backItem
            if let googlePlace = self.currentList!.place {
                detailViewController.storeId = googlePlace.id
            }
            detailViewController.list = self
            
        case "addBarCodeProductSegue":
            let barCodeController = segue.destination as! BarCodeScannerViewController
            barCodeController.selectedProduct = self.selectedProduct
            barCodeController.listId = self.listSelected
            barCodeController.currentGooglePlace = self.currentList!.place
            
            let backItem = UIBarButtonItem()
            backItem.title = "Cancelar"
            backItem.tintColor = .red
            navigationItem.backBarButtonItem = backItem
            
        case "storeSelectorSegue":
            let storeSelector = segue.destination as! StoreSelectorController
            storeSelector.delegate = self
            
            if self.currentList != nil {
                if let place = self.currentList!.placeShopping {
                    storeSelector.placeShopping = place.id
                }
            }
            
            storeSelector.lastLocation = self.lastLocation
            let backItem = UIBarButtonItem()
            backItem.title = "Cancelari"
            backItem.tintColor = .red
            navigationItem.backBarButtonItem = backItem
        case "showNewProductAdding":
            let controller = segue.destination
            controller.transitioningDelegate = self
            controller.modalPresentationStyle = .custom
            let newProductController = segue.destination as! NewProductNavigationViewController
            newProductController.listId = self.listSelected
        default:
            print("no action")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - View control methods
    
    @IBAction func addProductClick(_ sender: Any) {
        performSegue(withIdentifier: "showNewProductAdding", sender: self)
    }
    
    @IBAction func storeButtonClick(_ sender: Any) {
        self.performSegue(withIdentifier: "storeSelectorSegue", sender: self)
    }
    
    @IBAction func createTicket(_ sender: AnyObject) {
        
        if !products.contains(where: { $0.checked }) {
            self.showAlert(error: "Para cerrar el ticket debes tener productos marcados", title: "Ups")
            return
        }
        
        if self.currentList!.place != nil {
            
            let myAlert = UIAlertController(title: "Crear ticket", message: "¿Desea cerrar su compra y crear un ticket?", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .default) { (action) in
                self.createTicketConfirmed()
            }
            let cancelAction = UIAlertAction(title: "Cancelar", style: .default) { (action) in
                // ...
            }
            
            myAlert.addAction(okAction)
            myAlert.addAction(cancelAction)
            
            self.present(myAlert, animated: true, completion: nil)
        } else {
            self.showAlert(error: "Para cerrar el ticket debes elegir una tienda", title: "Ups")
        }
    }
	
	func catchNotification(notification:Notification) -> Void {
		print("Catch notification")
		
		guard let userInfo = notification.userInfo,
			let message  = userInfo["message"] as? HistoryPoint,
			let _     = userInfo["date"]    as? Date else {
				print("No userInfo found in notification")
				return
		}
		
		pointsNotification.append(message)
	}
	
    // MARK: - Methods
	
    func setViewControls() {
        configureTableList()
        setStoreButton()
        setSideMenuManager()
        setButtonAnimation()
    }
    
    func setStoreButton() {
        storeButton.titleLabel!.lineBreakMode = .byWordWrapping
        storeButton.titleLabel!.textAlignment = .center
    }
    
    func setButtonAnimation() {
        let buttonAnimation = AnimationView.init(name: "plusbutton")
        
        buttonAnimation.frame = CGRect(x: self.view.frame.midX - 33.5, y: addButton.frame.midY + 31, width: 67, height: 67)
        buttonAnimation.loopMode = .loop
        buttonAnimation.layer.zPosition = 7
        buttonAnimation.isUserInteractionEnabled = false
        self.view.addSubview(buttonAnimation)
        buttonAnimation.play()
    }
    
    func setSideMenuManager() {
        SideMenuManager.default.leftMenuNavigationController = storyboard!.instantiateViewController(withIdentifier: "LeftMenuNavigationController") as? SideMenuNavigationController
        
        SideMenuManager.default.menuFadeStatusBar = true
        SideMenuManager.default.menuAnimationTransformScaleFactor = 1
        // SideMenuManager.menuBlurEffectStyle = UIBlurEffectStyle.light
        SideMenuManager.default.menuAnimationFadeStrength = 0.3
        SideMenuManager.default.menuShadowOpacity = 0.3
        SideMenuManager.default.menuFadeStatusBar = true
        SideMenuManager.default.menuPresentMode = .viewSlideOutMenuIn
    }
    
    func setLocationManager() {
        
        locationManager.distanceFilter  = 10
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        self.locationManager.delegate = self
        
        if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways {
            if !isUpdatingLocation {
                locationManager.startUpdatingLocation()
            }
        } else {
            let alert = UIAlertController(title: "Me das permiso?", message: "Moak necesita acceder a tu posición para poder detectar si estás cerca de una tienda y mostrarte los mejores precios. Me autorizas?", preferredStyle: UIAlertController.Style.alert)
            
            alert.addAction(UIAlertAction(title: "No", style: .default, handler: { action in
                switch action.style{
                case .default:
                    print("default")
                    
                case .cancel:
                    print("cancel")
                    
                case .destructive:
                    print("destructive")
                @unknown default:
                    print("error")
                }
            }))
            
            alert.addAction(UIAlertAction(title: "Sí", style: .default, handler: { action in
                switch action.style{
                case .default:
                    print("default")
                    self.locationManager.requestAlwaysAuthorization()
                    
                    self.locationManager.startUpdatingLocation()
                    if CLLocationManager.authorizationStatus() != CLAuthorizationStatus.notDetermined {
                        if let appSettings = NSURL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.openURL(appSettings as URL)
                        }
                    }
                    
                case .cancel:
                    print("cancel")
                    
                case .destructive:
                    print("destructive")
                @unknown default:
                    print("error")
                }
            }))
            
            self.present(alert, animated: true, completion: nil)
        }
        
        
    }
    
    func loadTitle() {
        if let list = self.defaults.string(forKey: "listId") {
            self.listSelected = list
            
            if let listName = self.defaults.string(forKey: "listDescription") {
                self.listDescriptionSelected = listName
                self.navigationItem.title = self.listDescriptionSelected
            } else {
                let firebase = FirebaseClient()
                firebase.getShoppingList(shoppingListId: list) { (result: ShoppingList?) in
                    if let completeList = result {
                        self.defaults.set(completeList.name, forKey: "listDescription")
                        self.navigationItem.title = self.listDescriptionSelected
                    }
                }
            }
        }
    }
    
    func getDefaultList(completion: @escaping (_ nothing: String) -> Void) {
        let firebase = FirebaseClient()
        
        firebase.getUserDefaultShoppingList(completion: {(shoppingList: ShoppingList!) in
            
            if shoppingList != nil {
            	self.listSelected = shoppingList.id
                self.defaults.set(shoppingList.id, forKey: "listId")
                self.defaults.set(shoppingList.name, forKey: "listDescription")
                self.listDescriptionSelected = shoppingList.name
                self.navigationItem.title = shoppingList.name
                self.loadShoppingList()
                
                completion("")
            }
        })
    }
    
    func showPointsNotifications() {
		for point in pointsNotification{
			//let banner = NotificationBanner(title: "Puntos ganados!", subtitle: "Ganaste \(point.points) puntos por \(point.reason)", style: .success)
			// let view = PointNotification()
			
			let screenSize = UIScreen.main.bounds
			
			let anotherView = UIView()
			let label = UILabel(frame: CGRect(x: screenSize.width / 2, y: 30, width: 300, height: 21))
			label.center = CGPoint(x: screenSize.width / 2, y: 30)
			label.textAlignment = .center
			label.font = label.font.withSize(15)
			label.text = "Ganaste \(point.points) por \(point.reason)"
			label.textColor = UIColor.black
			
			let crownAnimation = AnimationView.init(name: "crown")
			
			crownAnimation.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
            crownAnimation.loopMode = .loop
			anotherView.addSubview(crownAnimation)
			crownAnimation.play()
			
			anotherView.backgroundColor = UIColor.white
			
			anotherView.addSubview(label)
			let banner = NotificationBanner(customView: anotherView)
			banner.haptic = .light
			banner.show()
		}
		
		pointsNotification.removeAll()
    }
    
    func addPoints(point: HistoryPoint) {
        pointsNotification.append(point)
    }
    
    func loadShoppingList() {
        let firebase = FirebaseClient()
        firebase.getShoppingList(shoppingListId: self.listSelected, completion: { result in
            
            if result != nil {
                self.currentList = result!
            }
        })
        
        self.suscribeToProducts()
    }
    
    // MARK: - StoreSelector Delegate
    func storeSelected(store: GooglePlaceResult?) {
        
        if store != nil {
            self.currentList!.place = store!
            self.storeButton.setTitle(self.currentList!.place?.name, for: .normal)
            self.setCurrentStore()
            self.reloadProducts()
        } else {
            self.currentList!.place = nil
        }
    }
    
    // MARK: - Functions
    
    func suscribeToProducts() {
        let firebase = FirebaseClient()
        
        let productsInList = firebase.getRefToProductsInShoppingList(shoppingList: listSelected)
        
        _ = productsInList.observe(DataEventType.value, with: { (snapshot) in
            var newItems: [Product] = []
            if let postDict = snapshot.value as? [String : AnyObject] {
                
                for item in postDict.values {
                    if let items = item as? [String: AnyObject] {
                        let itemType = Product(parameters: items)
                    	newItems.append(itemType)
                    }
                }
                
                let newItems2 = newItems.filter(){ $0.productName != "" }
                
                self.products = newItems2.sorted( by: { $0.listedOrder == $1.listedOrder ? $0.listedDate > $1.listedDate : $0.listedOrder < $1.listedOrder } )
                
                self.reloadProducts()
            }
        })
    }
    
    override var canBecomeFirstResponder : Bool {
        return true
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            let alertController = UIAlertController(title: "Orden de lista", message: "¿Desea ordenar la lista en automático?", preferredStyle: .alert)
            
            let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) {
                UIAlertAction in
                
                self.orderList()
                
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) {
                UIAlertAction in
                print("Cancel Order Pressed")
            }
            
            // Add the actions
            alertController.addAction(okAction)
            alertController.addAction(cancelAction)
            
            // Present the controller
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    // MARK: - CoreLocationManager
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("didChangeAuthorizationStatus")
        
        switch status {
        case .notDetermined:
            print(".NotDetermined")
            break
            
        case .authorizedAlways:
            print(".Authorized")
            self.locationManager.startUpdatingLocation()
            break
            
        case .denied:
            print(".Denied")
            break
            
        default:
            print("Unhandled authorization status")
            break
            
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        isUpdatingLocation = true
        self.lastLocation = locations.last! as CLLocation
        if self.lastLocation != nil && self.currentList != nil {
            print("didUpdateLocations:  \(self.lastLocation!.coordinate.latitude), \(self.lastLocation!.coordinate.longitude)")
            
            if Swift.abs(self.defaults.double(forKey: "currentLatitude") - self.lastLocation!.coordinate.latitude) > 0.0001 || Swift.abs(self.defaults.double(forKey: "currentLongitude") - self.lastLocation!.coordinate.longitude) > 0.0001 {
            
            
            	self.defaults.set(self.lastLocation!.coordinate.latitude, forKey: "currentLatitude")
            	self.defaults.set(self.lastLocation!.coordinate.longitude, forKey: "currentLongitude")
            
            	self.selectClosestStore()
            }
        }
    }
    
    // MARK: - Table View
    
    func configureTableList() {
        listTableView.delegate = self
        listTableView.dataSource = self
        listTableView.separatorStyle = .singleLine
        listTableView.tableFooterView = UIView()
        
        // To order the list
        let longpress = UILongPressGestureRecognizer(target: self, action: #selector(ListsViewController.longPressGestureRecognized(_:)))
        listTableView.addGestureRecognizer(longpress)
    }
    
    func orderList() {
        self.products = self.products.sorted(by: { !$0.checked && $1.checked } )
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        saveListOrder()
        self.listTableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ""
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableView {
        case listTableView:
            self.addProductsLabel.isHidden = products.count > 0
            self.listTableView.isHidden = products.count == 0
            if self.products.count == 0 {
                self.closeListButton.isHidden = true
                self.totalPriceLabel.isHidden = true
            }
            
            return products.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch tableView {
        case listTableView:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ListCell
            cell.selectionStyle = .none
            
            if let product = products[(indexPath as NSIndexPath).row] as Product? {
                cell.toDoItem = product
            }
            
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let product = products[(indexPath as NSIndexPath).row] as Product? {
            self.gotoDetail(product: product)
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let product = self.products[indexPath.row]
        var title = "Sacar del carrito"
        if !product.checked {
            title = "Meter al carrito"
        }
        
        let uncheck = UITableViewRowAction(style: .normal, title: title) { action, index in
            let product = self.products[indexPath.row]
            let checked = product.checked
            self.checkProductInList(product: product, checked: !checked)
        }
        
        uncheck.backgroundColor = UIColor(red: 0, green: 0.611, blue: 0.655, alpha: 0.65)

        let edit = UITableViewRowAction(style: .normal, title: "Editar") { action, index in
            if let product = self.products[(indexPath as NSIndexPath).row] as Product? {
                
                self.selectedProduct = product
                self.gotoDetail(product: product)
            }
        }
        edit.backgroundColor = UIColor(red: 0.29, green: 0.42, blue: 0.54, alpha: 0.65)

        let delete = UITableViewRowAction(style: .normal, title: "Borrar") { action, index in
            
            let product = self.products[indexPath.row]
            
            self.products.remove(at: indexPath.row)
            let firebase = FirebaseClient()
            firebase.deleteProduct(shoppingList: self.listSelected, productId: product.productId)
            
            // loop over the visible cells to animate delete
            let visibleCells = self.listTableView.visibleCells as! [ListCell]
            let lastView = visibleCells[visibleCells.count - 1] as ListCell
            var delay = 0.0
            var startAnimating = false
            for i in 0..<visibleCells.count {
                let cell = visibleCells[i]
                if startAnimating {
                    UIView.animate(withDuration: 0.3, delay: delay, options: UIView.AnimationOptions(),
                                   animations: {() in
                                    cell.frame = cell.frame.offsetBy(dx: 0.0,
                                                                     dy: -cell.frame.size.height)},
                                   completion: {(finished: Bool) in
                                    if (cell == lastView) {
                                        self.reloadProducts()
                                    }
                        }
                    )
                    delay += 0.03
                }
                if cell.toDoItem === product {
                    startAnimating = true
                    cell.isHidden = true
                }
            }
            
            // use the UITableView to animate the removal of this row
            self.listTableView.beginUpdates()
            self.listTableView.deleteRows(at: [indexPath], with: .fade)
            self.listTableView.endUpdates()
            
            if self.products.count == 0 {
                self.closeListButton.isHidden = true
                self.totalPriceLabel.isHidden = true
            }
        }
        
        delete.backgroundColor = UIColor(red: 0.95, green: 0.27, blue: 0.27, alpha: 0.65)
        
        return [uncheck, delete]
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
        } else if editingStyle == .insert {
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // MARK: - UIViewControllerTransitioningDelegate
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.transitionMode = .present
        transition.startingPoint = addButton.center
        transition.bubbleColor = addButton.backgroundColor!
        return transition
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.transitionMode = .dismiss
        transition.startingPoint = addButton.center
        transition.bubbleColor = addButton.backgroundColor!
        return transition
    }
    
	// MARK: - Functions
    
	@objc func longPressGestureRecognized(_ gestureRecognizer: UIGestureRecognizer) {
        let longPress = gestureRecognizer as! UILongPressGestureRecognizer
        let state = longPress.state
        let locationInView = longPress.location(in: listTableView)
        let indexPath = listTableView.indexPathForRow(at: locationInView)
        
        struct My {
            static var cellSnapshot : UIView? = nil
        }
        struct Path {
            static var initialIndexPath : IndexPath? = nil
        }
        
        switch state {
        case UIGestureRecognizerState.began:
            if indexPath != nil {
                Path.initialIndexPath = indexPath
                let cell = listTableView.cellForRow(at: indexPath!) as UITableViewCell?
                My.cellSnapshot  = snapshopOfCell(cell!)
                var center = cell?.center
                My.cellSnapshot!.center = center!
                My.cellSnapshot!.alpha = 0.0
                listTableView.addSubview(My.cellSnapshot!)
                
                UIView.animate(withDuration: 0.25, animations: { () -> Void in
                    center?.y = locationInView.y
                    My.cellSnapshot!.center = center!
                    My.cellSnapshot!.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                    My.cellSnapshot!.alpha = 0.98
                    cell?.alpha = 0.0
                    
                    }, completion: { (finished) -> Void in
                        if finished {
                            cell?.isHidden = true
                        }
                })
            }
            
        case UIGestureRecognizerState.changed:
            var center = My.cellSnapshot!.center
            center.y = locationInView.y
            My.cellSnapshot!.center = center
            if ((indexPath != nil) && (indexPath != Path.initialIndexPath)) {
                swap(&products[(indexPath! as NSIndexPath).row], &products[(Path.initialIndexPath! as NSIndexPath).row])
                listTableView.moveRow(at: Path.initialIndexPath!, to: indexPath!)
                Path.initialIndexPath = indexPath
                
            }
        case UIGestureRecognizerState.ended:
            let cell = listTableView.cellForRow(at: Path.initialIndexPath!) as UITableViewCell?
            cell?.isHidden = false
            cell?.alpha = 0.0
            UIView.animate(withDuration: 0.25, animations: { () -> Void in
                My.cellSnapshot!.center = (cell?.center)!
                My.cellSnapshot!.transform = CGAffineTransform.identity
                My.cellSnapshot!.alpha = 0.0
                cell?.alpha = 1.0
            }, completion: { (finished) -> Void in
                if finished {
                    Path.initialIndexPath = nil
                    My.cellSnapshot!.removeFromSuperview()
                    My.cellSnapshot = nil
                }
            })
            self.saveListOrder()
            
        default:
            let cell = listTableView.cellForRow(at: Path.initialIndexPath!) as UITableViewCell?
            cell?.isHidden = false
            cell?.alpha = 0.0
            UIView.animate(withDuration: 0.25, animations: { () -> Void in
                My.cellSnapshot!.center = (cell?.center)!
                My.cellSnapshot!.transform = CGAffineTransform.identity
                My.cellSnapshot!.alpha = 0.0
                cell?.alpha = 1.0
                }, completion: { (finished) -> Void in
                    if finished {
                        Path.initialIndexPath = nil
                        My.cellSnapshot!.removeFromSuperview()
                        My.cellSnapshot = nil
                    }
            })
        }
    }
    
    func snapshopOfCell(_ inputView: UIView) -> UIView {
        UIGraphicsBeginImageContextWithOptions(inputView.bounds.size, false, 0.0)
        inputView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()! as UIImage
        UIGraphicsEndImageContext()
        let cellSnapshot : UIView = UIImageView(image: image)
        cellSnapshot.layer.masksToBounds = false
        cellSnapshot.layer.cornerRadius = 0.0
        cellSnapshot.layer.shadowOffset = CGSize(width: -5.0, height: 0.0)
        cellSnapshot.layer.shadowRadius = 5.0
        cellSnapshot.layer.shadowOpacity = 0.4
        return cellSnapshot
    }
    
    func saveListOrder() {
        var counter: Float = 0
        for _ in products {
            
            let firebase = FirebaseClient()
            firebase.updateProductOrder(shoppingList: self.listSelected, purchaseId: products[Int(counter)].productId, order: counter)
            counter = counter + 1
        }
    }
    
    func showAlert(error:String, title: String) {
        let myAlert = UIAlertController(title: title, message: error, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
            // ...
        }
        myAlert.addAction(OKAction)
        self.present(myAlert, animated: true, completion: nil)
    }
    
    func addProduct(product: [String: AnyObject]) {
        
        let firebaseClient = FirebaseClient()
        
        firebaseClient.addProductInShoppingList(shoppingList: self.listSelected, product: Product(parameters: product))
        
        self.reloadProducts()
    }
    
    func checkProductInList(product: Product, checked: Bool) {
        product.checked = checked
        
        let firebase = FirebaseClient()
        firebase.check(shoppingList: self.listSelected, purchaseId: product.productId, checked: product.checked)
        
        self.reloadProducts()
    }
    
    func gotoDetail(product: Product) {
    	self.selectedProduct = product
        self.performSegue(withIdentifier: "showDetail", sender: nil)
    }
    
    func reloadProducts() {
        
        self.listTableView.reloadData()
        
        var isSomeChecked = false
        
        var totalPrice: Float = 0
        
        for product in self.products {
            if product.checked {
                
                isSomeChecked = true
                
                if product.unitaryPrice > 0 {
                    totalPrice = product.totalPrice + totalPrice
                }
            }
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        
        let number = NSNumber(value:totalPrice)
        
        self.totalPriceLabel.text = formatter.string(from: number)
        
        self.closeListButton.isHidden = !isSomeChecked
        self.totalPriceLabel.isHidden = !isSomeChecked
        
        self.listTableView.reloadData()
    }
    
    func updateComparisonPrices(completion: @escaping (_ updated: Bool) -> Void) {
        
        if self.currentList!.place == nil {
            completion(false)
            return 
        }
        
        let group = DispatchGroup()
        var updated = false
        if products.count > 0 {
            for index in 0...products.count - 1 {
                group.enter()
                let product = products[index]
                if product.checked && product.productSKU != "" {
                    let firebase = FirebaseClient()
                    firebase.getLastPriceInStore(storeId:self.currentList!.place!.id, skuNumber: product.productSKU) { (price: ProductComparer?) in
                        if let price = price {
                            updated = true
                            self.products[index].unitaryEstimatedPrice = price.unitaryPrice
                            self.products[index].totalEstimatedPrice = price.unitaryPrice * self.products[index].quantity
                        }
                    }
                }
                group.leave()
                _ = group.wait(timeout: DispatchTime.distantFuture)
                
            }
            completion(updated)
        } else {
            completion(false)
        }
    }
    
    func createTicketConfirmed() {
        
        let firebase = FirebaseClient()
        
        var totalPrice: Float = 0
        
        for product in self.products {
            if product.checked {
                totalPrice = product.totalPrice + totalPrice
            }
        }
        
        var ticketId = ""
        
        // Create the ticket
        let ticket = Ticket()
        ticket.shoppingList = self.listSelected
        ticket.ticketDate = Date()
        ticket.totalPrice = totalPrice
        if let store = self.currentList!.place {
            ticket.storeId = store.id
            ticket.storeLatitude = store.latitude
            ticket.storeLongitude = store.longitude
            ticket.storeName = store.name
        } else {
            ticket.storeId = ""
            ticket.storeLatitude = 0
            ticket.storeLongitude = 0
            ticket.storeName = ""
        }
        
        ticketId = firebase.addTicket(ticket)
        
        for product in self.products {
            if product.checked {
                firebase.moveProductToTicket(self.listSelected, product: product, ticketId: ticketId, storeId: ticket.storeId, storeName: ticket.storeName)
            } else {
                firebase.deleteProduct(shoppingList: self.listSelected, productId: product.productId)
            }
            
            if product.productSKU != "" && product.unitaryPrice > 0 && ticket.storeId != "" {
                let price = ProductComparer()
                if product.productSKUName != "" {
                	price.productName = product.productSKUName
                } else {
                    price.productName = product.productName
                }
                price.sku = product.productSKU
                price.storeId = ticket.storeId
                price.storeName = ticket.storeName
                price.priceDate = Date()
                price.unitaryPrice = product.unitaryPrice
                
                firebase.setProductPrice(price: price, shoppingListId: self.listSelected)
            }
        }
        
        firebase.deleteStoreFromList(list: self.listSelected)
        
        self.reloadProducts()
    }
    
    func setCurrentStore() {
        let firebase = FirebaseClient()
        
        if self.currentList != nil {
            if let currentStore = self.currentList!.place {
                firebase.setStoreInUserFavs(store: currentStore)
                firebase.setStoreInShoppingList(shoppingListId: self.listSelected, store: currentStore)
                
                self.estimateTotal()
                
            } else {
                firebase.deleteStoreFromList(list: self.listSelected)
            }
        }
    }
    
    func estimateTotal() {
        let firebase = FirebaseClient()
        if self.currentList!.place != nil {
            for product in products {
                if product.productSKU != "" {
                    firebase.getLastPriceInStore(storeId: self.currentList!.place!.id, skuNumber: product.productSKU) { (price: ProductComparer?) in
                        if let price = price {
                            let total = price.unitaryPrice * product.quantity
                            firebase.updateProductPrice(shoppingList: product.shoppingList, purchaseId: product.productId, modeBuying: 0, unitaryPrice: price.unitaryPrice, totalPrice: total)
                        }
                    }
                }
            }
        }
    }
    
    func showAlertForProduct(_ completion:@escaping (String?) -> ()) {
        let alertController = UIAlertController(title: "No se encontró el código de barras", message: "Captura el nombre del producto", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) {
            UIAlertAction in
            
            if self.inputText != nil {
                completion(self.inputText!.text)
            }
            
            NSLog("OK Undo Pressed")
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) {
            UIAlertAction in
            NSLog("Cancel Undo Pressed")
        }
        
        // Add the actions
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        
        // Add the textField
        alertController.addTextField(configurationHandler: configurationTextField)
        
        // Present the controller
        self.present(alertController, animated: true, completion: nil)
        
    }
    
    func configurationTextField(textField: UITextField!)
    {
        if (textField) != nil {
            self.inputText = textField!        //Save reference to the UITextField
            self.inputText?.text = ""
        }
    }
    
    func selectClosestStore() {
        if self.currentList != nil {
            let gpClient = GooglePlacesClient()
            gpClient.getCloserStore(currentLocation: self.lastLocation!) { (result: GooglePlaceResult?, error: String?) in
                
                if result != nil {
                    print("distancia a tienda \(result!.distance)")
                    if result!.distance < 30 {
                        self.currentList!.place = result
                        self.storeButton.setTitle(self.currentList!.place?.name, for: .normal)
                        self.storeButton.setTitleColor(UIColor.red, for: .normal)
                    }
                } else {
                    
                    self.currentList!.place = nil
                }
                
                self.setCurrentStore()
            }
        }
    }
}

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
