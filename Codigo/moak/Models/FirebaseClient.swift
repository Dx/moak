//  FirebaseClient.swift
//  moak
//
//  Created by Dx on 03/07/16.
//  Copyright © 2016 moak. All rights reserved.
//

import Foundation
import Firebase
import FirebaseDatabase
import CoreLocation

class FirebaseClient {
    
    var db : DatabaseReference!
    let defaults = UserDefaults.standard
    
    var notUsefulWords = [String]()
    
    init() {
        self.db = Database.database().reference()
        initWords()
    }
    
    func initWords() {
        notUsefulWords.append("de")
        notUsefulWords.append("en")
        notUsefulWords.append("el")
        notUsefulWords.append("para")
        notUsefulWords.append("con")
        notUsefulWords.append("la")
        notUsefulWords.append("los")
        notUsefulWords.append("las")
        notUsefulWords.append("del")
        notUsefulWords.append("verga")
        notUsefulWords.append("berga")
        notUsefulWords.append("caca")
        notUsefulWords.append("mierda")
        notUsefulWords.append("chingada")
        notUsefulWords.append("chingado")
        notUsefulWords.append("puto")
        notUsefulWords.append("puta")
        notUsefulWords.append("pinche")
        notUsefulWords.append("pinchi")
        notUsefulWords.append("culero")
    }
    
    func getUserId(_ completion:@escaping (String) -> ()) {
        
        Auth.auth().addStateDidChangeListener { auth, user in
            if let user = user {
                completion(user.uid)
            }
        }
    }
    
    // MARK: - Products
    
    func getRefToProductsInShoppingList(shoppingList: String) -> DatabaseReference {
        return self.db.child("productsInShoppingList").child(shoppingList)
    }
    
