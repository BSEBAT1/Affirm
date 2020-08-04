//
//  CustomImageView.swift
//  Affirm
//
//  Created by Berkay Sebat on 8/3/20.
//  Copyright © 2020 Affirm. All rights reserved.
//

import UIKit
import Foundation

// MARK: - Global Properties -
let imageCache = NSCache<AnyObject, AnyObject>()

class CustomImageView: UIImageView {
    
    private var imageUrlString: String?
    
    let activityIndicator = UIActivityIndicatorView()
    
    // MARK: - Load Image -
    func loadImageUsingCacheWithUrlString(urlString: String) {
        
        imageCache.totalCostLimit = 50_000_000
        
        // setup activityIndicator
        activityIndicator.color = .darkGray
        
        addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        imageUrlString = urlString
        
        guard let url = NSURL(string: urlString) else { return }
        
        image = nil
        activityIndicator.startAnimating()
        
        // retrieves image if already available in cache
        if let imageFromCache = imageCache.object(forKey: urlString as AnyObject) as? UIImage {
            
            self.image = imageFromCache
            activityIndicator.stopAnimating()
            return
        }
        
        // image is not available in cache.. so get it from url...
        URLSession.shared.dataTask(with: url as URL, completionHandler: {(data, response, error) in
            
            if error != nil {
                print(error as Any)
                DispatchQueue.main.async(execute: {
                    self.activityIndicator.stopAnimating()
                })
                return
            }
            
            DispatchQueue.main.async(execute: {
                
                if let unwrappedData = data, let imageToCache = UIImage(data: unwrappedData) {
                    
                    if self.imageUrlString == urlString {
                        self.image = imageToCache
                    }
                    
                    imageCache.setObject(imageToCache, forKey: url as AnyObject)
                }
                self.activityIndicator.stopAnimating()
            })
        }).resume()
    }
}

