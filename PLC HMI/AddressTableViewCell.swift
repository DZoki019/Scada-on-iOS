//
//  AddressTableViewCell.swift
//  PLC HMI
//
//  Created by Djordje Jovic on 10/5/17.
//  Copyright © 2017 Encoded Street. All rights reserved.
//

import UIKit
import PureLayout

protocol AddressTableViewCellDelegate {
    func doneButtonTapped(_ : AddressTableViewCell) -> Void
}

class AddressTableViewCell: UITableViewCell {

    public let componentTextLabel = UILabel()
    public let addressTextField = UITextField()
    var delegate : AddressTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.uiInit()
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.uiInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func uiInit() -> Void {
        self.contentView.addSubview(self.componentTextLabel)
        self.componentTextLabel.autoPinEdge(toSuperviewEdge: .left, withInset: 30)
        self.componentTextLabel.autoSetDimension(.width, toSize: 150)
        self.componentTextLabel.autoAlignAxis(toSuperviewAxis: .horizontal)
        
        self.contentView.addSubview(self.addressTextField)
        self.addressTextField.autoPinEdge(.left, to: .right, of: self.componentTextLabel, withOffset: 30)
        self.addressTextField.autoPinEdge(toSuperviewEdge: .right, withInset: 30)
        self.addressTextField.autoAlignAxis(toSuperviewAxis: .horizontal)
        self.addressTextField.textAlignment = .right
        
        self.addDoneButtonOnKeyboard()
        
//        self.addressTextField.textAlignment = .left
//        self.addressTextField.backgroundColor = .blue
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func addDoneButtonOnKeyboard() -> Void {
        let toolBar = UIToolbar()
        
//        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        toolBar.autoresizingMask = .flexibleHeight
        
        
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(doneButtonTapped))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.plain, target: self, action: #selector(cancelButtonTapped))
        
        toolBar.setItems([ cancelButton,spaceButton, doneButton], animated: false)
        
        self.addressTextField.inputAccessoryView = toolBar
    }
    
    func cancelButtonTapped() -> Void {
        self.endEditing(true)
    }
    
    func doneButtonTapped() -> Void {
        self.delegate?.doneButtonTapped(self)
        self.endEditing(true)
    }
}
