//
//  ButtonStackView.swift
//  Affirm
//
//  Created by Berkay Sebat on 8/3/20.
//  Copyright © 2020 Affirm. All rights reserved.
//
// Since this is supposed to be some sort of production ready project done in "3 hours". We have to have some reusable views. Therefore instead of just putting 2 buttons in the View Controller in the story board lets try and keep our View Controllers light and make a new reusable class for some button stackviews. Perfect.
//
//

import UIKit

// now any viewcontroller that adopts this protocol can use our buttons. 
protocol ButtonStackViewDelegate: AnyObject {
    func didTapButton(button: UIButton)
}

class ButtonStackView: UIStackView {
    
    weak var delegate: ButtonStackViewDelegate?
    
    private let prevButton : UIButton = {
        let button = UIButton()
        button.setTitle("Previous", for: .normal)
        button.setTitleColor(UIColor.red, for: .normal)
        button.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        
        return button
    }()
    
    private let nextButton : UIButton = {
        let button = UIButton()
        button.setTitle("Next", for: .normal)
        button.setTitleColor(UIColor.green, for: .normal)
        button.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        button.tag = 2
        
        return button
    }()
    
    private func configureButtons() {
        let one: CGFloat = 1
        addArrangedSubview(from: prevButton, diameterMultiplier: one)
        addArrangedSubview(from: nextButton, diameterMultiplier: one)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        distribution = .fillEqually
        alignment = .center
        axis = .horizontal
        configureButtons()
    }
    
    private func addArrangedSubview(from button: UIButton, diameterMultiplier: CGFloat) {
        let container = ButtonContainer()
        container.addSubview(button)
        button.anchorToSuperview()
        addArrangedSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        container.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: diameterMultiplier).isActive = true
        container.heightAnchor.constraint(equalTo: button.widthAnchor).isActive = true
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func handleTap(_ button: UIButton) {
        delegate?.didTapButton(button: button)
    }
    
}

private class ButtonContainer: UIView {
    
    override func draw(_ rect: CGRect) {
        applyShadow(radius: 0.2 * bounds.width, opacity: 0.05, offset: CGSize(width: 0, height: 0.15 * bounds.width))
    }
}

