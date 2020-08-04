//
//  ViewController.swift
//  Affirm
//
//  Created by Berkay Sebat on 8/3/20.
//  Copyright © 2020 Affirm. All rights reserved.
// This is the main ViewController. It is responsible for setting up and presenting card Views. I used a cocoapod called Shuffle because I do not have the time to make all the swipable views and animations that are required. I have used Shuffle in the past and I like it. With more time I would have moved more of the business logic out of here.

import UIKit
import Shuffle_iOS
import CoreLocation

class ViewController: UIViewController {
    
    // MARK: - Private Properties -
    private let cardStack = SwipeCardStack()
    private let buttons = ButtonStackView()
    private let locationManager = CLLocationManager()
    private var prevLocation = CLLocation()
    private let webservices = WebServices.init()
    private var cardData = [CardModel]()
    private let label = UILabel.init()
    private let searchBar = UISearchBar.init()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        layoutButtonStackView()
        addSearchBar()
        layoutCardStackView()
        cardStack.delegate = self
        cardStack.dataSource = self
        buttons.delegate = self
        searchBar.delegate = self
        checkLocationStatus()
        addWarningLabel()
    }
    // MARK: - Configuration -
    private func addWarningLabel() {
        view.addSubview(label)
        label.text = " We Need Location Authorization to Load Cards"
        label.anchor(top: view.safeAreaLayoutGuide.topAnchor,
                     left: view.safeAreaLayoutGuide.leftAnchor,
                     bottom: view.safeAreaLayoutGuide.bottomAnchor,
                     right: view.safeAreaLayoutGuide.rightAnchor)
    }
    
    private func addSearchBar() {
        view.addSubview(searchBar)
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        let views = ["searchBar": searchBar]
        let widthConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-[searchBar]-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: views)
        let heightConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-[searchBar(50)]", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: views)
        NSLayoutConstraint.activate(widthConstraints)
        NSLayoutConstraint.activate(heightConstraints)
    }
    
    private func layoutCardStackView() {
        view.addSubview(cardStack)
        cardStack.anchor(top: searchBar.bottomAnchor,
                         left: view.safeAreaLayoutGuide.leftAnchor,
                         bottom: buttons.topAnchor,
                         right: view.safeAreaLayoutGuide.rightAnchor)
    }
    
    private func layoutButtonStackView() {
        view.addSubview(buttons)
        buttons.anchor(left: view.safeAreaLayoutGuide.leftAnchor,
                       bottom: view.safeAreaLayoutGuide.bottomAnchor,
                       right: view.safeAreaLayoutGuide.rightAnchor,
                       paddingLeft: 24,
                       paddingBottom: 12,
                       paddingRight: 24)
    }
    
    private func checkLocationStatus() {
        if (CLLocationManager.locationServicesEnabled())
        {
            CLLocationManager.authorizationStatus()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
            locationManager.distanceFilter = 400
        } else {
            askForLocationPermissions()
        }
    }
    
    private func apiService(_ term: String = "restaurants") {
        var offset = cardData.count
        if term != webservices.term {
            offset = 0
        }
        webservices.fetchYelpData(withTerm: term, withLocation: prevLocation, withOffset:offset) {[weak self] (data, error) in
            guard let strongSelf = self else {return}
            if let error = error {
                strongSelf.hanldeErrors(error: error)
            } else {
                if let data = data {
                    if term != "restaurants"{
                        DispatchQueue.main.async {
                            for card in data {
                            strongSelf.cardData.insert(card, at: 0)
                            strongSelf.cardStack.insertCard(atIndex: 0, position: 0)
                            }
                        strongSelf.cardStack.reloadData()
                        }
                    } else {
                        let prevCount = strongSelf.cardData.count
                        let newCount = prevCount + data.count
                        DispatchQueue.main.async {
                        strongSelf.cardData.append(contentsOf: data)
                        strongSelf.cardStack.appendCards(atIndices:Array(prevCount..<newCount))
                        strongSelf.label.isHidden = true
                            
                        }
                    }
                }
            }
        }
        
    }
    
    // MARK: - Error Handling -
    private func askForLocationPermissions() {
        
        let alertController = UIAlertController(title: "Location Needed", message: "Please go to Settings and turn on the location permissions", preferredStyle: .alert)
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in })
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        alertController.addAction(cancelAction)
        alertController.addAction(settingsAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func hanldeErrors(error:String) {
        let alert = UIAlertController(title: "Alert", message: error, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

// MARK: - CardView Delegate Methods -
extension ViewController: SwipeCardStackDelegate, SwipeCardStackDataSource {
    
    func cardStack(_ cardStack: SwipeCardStack, cardForIndexAt index: Int) -> SwipeCard {
        let card = SwipeCard()
        if index < cardData.count {
            let contentView = CardContent.init(withImageURL:cardData[index].imageUrl)
            card.content = contentView
            let footer = CardFooterView.init(withTitle: cardData[index].name, subtitle: cardData[index].rating)
            card.footer = footer
        }
        
        return card
    }
    
    func cardStack(_ cardStack: SwipeCardStack, didSwipeCardAt index: Int, with direction: SwipeDirection) {
        
        if cardStack.numberOfRemainingCards() == 0 {
            apiService()
        }
    }
    
    func cardStack(_ cardStack: SwipeCardStack, didSelectCardAt index: Int) {
        searchBar.endEditing(true)
    }
    
    
    func numberOfCards(in cardStack: SwipeCardStack) -> Int {
        return cardData.count
    }
    
}

// MARK: - Location Manager Delegates -
extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let last = locations.last {
            if last.coordinate.latitude != prevLocation.coordinate.latitude, last.coordinate.longitude != prevLocation.coordinate.longitude {
                apiService()
                prevLocation = last
            }
        }
    }
}

// MARK: - Button Delegates -
extension ViewController: ButtonStackViewDelegate {
    
    func didTapButton(button: UIButton) {
        if button.tag == 2 {
            self.cardStack.swipe(.left, animated: true)
        } else {
            self.cardStack.undoLastSwipe(animated: true)
        }
    }
}

extension ViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let text = searchBar.text {
            apiService(text)
        }
    }
    
    
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
    }
    
}
