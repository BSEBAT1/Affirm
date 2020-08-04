//
//  ViewController.swift
//  Affirm
//
//  Created by Berkay Sebat on 8/3/20.
//  Copyright © 2020 Affirm. All rights reserved.
// This is the main ViewController. It is responsible for setting up and presenting card Views. I used a cocoapod called Shuffle because I do not have the time to make all the swipable views and animations that are required. I have used Shuffle in the past and I like it. 

import UIKit
import Shuffle_iOS
import CoreLocation

class ViewController: UIViewController {
    
    private let cardStack = SwipeCardStack()
    private let buttons = ButtonStackView()
    private let locationManager = CLLocationManager()
    private var prevLocation = CLLocation()
    private let webservices = WebServices.init()
    private var cardData = [CardModel]()
    private var swipeCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        layoutButtonStackView()
        layoutCardStackView()
        cardStack.delegate = self
        cardStack.dataSource = self
        buttons.delegate = self
        checkLocationStatus()
    }
    
    private func layoutCardStackView() {
      view.addSubview(cardStack)
      cardStack.anchor(top: view.safeAreaLayoutGuide.topAnchor,
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

extension ViewController: SwipeCardStackDelegate,SwipeCardStackDataSource {
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
    
    func numberOfCards(in cardStack: SwipeCardStack) -> Int {
        return cardData.count
    }
}

extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let last = locations.last {
            if last.coordinate.latitude != prevLocation.coordinate.latitude, last.coordinate.longitude != prevLocation.coordinate.longitude {
                webservices.fetchYelpData(withLocation: last, withOffset: 0) {[weak self] (data, error) in
                    guard let strongSelf = self else { return }
                    
                    if let error = error {
                        strongSelf.hanldeErrors(error: error)
                    } else if let data = data {
                        DispatchQueue.main.async {
                            strongSelf.cardData.append(contentsOf: data)
                            strongSelf.cardStack.appendCards(atIndices:Array(0..<data.count))
                        }
                    }
                }
                prevLocation = last
            }
        }
    }
}

extension ViewController: ButtonStackViewDelegate {
    
    func didTapButton(button: UIButton) {
        if button.tag == 2 {
            cardStack.swipe(.left, animated: true)
            swipeCount += 1
            if swipeCount % 10 == 0 {
                webservices.fetchYelpData(withLocation: prevLocation, withOffset:cardData.count) { (data, error) in
                    if let error = error {
                        self.hanldeErrors(error: error)
                    } else {
                        if let data = data {
                        DispatchQueue.main.async {
                             let prevCount = self.cardData.count
                             let newCount = prevCount + data.count
                            self.cardData.append(contentsOf: data)
                            for cards in self.cardData {
                                print(cards.name)
                            }
                            self.cardStack.appendCards(atIndices:Array(prevCount..<newCount))
                            }
                        }
                    }
                }
            }
        } else {
            cardStack.undoLastSwipe(animated: true)
            if swipeCount > 0 {
                swipeCount -= 1
            }
        }
    }
}