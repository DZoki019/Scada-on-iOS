//
//  MainViewController.swift
//  PLC HMI
//
//  Created by Djordje Jovic on 10/5/17.
//  Copyright © 2017 Encoded Street. All rights reserved.
//

import UIKit
import PureLayout

class MainViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, AddressTableViewCellDelegate {
    
    //// UI
    var switchButton = UISwitch()
    var lightImageView = UIImageView()
    let tableView = UITableView()
    
    //// Cell reuse identifiers
    let kInputCellReuseIdentifier = "kInputCellReuseIdentifier"
    let kOutputCellReuseIdentifier = "kOutputCellReuseIdentifier"
    
    //// Data
    var plcAddress = "192.168.0.1"
    var inputAddress = "%M0.1"
    var outputAddress = "%A0.1"
    
    ////
    let client = S7Client()
    var timer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        uiInit()
        clientInit()
    }
    
    func uiInit() -> Void {
        self.view.backgroundColor = .white
        
        self.navigationController?.navigationBar.isTranslucent = false
        
        self.lightImageView = UIImageView()
        self.view.addSubview(self.lightImageView)
        self.lightImageView.autoPinEdge(toSuperviewEdge: .right, withInset: 100)
        self.lightImageView.autoPinEdge(toSuperviewEdge: .top, withInset: 20)
        self.lightImageView.autoSetDimensions(to: CGSize.init(width: 100, height: 100))
        self.lightImageView.contentMode = .scaleAspectFit
        self.lightImageView.image = UIImage.init(named: "light_off")
        
        self.switchButton = UISwitch()
        self.view.addSubview(self.switchButton)
        self.switchButton.autoPinEdge(toSuperviewEdge: .left, withInset: 100)
        self.switchButton.autoAlignAxis(.horizontal, toSameAxisOf: self.lightImageView)
        self.switchButton.addTarget(self, action: #selector(switchButtonChangedState), for: .valueChanged)
        self.switchButtonChangedState(switchButton: self.switchButton)
        
        self.view.addSubview(self.tableView)
        self.tableView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
        self.tableView.autoPinEdge(.top, to: .bottom, of: self.lightImageView, withOffset:20)
        self.tableView.register(AddressTableViewCell.self, forCellReuseIdentifier: kInputCellReuseIdentifier)
        self.tableView.register(AddressTableViewCell.self, forCellReuseIdentifier: kOutputCellReuseIdentifier)
        self.tableView.allowsSelection = false
        self.tableView.delegate = self
        self.tableView.dataSource = self
    }
    
    func clientInit() -> Void {
        self.client.connect(plcAddress, rack: 0, slot: 1) {
            NSLog("connect: %x", $0)
            
            if #available(iOS 10.0, *) {
                
                DispatchQueue.main.async {
                    self.timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { (timer) in
                        self.checkBool()
                    }
                    self.timer.fire()
                }
            } else {
                //// Fallback on earlier versions
            }
        }
    }
    
    func checkBool() -> Void
    {
        _ = self.client.read(outputAddress, defaultValue: true) { (bit, value) in
            if bit {
                DispatchQueue.main.async {
                    self.lightImageView.image = UIImage.init(named: "light_on")
                }
                
            } else {
                DispatchQueue.main.async {
                    self.lightImageView.image = UIImage.init(named: "light_off")
                }
            }
        }
    }
    
    func switchButtonChangedState(switchButton : UISwitch) -> Void {
        _ = self.client.write(inputAddress, value: switchButton.isOn, completion: nil)
    }
    
    // MARK: - Table View delegates
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: kInputCellReuseIdentifier) as! AddressTableViewCell
            cell.componentTextLabel.text = "Input Address"
            cell.addressTextField.text = self.inputAddress
            cell.tag = indexPath.row
            cell.delegate = self
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: kOutputCellReuseIdentifier) as! AddressTableViewCell
            cell.componentTextLabel.text = "Output Address"
            cell.addressTextField.text = self.outputAddress
            cell.tag = indexPath.row
            cell.delegate = self
            return cell
        default:
            let kCellReuseIdentifier = "kCellReuseIdentifier"
            var cell = tableView.dequeueReusableCell(withIdentifier: kCellReuseIdentifier)
            if (cell == nil) {
                cell = UITableViewCell.init(style: .default, reuseIdentifier: kCellReuseIdentifier)
            }
            return cell!
        }
        
    }
    
    // MARK: - AddressTableViewCellDelegate
    func doneButtonTapped(_ cell : AddressTableViewCell) {
        switch cell.tag {
        case 0:
            self.inputAddress = cell.addressTextField.text!
        case 1:
            self.outputAddress = cell.addressTextField.text!
        default:
            print("Unexpected case.")
        }
    }
}
