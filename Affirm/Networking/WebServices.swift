//
//  WebServices.swift
//  Affirm
//
//  Created by Berkay Sebat on 8/3/20.
//  Copyright © 2020 Affirm. All rights reserved.
//

import Foundation
import CoreLocation

class WebServices {
    
    // MARK: - Private Properties -
    
    private var session = URLSession.shared
    private var modelArray = [CardModel]()
    
    // MARK: - API Calls -
    
    func fetchYelpData(withLocation:CLLocation, withOffset:Int, completion: @escaping (_ data:[CardModel]?, _ failure:String?) -> ()) {
        
        let rawURLString = "https://api.yelp.com/v3/businesses/search?offset=\(withOffset)&latitude=\(withLocation.coordinate.latitude)&longitude=\(withLocation.coordinate.longitude)"
        
        guard let url = URL.init(string:rawURLString) else {return}
        
        var request = URLRequest.init(url: url)
        
        let headers = [
            "Authorization":"Bearer itoMaM6DJBtqD54BHSZQY9WdWR5xI_CnpZdxa3SG5i7N0M37VK1HklDDF4ifYh8SI-P2kI_mRj5KRSF4_FhTUAkEw322L8L8RY6bF1UB8jFx3TOR0-wW6Tk0KftNXXYx"
        ]
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.httpAdditionalHeaders = headers
        session = URLSession.init(configuration: sessionConfig)
        request.httpMethod = "GET"

       let task = session.dataTask(with: request) {[weak self] (data, response, error) in
         
        guard let strongSelf = self else { return }
        
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            completion(nil,"unable to connect to server")
            return
            
        }
        if let error = error {
            completion(nil,"error connecting to server:\(error.localizedDescription)")
            return
        }
        
        guard let data = data else {
            completion(nil,"error parsing json data")
            return
        }
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String:Any] {
                guard let jsonData = json["businesses"] as? [Any] else {
                    completion(nil,"error parsing json data")
                    return}
                for obj in jsonData {
                    // I should have used a codable here but I ran out of time.
                    if let dictonary = obj as? [String:Any] {
                        if let name = dictonary["name"] as? String, let rating = dictonary["rating"] as? Double,  let imageUrl = dictonary["image_url"] as? String {
                            strongSelf.modelArray.append(CardModel.init(name: name, rating: String(rating), imageUrl: imageUrl))
                        }
                    }
                }
                completion(strongSelf.modelArray,nil)
            } else {
                completion(nil,"error parsing json data")
            }
        } catch let error as NSError {
            print(error.localizedDescription)
            completion(nil,error.localizedDescription)
        }
            if let error = error {
                print(error.localizedDescription)
                completion(nil,"error connecting to server:\(error.localizedDescription)")
                return
            }
        }
        task.resume()
    }
}
