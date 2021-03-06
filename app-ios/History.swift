//
//  History.swift
//  argent-ios
//
//  Created by Sinan Ulkuatam on 4/22/16.
//  Copyright © 2016 Sinan Ulkuatam. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire

class History {

    let id: String
    let amount: String
    let created: String
    let currency: String
    let type: String
    
    required init(id: String, amount: String, created: String, currency: String, type: String) {
        self.id = id
        self.amount = amount
        self.created = created
        self.currency = currency
        self.type = type
    }

    class func getAccountHistory(limit: String, starting_after: String, completionHandler: ([History]?, NSError?) -> Void) {
        // request to api to get data as json, put in list and table
        
        // check for token, get profile id based on token and make the request
        if(userAccessToken != nil) {
            User.getProfile({ (user, error) in
                if error != nil {
                    print(error)
                }
                
                let parameters : [String : AnyObject] = [:]
                
                let headers = [
                    "Authorization": "Bearer " + (userAccessToken as! String),
                    "Content-Type": "application/x-www-form-urlencoded"
                ]
                
                let limit = limit
                let starting_after = starting_after
                let user_id = (user?.id)
                
                var endpoint = API_URL + "/stripe/" + user_id! + "/transactions"
                if starting_after != "" {
                    endpoint = API_URL + "/stripe/" + user_id! + "/transactions?limit=" + limit + "&starting_after=" + starting_after
                } else {
                    endpoint = API_URL + "/stripe/" + user_id! + "/transactions?limit=" + limit
                }
                
                Alamofire.request(.GET, endpoint, parameters: parameters, encoding: .URL, headers: headers)
                    .validate().responseJSON { response in
                        switch response.result {
                        case .Success:
                            if let value = response.result.value {
                                let data = JSON(value)
                                var historyItemsArray = [History]()
                                let accountHistories = data["transactions"]["data"].arrayValue
                                for history in accountHistories {
                                    let id = history["id"].stringValue
                                    let amount = history["amount"].stringValue
                                    let created = history["created"].stringValue
                                    let currency = history["currency"].stringValue
                                    let type = history["type"].stringValue
                                    let item = History(id: id, amount: amount, created: created, currency: currency, type: type)
                                    historyItemsArray.append(item)
                                }
                                completionHandler(historyItemsArray, response.result.error)
                            }
                        case .Failure(let error):
                            print(error)
                        }
                }
            })
        }
    }
    
    class func getHistoryArrays(completionHandler: (Array<AnyObject>?, Array<AnyObject>?, Array<AnyObject>?, Array<AnyObject>?, Array<AnyObject>?, Array<AnyObject>?, Array<AnyObject>?, NSError?) -> Void) {
        // request to api to get data as json, put in list and table
        
        // check for token, get profile id based on token and make the request
        if(userAccessToken != nil) {
            User.getProfile({ (user, error) in
                if error != nil {
                    print(error)
                }
                
                let parameters : [String : AnyObject] = [:]
                
                let headers = [
                    "Authorization": "Bearer " + (userAccessToken as! String),
                    "Content-Type": "application/x-www-form-urlencoded"
                ]
                
                let limit = "1000"
                let user_id = (user?.id)
                
                let endpoint = API_URL + "/stripe/" + user_id! + "/history?limit=" + limit
                
                Alamofire.request(.GET, endpoint, parameters: parameters, encoding: .URL, headers: headers)
                    .responseJSON { response in
                        switch response.result {
                        case .Success:
                            if let value = response.result.value {
                                let data = JSON(value)
                                let historyOneDay = data["history"]["1D"].arrayObject
                                let historyTwoWeeks = data["history"]["2W"].arrayObject
                                let historyOneMonth = data["history"]["1M"].arrayObject
                                let historyThreeMonths = data["history"]["3M"].arrayObject
                                let historySixMonths = data["history"]["6M"].arrayObject
                                let historyOneYear = data["history"]["1Y"].arrayObject
                                let historySixYears = data["history"]["5Y"].arrayObject

                                completionHandler(historyOneDay, historyTwoWeeks, historyOneMonth, historyThreeMonths, historySixMonths, historyOneYear, historySixYears, response.result.error)
                            }
                        case .Failure(let error):
                            print(error)
                        }
                }
            })
        }
    }
}