    func getProductInShoppingList(shoppingList: String, productId: String, completion:@escaping (_ product: Product?) -> Void) {
        self.db.child("productsInShoppingList").child(shoppingList).child(productId).observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let value = snapshot.value as? [String: AnyObject] {
                let product = Product(parameters: value)
                completion(product)
            } else {
                completion(nil)
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func addProductInShoppingList(shoppingList: String, product: Product) {
        
        self.getProductInShoppingList(shoppingList: shoppingList, productId: product.productSKU, completion: {(lastProduct: Product?) in
            
            if lastProduct == nil {
                product.productId = product.productSKU
                product.listedOrder = 0
                let document = product.getFirebaseObject()
                
                let childUpdates = ["productsInShoppingList/\(shoppingList)/\(product.productSKU)": document]
                self.db.updateChildValues(childUpdates)
            }
        })
    }
    
    func check(shoppingList: String, purchaseId: String, checked: Bool) {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let date = dateFormatter.string(from: Date())
        
        self.db.child("productsInShoppingList").child(shoppingList).child(purchaseId).child("checked").setValue(checked)
            
        self.db.child("productsInShoppingList").child(shoppingList).child(purchaseId).child("checkedDate").setValue(date)
    }
    
    func updateProductName(shoppingList: String, purchaseId: String, productName: String, productSKUName: String, productSKU: String) {
        let childUpdates = ["productsInShoppingList/\(shoppingList)/\(purchaseId)/productName": productName,
                            "productsInShoppingList/\(shoppingList)/\(purchaseId)/productSKUName": productSKUName,
                            "productsInShoppingList/\(shoppingList)/\(purchaseId)/productSKU": productSKU]
        self.db.updateChildValues(childUpdates)
    }
    
    func updateProductPrice(shoppingList: String, purchaseId: String, buyThreePayTwo: Bool, unitaryPrice: Float, totalPrice: Float) {
        let childUpdates = ["productsInShoppingList/\(shoppingList)/\(purchaseId)/unitaryPrice": unitaryPrice,
                            "productsInShoppingList/\(shoppingList)/\(purchaseId)/buyThreePayTwo": buyThreePayTwo,
                            "productsInShoppingList/\(shoppingList)/\(purchaseId)/totalPrice": totalPrice] as [String : Any]
        self.db.updateChildValues(childUpdates as [AnyHashable: Any])
    }
    
    func updateProductQuantity(shoppingList: String, purchaseId: String, quantity: NSDecimalNumber, totalPrice: Float) {
        let childUpdates = ["productsInShoppingList/\(shoppingList)/\(purchaseId)/quantity": quantity,
                            "productsInShoppingList/\(shoppingList)/\(purchaseId)/totalPrice": totalPrice] as [String : Any]
        self.db.updateChildValues(childUpdates as [AnyHashable: Any])
    }
    
    func updateProductOrder(shoppingList: String, purchaseId: String, order: Float) {
        let childUpdates = ["productsInShoppingList/\(shoppingList)/\(purchaseId)/listedOrder": order]
        self.db.updateChildValues(childUpdates as [AnyHashable: Any])
    }
    
    func deleteProduct(shoppingList: String, productId: String) {
        self.db.child("productsInShoppingList").child(shoppingList).child(productId).removeValue()
    }
    
    func setProductSKU(productName: String, sku: String) {
        
        if productName != "" {
        	self.db.child("userSkus").child(sku).setValue(productName)
        }
    }
    
    func getProductSKU(sku: String, completion:@escaping (_ productName: String) -> Void) {
        
        
        self.db.child("userSkus").child(sku).observeSingleEvent(of: .value, with: { (snapshot) in
            
            	if let value = snapshot.value as? String {
                    completion(value)
                } else {
                    completion("")
                }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func moveUserProductsToGeneralUserProducts() {
//        let userId = "U4iV970MNNMDtye8JuQYOw6NmF02"
        let userId = "0YK9X1pqzyg1zfc1Tvi5YgsjDJp2"
//        let userId = self.defaults.string(forKey: "userId")!
        
        self.db.child("userSkus").child(userId).observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let value = snapshot.value as? [String: AnyObject] {
                for product in value {
                    	self.setProductSKU(productName: product.value as! String, sku: product.key)
                    }
                }
            }
        )
    }
    
    func movePricesByStoreT() {
        self.db.child("pricesByStore").observeSingleEvent(of: .value, with: { (snapshot) in
            if let value = snapshot.value as? [String: AnyObject] {
                for sku in value {
                    if let stores = sku.value as? [String: AnyObject] {
                        for store in stores {
                            if let prices = store.value as? [String: AnyObject] {
                                for price in prices {
                            		self.getPrice(priceId: price.key) {(result: ProductComparer?) in                                
                                		if result != nil {
                                			self.setProductPriceInStoreDate(price: result!)
                                		}
                            		}
                                }
                        	}
                        }
                    }
                }
            }
        })
    }
    
    func setProductPrice(price: ProductComparer, shoppingListId: String) {
        let userId = self.defaults.string(forKey: "userId")!
        
        let key = db.child("prices").childByAutoId().key
        price.id = key
        price.capturedByUserId = userId
        db.child("prices").child(key).setValue(price.getFirebaseObject())
        
        db.child("userShops").child(userId).child(price.sku).child(key).setValue(key)
        
        getUserIdsSharingShoppingList(shoppingList: shoppingListId) { (result: [String]?) in
            if let userNames = result {
                for userName in userNames {
                    self.db.child("userShops").child(userName).child(price.sku).child(key).setValue(key)
                }
            }
        }
        
        if price.storeId != "" {
            setProductPriceInStoreDate(price: price)
        }
    }
    
    func getStringDate(date: Date) -> String {
        let calendar = Calendar.current
        
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        var stringMonth = "\(month)"
        if month < 10 {
            stringMonth = "0\(month)"
        }
        let day = calendar.component(.day, from: date)
        var stringDay = "\(day)"
        if day < 10 {
            stringDay = "0\(day)"
        }
        return "\(year)-\(stringMonth)-\(stringDay)"
    }
    
    func setProductPriceInStoreDate(price: ProductComparer) {
        
        let stringDate = self.getStringDate(date: price.priceDate)
        
        db.child("pricesByStore").child(price.sku).child(stringDate).child(price.storeId).setValue(price.getFirebaseObject())
    }
    
    func getLastProductPrices(skuNumber: String,completion:@escaping (_ userShops: [ProductComparer]) -> Void) {
        var prices = [ProductComparer]()
        let group = DispatchGroup()
        
        let gpClient = GooglePlacesClient()
        let latitude = self.defaults.double(forKey: "currentLatitude")
        let longitude = self.defaults.double(forKey: "currentLongitude")
        let currentLocation = CLLocation(latitude: latitude, longitude: longitude)
        
        gpClient.getCloserStoreIds(currentLocation: currentLocation) { (result: [String]?, error: String?) in
            
            group.enter()
            if result != nil  {
            	for storeId in result! {
                
            	    self.getLastPriceInStore(storeId: storeId, skuNumber: skuNumber) { (price: ProductComparer?) in
                	    if let price = price {
                    	    prices.append(price)
                        	completion(prices)
                    	}
                	}
            	}
            
            	group.leave()
            
            	_ = group.wait(timeout: DispatchTime.distantFuture)
            	completion(prices)
            } else {
                completion([ProductComparer]())
            }
        }
    }
    
    func getLastPriceInStore(storeId: String, skuNumber: String, completion: @escaping (_ price: ProductComparer?) -> Void) {
        self.db.child("pricesByStore").child(skuNumber).child(storeId).queryLimited(toLast: 1).observeSingleEvent(of: .value, with: { (snapshot) in
            if let prices = snapshot.value! as? [String: AnyObject] {
                for price in prices {
                    self.getPrice(priceId: price.value as! String) { (price: ProductComparer?) in
                        if price != nil {
        					completion(price)
        				} else {
        					completion(nil)
        				}
                    }
                }
            }
        })
    }
    
    func getLastUserPrices(skuNumber: String, priceNumber: Int, completion:@escaping (_ userShops: [ProductComparer]) -> Void) {
        
        let userId = self.defaults.string(forKey: "userId")!
        
        self.db.child("userShops").child(userId).child(skuNumber).queryOrderedByKey().queryLimited(toFirst: UInt(priceNumber)).observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let prices = snapshot.value! as? [String: AnyObject] {
                var pricesResult = [ProductComparer]()
                for price in prices {
                    self.getPrice(priceId: price.value as! String) { (price: ProductComparer?) in
                        if price != nil {
                            pricesResult.append(price!)
                            completion(pricesResult)
                        }
                    }
                }
            } else {
                completion([ProductComparer]())
            }
        })
    }
    
    func getPrice(priceId: String, completion: @escaping (_ price: ProductComparer?) -> Void) {
        self.db.child("prices").child(priceId).observeSingleEvent(of: .value, with: { (snapshot) in
            if let parameters = snapshot.value as? [String: AnyObject] {
                let price = ProductComparer(parameters: parameters)
                completion(price)
            } else {
                completion(nil)
            }
        })
    }
    
    func setSpecificSkuToGenericSku(specificSku: String, genericSku: String) {
        
        let userId = self.defaults.string(forKey: "userId")!
        
        self.db.child("userSkuRelations").child(userId).child(genericSku).child(specificSku).setValue(specificSku)
    }
    
    func saveUserProduct(name: String, sku: String) {
        
        let nameArr : [String] = name.components(separatedBy: " ")
        
        for element in nameArr {
            
            if !notUsefulWords.contains(element.lowercased()) {
            	self.db.child("userProducts").child(element).child(sku).setValue(name)
            }
        }
    }
    
    func getUserProductsWithName(nameSearch: String, completion: @escaping (_ result: [SearchProduct]?) -> Void) {
        
        var resultArray = [SearchProduct]()
        
        self.db.child("userProducts").child(nameSearch).observeSingleEvent(of: .value, with: { (snapshot) in
        	
            if let product = snapshot.value! as? [String: AnyObject] {
                for productSku in product {
                    let resultado = SearchProduct()
                    resultado.nombre = productSku.value as! String
                    resultado.sku = productSku.key
                    resultado.userProduct = true
                    resultArray.append(resultado)
                }
                completion(resultArray)
            } else {
                completion(nil)
            }
        })
    }
    
    func setShopsT() {
        self.db.child("userShops").child("NT8Y9S4TmpgPTO0gVRoFnDTXlfm1").observeSingleEvent(of: .value, with: { (snapshot) in
            if let prices = snapshot.value! as? [String: AnyObject] {
                for price in prices {
                    for priceKey in (price.value as? [String: AnyObject])! {
                    	self.db.child("userShops").child("0YK9X1pqzyg1zfc1Tvi5YgsjDJp2").child(price.key).child(priceKey.key).setValue(priceKey.key)
                    }
                }
            }
        })
    }
    
    func setAveragePerProduct(userId: String, skuText: String) {
        
        let calendar = NSCalendar.current
        
        self.getLastUserPrices(skuNumber: skuText, priceNumber: 30) { (historyProductsQuery: [ProductComparer]) in
            
            var dayDiffs = [Int]()
            
            let historyProducts = historyProductsQuery.sorted( by: { $0.priceDate.compare($1.priceDate) == .orderedDescending })
            
            if historyProducts.count < 2 {
                return
            }
            
            for index in 0...historyProducts.count - 2 {
                let date1 = calendar.startOfDay(for: historyProducts[index].priceDate)
                let date2 = calendar.startOfDay(for: historyProducts[index + 1].priceDate)
                
                let components = calendar.dateComponents([.day], from: date1, to: date2)
                dayDiffs.append(Swift.abs(components.day!))
            }
            
            let average = self.average(numbers: dayDiffs)
            
            let userProductAverage = UserProductAverage(sku: skuText, productName: historyProducts[0].productName, average: average, lastPrice: historyProducts[0].unitaryPrice, lastShoppingDate: historyProducts[0].priceDate)
            
            self.db.child("userShopsAverage").child(userId).child(skuText).setValue(userProductAverage.getFirebaseObject())
            
            // DX QUITAR
            self.db.child("userShopsAverage").child("0YK9X1pqzyg1zfc1Tvi5YgsjDJp2").child(skuText).setValue(userProductAverage.getFirebaseObject())
        }
    }
    
    func getAverageProducts(completion: @escaping (_ products: [UserProductAverage]) -> Void) {
        
        let userId = self.defaults.string(forKey: "userId")!
        
        var result:[UserProductAverage] = []
        
        self.db.child("userShopsAverage").child(userId).observeSingleEvent(of: .value, with: { (snapshot) in
            if let products = snapshot.value as? [String: AnyObject] {
                for product in products {
                    
                    if let productParams = product.value as? [String: AnyObject] {
                    
                    	let product = UserProductAverage(parameters: productParams)
                        if product.daysToBuy() > -8 && product.daysToBuy() < 8 {
                			result.append(product)
                        }
                    }
                }
                
                result = result.sorted( by: { $0.floatProgressBar() > $1.floatProgressBar() })
                
                completion(result)
            } else {
                completion([UserProductAverage]())
            }
        })
    }
    
    func average(numbers: [Int]) -> Double {
        return Double(numbers.reduce(0, +)) / Double(numbers.count)
    }
    
    // MARK: - Users
    
    func addUser (user: User) {
        let userId = self.defaults.string(forKey: "userId")!
        user.id = userId
        let document = user.getFirebaseObject()
        
        self.db.child("users").child(userId).setValue(document, andPriority: "email", withCompletionBlock: {_,_ in
        })
        
        //This didn't work, lets use another index
        let emailComma = user.email.replacingOccurrences(of: ".", with: ",")
        let value = ["userId":userId]
        self.db.child("userMails/\(emailComma)").setValue(value)
    }
    
    func getUserNameByUserId(_ userId: String, completion:@escaping (_ userNames: String) -> Void) {
        self.db.child("users").child(userId).observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let value = snapshot.value as? [String: AnyObject] {
                
                if let _ = value["id"] as? String {
                    
                    completion(value["userName"] as! String)
                } else {
                    completion("")
                }
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func getUserIdsSharingShoppingList(shoppingList: String, completion:@escaping ([String]?) -> ()) {
        let userId = self.defaults.string(forKey: "userId")
        var usersResult = [String]()
        
        self.db.child("shoppingLists").child(shoppingList).child("sharedWith").observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let users = snapshot.value! as? [String: AnyObject] {
                for user in users {
                    if user.key != userId {
                        usersResult.append(user.key)
                    }
                }
                
                completion(usersResult)
            }
        })
    }
    
    func getUser(_ completion:@escaping (User?) -> ()) {
        let userId = self.defaults.string(forKey: "userId")!
        self.db.child("users").child(userId).observeSingleEvent(of: .value, with: { (snapshot) in
            
            var user: User? = nil
            
            if let value = snapshot.value as? [String: AnyObject] {
            
                if let id = value["id"] as? String {
                    
                    var name = ""
                    if let pname = value["name"] as? String {
                        name = pname
                    }
                    
                    var userName = ""
                    if let value = value["userName"] as? String {
                        userName = value
                    }
                    
                    let email = value["email"] as! String
                    
                    let firstname = value["firstName"] as! String
                    
                    let lastname = value["lastName"] as! String
                    
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
                    
                    var birthday: NSDate? = nil
                    if let userbirthday = formatter.date(from: value["birthday"]! as! String) {
                        birthday = userbirthday as NSDate?
                    }
                    
                    let gender = value["gender"] as! String
                    
                    let location = value["location"] as! String
                    
                    var level = 0
                    if let levelOriginal = value["level"] as? Int {
                        level = levelOriginal
                    }
                    
                    var points = 0
                    if let pointsOriginal = value["points"] as? Int {
                        points = pointsOriginal
                    }
                    
                    var lists = [String: String]()
                    if let listsOriginal = value["lists"] as? [String: String] {
                        lists = listsOriginal
                    }
                    
                    var buyedLists = [String: String]()
                    if let buyedListsOriginal = value["buyedLists"] as? [String: String] {
                        buyedLists = buyedListsOriginal
                    }
                    
                    user = User.init(id: id, name: name, userName: userName, email: email, firstName: firstname, lastName: lastname, gender: gender, birthday: birthday as Date?, location: location, level: level, points: points, lists: lists, buyedLists: buyedLists)
                    
                    completion(user)
                }
            } else {
                completion(nil)
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func getUsersWithEmail(email: String, completion: @escaping (_ user: UserToShareWith?) -> Void) {
        let emailCommas = email.replacingOccurrences(of: ".", with: ",")
        self.db.child("userMails").child(emailCommas).observeSingleEvent(of: .value, with: { (snapshot) in
            if let users = snapshot.value! as? [String: AnyObject] {
                for userFb in users {
                    if let user = userFb.1 as? String {
                        self.db.child("users/\(user)").observeSingleEvent(of: .value, with: { (snapshot2) in
                            let userToShare = UserToShareWith()
                            if let value2 = snapshot2.value as? [String: AnyObject] {
                                userToShare.firstName = value2["firstName"] as! String
                                userToShare.lastName = value2["lastName"] as! String
                                userToShare.email = value2["email"] as! String
                                userToShare.id = user
                                
                                completion(userToShare)
                            }
                        })
                    }
                }
        	} else {
        		completion(nil)
        	}
        })
    }
    
    // MARK: - ShoppingLists
    
    func addUserShoppingList(shoppingList: ShoppingList) -> String {
        let userId = self.defaults.string(forKey: "userId")!
        // Completes the shopping list entity
        let key = self.db.child("shoppingLists").childByAutoId().key
        shoppingList.id = key
        shoppingList.owner = userId
        let document = shoppingList.getFirebaseObject()
        
        // Add new shopping list
        let childUpdates = ["shoppingLists/\(key)": document]
        self.db.updateChildValues(childUpdates)
        
    	self.db.child("users").child(userId).child("lists").child(shoppingList.id).setValue(shoppingList.name)
        
        return key
    }
    
    func updateNameShoppingList(id: String, name: String) {
        let userId = self.defaults.string(forKey: "userId")!
        
        self.db.child("shoppingLists").child(id).child("name").setValue(name)
        self.db.child("users").child(userId).child("lists").child(id).setValue(name)
    }

    func deleteShoppingList(_ shoppingListId: String) {
        let userId = self.defaults.string(forKey: "userId")!
        
        
        //delete from the users who share the list
        self.getShoppingList(shoppingListId: shoppingListId, completion:{(shoppingList: ShoppingList?) in
            
            if let list = shoppingList {
                for user in list.sharedWith {
                    if let userId = user.1 as? String {
                        self.db.child("users").child(userId).child("lists").child(shoppingListId).removeValue()
                    }
                }
                
                if list.owner == userId {
                    // delete from the owner user
                    self.db.child("users").child(userId).child("lists").child(shoppingListId).removeValue()
                    
                    // delete products from shopping list
                    self.db.child("productsInShoppingList").child(shoppingListId).removeValue()
                    
                    // delete the shopping list
                    self.db.child("shoppingLists").child(shoppingListId).removeValue()
                }
            }
        })
    }

    func getUserShoppingLists() -> DatabaseQuery {
        let userId = self.defaults.string(forKey: "userId")!
        return self.db.child("users").child(userId).child("lists")
    }
    
    func getUserDefaultShoppingList(completion:@escaping (ShoppingList!) -> ()) {
        let userId = self.defaults.string(forKey: "userId")!
        
        self.db.child("users").child(userId).child("lists").queryLimited(toFirst: 1).observeSingleEvent(of: .value, with: { (snapshot) in
            if let postDict = snapshot.value as? [String : String] {
                
                var lists = [String: String]()
                
                lists = postDict
                
                let listId = lists.keys.first!
                
                self.getShoppingList(shoppingListId: listId, completion:{(shoppingList: ShoppingList?) in
                    if let list = shoppingList {
                        completion(list)
                    }
                })
            } else {
                
                let shoppingList = ShoppingList(id: "", name: "Lista de deseos", owner: userId)
                shoppingList.id = self.addUserShoppingList(shoppingList: shoppingList)
                
                completion(shoppingList)
            }
        })
    }
    
    func getShoppingList(shoppingListId: String, completion:@escaping (ShoppingList?) -> ()) {
        self.db.child("shoppingLists").child(shoppingListId).observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let shoppingList = snapshot.value! as? [String: AnyObject] {
                // Already have lists
                let list = ShoppingList(parameters: shoppingList)
                completion(list)
            } else {
                completion(nil)
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func shareShoppingList(shoppingListId: String, name: String, idUser: String) {
        self.db.child("shoppingLists").child(shoppingListId).child("sharedWith").child(idUser).setValue(idUser)
        
        self.db.child("users").child(idUser).child("lists").child(shoppingListId).setValue(name)
    }
    
    func deleteUserToShareInList(_ idUser: String, shoppingListId: String) {
        self.db.child("shoppingLists").child(shoppingListId).child("sharedWith").child(idUser).removeValue()
        
        self.db.child("users").child(idUser).child("lists").child(shoppingListId).removeValue()
    }
    
    func deleteStoreFromList(list: String) {
        self.db.child("shoppingLists").child(list).child("place").removeValue()
    }
    
    // MARK: - Friends
    func addFriend(friendId: String) {
        let userId = self.defaults.string(forKey: "userId")!
        self.db.child("users").child(userId).child("friends").child(friendId).setValue(friendId)
    }
    
    func getFriends(completion:@escaping ([Friend]?) -> ()) {
        var result = [Friend]()
        let userId = self.defaults.string(forKey: "userId")!
        self.db.child("users").child(userId).child("friends").observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let friends = snapshot.value! as? [String: AnyObject] {
                for friend in friends {
                	let friendId = friend.value
                    
        			self.db.child("users").child(friendId as! String).observeSingleEvent(of: .value, with: { (snapshot) in
                        if let params = snapshot.value! as? [String: AnyObject] {
                        	let friend = Friend(parameters: params)
                            result.append(friend)
                        } else {
                        	print("Friend not found")
                        }
                    	completion(result)
                	})
                }
            } else {
                completion([])
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    // MARK: Tickets
    func getUserTickets() -> DatabaseReference {
        let userId = self.defaults.string(forKey: "userId")!
        return self.db.child("users").child(userId).child("tickets")
    }
    
    func getProductsInTicket(_ ticketId: String) -> DatabaseReference {
        return self.db.child("ticketProducts").child(ticketId)
    }
    
    func addTicket(_ ticket: Ticket) -> String {
        let userId = self.defaults.string(forKey: "userId")!
        // Adds the ticket to the user
        let key = self.db.child("users").child(userId).child("tickets").childByAutoId().key
        let ticketSummary = TicketSummary(id: key, storeName: ticket.storeName, totalPrice: ticket.totalPrice!, ticketDate: ticket.ticketDate)
        
        var sharedWith = [String]()
        sharedWith.append(userId)
        
        // adds from the users who share the list
        self.getShoppingList(shoppingListId: ticket.shoppingList, completion:{(shoppingList: ShoppingList?) in
            if let list = shoppingList {
                for user in list.sharedWith {
                    if user.1["id"] != nil {
                    	if let userId = (user.1["id"])! as? String {
                        	self.db.child("users").child(userId).child("tickets").child(key).setValue(ticketSummary.getFirebaseObject())
                        	sharedWith.append(userId)
                    	}
                    }
                }
            }
        })
        
        // adds the ticket to the shopping list owner
        let childUpdates = ["users/\(userId)/tickets/\(key)": ticketSummary.getFirebaseObject()]
        self.db.updateChildValues(childUpdates)
        
        // Completes the ticket entity
        ticket.id = key
        ticket.owner = userId
        ticket.ticketDate = Date()
        ticket.sharedWith = sharedWith
        let document = ticket.getFirebaseObject()
        
        // Add new ticket
        let childUpdatesTickets = ["tickets/\(key)": document]
        self.db.updateChildValues(childUpdatesTickets)
        
        return key
    }
    
    
    
    func moveProductToTicket(_ shoppingList: String, product: Product, ticketId: String, storeId: String, storeName: String) {
        // Add ticket value to product
		product.ticketId = ticketId
        let document = product.getFirebaseObject()
        
    	// Create product in ticketproducts
        self.db.child("ticketProducts").child(ticketId).child(product.productId).setValue(document)
        
        // Delete product in shopping list
        self.db.child("productsInShoppingList").child(shoppingList).child(product.productId).removeValue()
        print ("Borrado shoppinglist:\(shoppingList) productId:\(product.productId)")
        
        let userId = self.defaults.string(forKey: "userId")!
        setAveragePerProduct(userId: userId, skuText: product.productSKU)
        
        // DX: Falta para los que comparten la lista
	}
    
    func deleteTicket(ticketId: String) {
        
        // delete ticket in users
        self.db.child("tickets").child(ticketId).observeSingleEvent(of: .value, with: { (snapshot) in

            if let postDict = snapshot.value as? [String : AnyObject] {
                if let items = postDict["sharedWith"] as? [String] {
                   	for item in items {
                       	self.db.child("users").child(item).child("tickets").child(ticketId).removeValue()
                   	}
               	}
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }

        // delete products of ticket
        self.db.child("ticketsProducts").child(ticketId).removeValue()
        
        // finally delete the ticket
        self.db.child("tickets").child(ticketId).removeValue()
    }
    
    // MARK: - Stores
    
    func getUserStores(location: CLLocation?, completion:@escaping (_ stores:[GooglePlaceResult]) -> Void) {
        var result: [GooglePlaceResult] = []
        let userId = self.defaults.string(forKey: "userId")!
        
        self.db.child("users").child(userId).child("favStores").observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let stores = snapshot.value! as? [String: AnyObject] {
                
                for store in stores {
                    
                    self.db.child("stores").child(store.value as! String).observeSingleEvent(of: .value, with: { (snapshot) in
                        
            			if let storeParameters = snapshot.value! as? [String: AnyObject] {
                            let storeComplete = GooglePlaceResult(parameters: storeParameters)
                            
                            if let location = location {
                            	storeComplete.distance = Int(storeComplete.getStoreLocation().distance(from: location))
                            } else {
                                storeComplete.distance = -1
                            }
                            
                            result.append(storeComplete)
                            
                            result = result.sorted(by: { $0.distance < $1.distance} )
                            
                            completion(result)
                        }
                    })
                }
            }
        })
    }
    
    func setStoreInUserFavs(store: GooglePlaceResult) {
        self.db.child("stores").child(store.id).setValue(store.getFirebaseObject())
        
        let userId = self.defaults.string(forKey: "userId")!
        self.db.child("users").child(userId).child("favStores").child(store.id).setValue(store.id)
    }
    
    func setStoreInShoppingList(shoppingListId: String, store: GooglePlaceResult) {
        self.db.child("shoppingLists").child(shoppingListId).child("place").setValue(store.getFirebaseObject())
    }
    
    func clearStoreInShoppingList(shoppingListId: String) {
        self.db.child("shoppingLists").child(shoppingListId).child("place").removeValue()
    }
    
    func deleteStore(storeId: String) {
        let userId = self.defaults.string(forKey: "userId")!
        self.db.child("users").child(userId).child("favStores").child(storeId).removeValue()
    }
    
    // MARK: - Username
    func getUserByUserName(userName: String, completion:@escaping (_ user: UserToShareWith?) -> Void) {
        let userNameLower = userName.lowercased()
        
        self.db.child("userNames").child(userNameLower).observeSingleEvent(of: .value, with: { (snapshot) in
            if let users = snapshot.value! as? [String: AnyObject] {
                for userFb in users {
                    if let user = userFb.1 as? String {
                        self.db.child("users/\(user)").observeSingleEvent(of: .value, with: { (snapshot2) in
                            let userToShare = UserToShareWith()
                            if let userShot = snapshot2.value! as? [String: AnyObject] {
                                userToShare.firstName = userShot["firstName"] as! String
                                userToShare.lastName = userShot["lastName"] as! String
                                userToShare.email = userShot["email"] as! String
                                userToShare.id = user
                            }
                            
                            completion(userToShare)
                        })
                    }
                }
            } else {
                completion(nil)
            }
        })
    }
    
    func setUserName(userName: String) {
        let userNameLower = userName.lowercased()
        
        let userId = self.defaults.string(forKey: "userId")!
        let value = ["userId":userId]
        self.db.child("userNames").child(userNameLower).setValue(value)
        
        self.db.child("users/\(userId)/userName").setValue(userNameLower)
        
    }
    
    func checkUserName(userName: String, completion:@escaping (_ found: Bool) -> Void) {
        
        let userNameLower = userName.lowercased()
        
        self.db.child("userNames").child(userNameLower).observeSingleEvent(of: .value, with: { (snapshot) in
            
            if snapshot.value! is [String: AnyObject] {

                completion(true)
            } else {
                completion(false)
            }
            
        }) { (error) in
            print(error.localizedDescription)
            completion(false)
        }
    }
    
    // MARK: - Points
    func addPoints(points: Int, reason: String) {
        var oldpoints = 0
        let userId = self.defaults.string(forKey: "userId")!
        let key = self.db.child("pointsHistory").child(userId).childByAutoId().key
        
        let point = HistoryPoint(id: key, reason: reason, date: Date(), points: points, userId: userId)
        
        self.db.child("pointsHistory").child(userId).child(key).setValue(point.getFirebaseObject())
        
        self.db.child("users").child(userId).observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let snapshotValue = snapshot.value as? [String: AnyObject] {
            	if let value = snapshotValue["points"] as? Int {
                	oldpoints = value
            	}
            }
            
            self.db.child("users").child(userId).child("points").setValue(oldpoints + points)
            
            self.updateLevel(points: oldpoints + points)
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func getPointHistory() -> DatabaseReference {
        let userId = self.defaults.string(forKey: "userId")!
        return self.db.child("pointsHistory").child(userId)
    }
    
    func updateLevel(points: Int) {
        let userId = self.defaults.string(forKey: "userId")!
        
        switch points {
        case 0..<200:
            self.db.child("users").child(userId).child("level").setValue(0)
        case 200..<450:
            self.db.child("users").child(userId).child("level").setValue(1)
        case 450..<1000:
            self.db.child("users").child(userId).child("level").setValue(2)
        case 1000..<1500:
            self.db.child("users").child(userId).child("level").setValue(3)
        case 1500..<2000:
            self.db.child("users").child(userId).child("level").setValue(4)
        case 2000..<10000:
            self.db.child("users").child(userId).child("level").setValue(5)
        default:
            self.db.child("users").child(userId).child("level").setValue(0)
        }
    }
    
    // MARK: - Levels
    func createLevels() {
//        let firebaseParameters: [String: AnyObject] = [
//            "level": 0,
//            "limitPoints": 50,
//            "nameMale": "Mandilón",
//            "nameFemale": "Chacha"
//            "storeId": self.storeId,
//            "storeName": self.storeName,
//            "ticketDate": formattedDate,
//            "storePosition":
//                ["lat":self.storeLatitude!,
//                    "long":self.storeLongitude!],
//            "totalPrice": self.totalPrice!]
//        
//    	self.db.child("gamelevels/0").setValue(<#T##value: AnyObject?##AnyObject?#>)
    }
}
