//
//  SearchClient.swift
//  ApiAIDemoWatchOSSwift
//
//  Created by Dx on 09/06/16.
//  Copyright © 2016 moak. All rights reserved.
//

import Foundation
import Alamofire

class SearchClient {
    
    // var sessionManager : Alamofire.SessionManager?
    
    // let url = "https://moaksearch.search.windows.net/indexes/skuindex/docs/index?api-version=2016-09-01"
    
    func retrieveProductsWithName(_ name: String, completion: @escaping (_ result:[SearchProduct], _ error: String?) -> Void)  {
        
        let queue = DispatchQueue(label: "searchClient", attributes: [.concurrent])
        
        var results: [SearchProduct] = []
        
        let headers = ["api-key": "20BF8E09583ED7F07A9846FAF42AE029",
                       "Content-Type": "application/json"]
        
        let getUrl = "https://moaksearch.search.windows.net/indexes/sincodigo/docs?api-version=2015-02-28&$top=10&search=descripcion=\(name)"
        
        Alamofire.request(getUrl, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON(
            queue: queue,
            options: .allowFragments,
            completionHandler: { response in
                
              	if response.result.value != nil {
                    if let values = response.result.value! as? [String: AnyObject] {
                        if let array = values["value"]! as? [AnyObject] {
                    		for element in array {
                        		let product = SearchProduct()
	                        	product.nombre = element["descripcion"] as! String
	                        	//product.precioEstimado = (element["precioestimado"] as! NSString).floatValue
	                        	product.sku = element["sku"] as! String
	                        	product.categorias = [element["categoria"] as! String]
	                        	results.append(product)
    	                	}
        	            	completion(results, "")
                        } else {
                            completion(results, "Search failed")
                        }
                	} else {
                    	completion(results, "Search failed")
                	}
        		} else {
                	completion(results, "Search failed")
                }
        }
        )
    }
    
    func retrieveDescription(_ sku: String, completion: @escaping (_ result:String?, _ error: String?) -> Void)  {
        
//        let start = sku.startIndex
//        let end = sku.index(sku.endIndex, offsetBy:-1)
//        let range = start ..< end
//        let otherSku = sku.substring(with:range)
//        let skusearch = "\(sku)|0\(otherSku)"
        let queue = DispatchQueue(label: "searchClient", attributes: [.concurrent])
        
        let headers = ["api-key": "20BF8E09583ED7F07A9846FAF42AE029",
                       "Content-Type": "application/json"]
        
        let getUrl = "https://moaksearch.search.windows.net/indexes/mipitoconunafloresota/docs?api-version=2016-09-01&search=sku=\(createSkuToSearch(sku:sku))"
        
        let urlwithPercentEscapes = getUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        
        Alamofire.request(urlwithPercentEscapes!, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON(
            queue: queue,
            options: .allowFragments,
            completionHandler: { response in
                
                if response.result.value != nil {
                    if let values = response.result.value! as? [String: AnyObject] {
                        if values["values"] != nil {
                        	if let array = values["value"]! as? [AnyObject] {
                            	if array.count < 1 {
                                	completion(nil, "Not found")
                            	} else {
                                	if let nombre = array[0]["nombre"] as? String {
                                		completion(nombre, nil)
                                	}
                            	}
                        	} else {
                            	completion(nil, "Search failed")
                        	}
                        } else {
                            completion(nil, "Service failed")
                        }
                    } else {
                        completion(nil, "Search failed")
                    }
                } else {
                    completion(nil, "Search failed")
                }
            }
        )
    }
    
    func retrieveDescription2(_ sku: String, completion: @escaping (_ result:String?, _ error: String?) -> Void)  {
        
        let queue = DispatchQueue(label: "searchClient", attributes: [.concurrent])
        
        let headers = ["api-key": "B0F2F9999878F2D8498203B7ACAD1EF3",
                       "Content-Type": "application/json"]
        
        let getUrl = "https://moak.search.windows.net/indexes/mipitoconunaflor2/docs?api-version=2016-09-01&search=sku=\(createSkuToSearch(sku:sku))"
        
        let urlwithPercentEscapes = getUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        
        Alamofire.request(urlwithPercentEscapes!, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON(
            queue: queue,
            options: .allowFragments,
            completionHandler: { response in
                
                if response.result.value != nil {
                    if let values = response.result.value! as? [String: AnyObject] {
                        if values["values"] != nil {
                        	if let array = values["value"]! as? [AnyObject] {
                            	if array.count < 1 {
                                	completion(nil, "Not found")
                            	} else {
                                	if let nombre = array[0]["nombre"] as? String {
                                    	completion(nombre, nil)
                                	}
                            	}
                        	} else {
                            	completion(nil, "Search failed")
                        	}
                        } else {
                            completion(nil, "Service failed")
                        }
                    } else {
                        completion(nil, "Search failed")
                    }
                } else {
                    completion(nil, "Search failed")
                }
        }
        )
    }
    
    func retrieveDescription3(_ sku: String, completion: @escaping (_ result:String?, _ error: String?) -> Void)  {
        
        let queue = DispatchQueue(label: "searchClient", attributes: [.concurrent])
        
        let headers = ["api-key": "119E9FBC8C1077DFAE7FC108452D9328",
                       "Content-Type": "application/json"]
        
        let getUrl = "https://moaksku.search.windows.net/indexes/mipitoconunaflorfrancesa/docs?api-version=2016-09-01&search=sku=\(createSkuToSearch(sku:sku))"
        
        let urlwithPercentEscapes = getUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        
        Alamofire.request(urlwithPercentEscapes!, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON(
            queue: queue,
            options: .allowFragments,
            completionHandler: { response in
                
                if response.result.value != nil {
                    if let values = response.result.value! as? [String: AnyObject] {
                        if values["values"] != nil {
                        	if let array = values["value"]! as? [AnyObject] {
                            	if array.count < 1 {
                                	completion(nil, "Not found")
                            	} else {
                                	if let nombre = array[0]["nombre"] as? String {
                                    	completion(nombre, nil)
                                	}
                            	}
                        	} else {
                            	completion(nil, "Search failed")
                        	}
                        } else {
                            completion(nil, "Service failed")
                        }
                    } else {
                        completion(nil, "Search failed")
                    }
                } else {
                    completion(nil, "Search failed")
                }
        }
        )
    }
    
    func createSkuToSearch(sku: String) -> String {
        let start = sku.startIndex
        let end = sku.index(sku.endIndex, offsetBy:-1)
        let range = start ..< end
        let otherSku = sku.substring(with:range)
        let result = otherSku.leftPadding(toLength:14, withPad: "0")
        
        return result
    }
    
    func retrieveDescriptionNoSku(_ sku: String, completion: @escaping (_ result:String?, _ error: String?) -> Void)  {
        
        //let start = sku.startIndex
        //let end = sku.index(sku.endIndex, offsetBy:-1)
        //let range = start ..< end
        //let otherSku = sku.substring(with:range)
        //let skusearch = "\(sku)|0\(otherSku)"
        let queue = DispatchQueue(label: "searchClient", attributes: [.concurrent])
        
        let headers = ["api-key": "20BF8E09583ED7F07A9846FAF42AE029",
                       "Content-Type": "application/json"]
        
        let getUrl = "https://moaksearch.search.windows.net/indexes/sincodigo/docs?api-version=2015-02-28&search=sku=\(sku)"
        
        let urlwithPercentEscapes = getUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        
        Alamofire.request(urlwithPercentEscapes!, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON(
            queue: queue,
            options: .allowFragments,
            completionHandler: { response in
                
                if response.result.value != nil {
                    if let values = response.result.value! as? [String: AnyObject] {
                        if values["values"] != nil {
                        	if let array = values["value"]! as? [AnyObject] {
                            	if array.count < 1 {
                                	completion(nil, "Not found")
                            	} else {
                                	if let nombre = array[0]["nombre"] as? String {
                                    	completion(nombre, nil)
                                	}
                            	}
                        	} else {
                            	completion(nil, "Search failed")
                        	}
                        } else {
                            completion(nil, "Service failed")
                        }
                    } else {
                        completion(nil, "Search failed")
                    }
                } else {
                    completion(nil, "Search failed")
                }
        }
        )
    }
    
    func findDescriptionSKUAndMoakSKUs(_ sku: String, completion: @escaping (_ result:String?) -> Void) {
        self.retrieveDescription(sku) { (result: String?, error: String?) in
            if let result = result {
                completion(result)
            } else {
                self.retrieveDescription2(sku) { (result: String?, error: String?) in
                    if let result = result {
                        completion(result)
                    } else {
                        self.retrieveDescription3(sku) { (result: String?, error: String?) in
                            if let result = result {
                                completion(result)
                            } else {
                        		self.retrieveDescriptionNoSku(sku) { (result: String?, error: String?) in
                            		if let result = result {
                                		completion(result)
                            		} else {
                                		completion(nil)
                            		}
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

