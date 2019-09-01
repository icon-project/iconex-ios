//
//  AddressBookViewController.swift
//  iconex_ios
//
//  Created by Seungyeon Lee on 2019/09/02.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import PanModal

class AddressBookTableViewCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
}

class MyWalletTableViewCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var symbolLabel: UILabel!
}

class AddressBookViewController: BaseViewController {
    @IBOutlet weak var dismissButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var rightButton: UIButton!
    
    @IBOutlet weak var addressBookButton: UIButton!
    @IBOutlet weak var myWalletButton: UIButton!
    
    @IBOutlet weak var addressBookLine: UIView!
    @IBOutlet weak var myWalletLine: UIView!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var footerRightButton: UIButton!
    
    var isEditMode: Bool = false
    var isICX: Bool = true
    
    var selected: Int = 0
    
    var myAddress: String = ""
    var addressBookList = [AddressBookModel]()
    var myWalletList = [BaseWalletConvertible]()
    
    var token: Token? = nil
    
    var selectedHandler: ((_ address: String) -> Void)?
    
    let messageLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: .max, height: 20))
        label.size14(text: "AddressBook.NoAddedAddress".localized, color: .gray77, align: .center)
        
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupBind()
        
        self.tableView.tableFooterView = UIView()
        
        addressBookList = try! DB.addressBookList(by: self.isICX ? "icx" : "eth")
        myWalletList = DB.loadMyWallets(address: self.myAddress, type: self.isICX ? "icx" : "eth")
        
        if addressBookList.isEmpty {
            self.tableView.backgroundView = messageLabel
            self.tableView.separatorStyle = .none
        }
    }
    
    private func setupUI() {
        titleLabel.size18(text: "AddressBook.Title".localized, color: .gray77, weight: .medium, align: .center)
        
        addressBookButton.setTitle("AddressBook.Button.AddressBook".localized, for: .normal)
        myWalletButton.setTitle("AddressBook.Button.MyWallet".localized, for: .normal)
        
        addressBookButton.isSelected = true

        addressBookButton.titleLabel?.size14(text: "AddressBook.Button.AddressBook".localized, color: .gray77, weight: .bold, align: .center)
        myWalletButton.titleLabel?.size14(text: "AddressBook.Button.MyWallet".localized, color: .gray77, align: .center)
        
        rightButton.setTitle("Common.Edit".localized, for: .normal)
        
        cancelButton.round02()
        footerRightButton.round02()
        
        cancelButton.setTitle("Common.Cancel".localized, for: .normal)
        footerRightButton.setTitle("AddressBook.AddAddress".localized, for: .normal)
        
        myWalletLine.isHidden = true
    }
    
    private func setupBind() {
        addressBookButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                self.rightButton.isHidden = false
                self.addressBookButton.titleLabel?.size14(text: "AddressBook.Button.AddressBook".localized, color: .gray77, weight: .bold, align: .center)
                self.myWalletButton.titleLabel?.size14(text: "AddressBook.Button.MyWallet".localized, color: .gray77, weight: .regular, align: .center)
                
                self.selected = 0
                self.footerView.isHidden = false
                self.addressBookLine.isHidden = false
                self.myWalletLine.isHidden = true
                self.tableView.reloadData()
                
                if self.addressBookList.isEmpty {
                    self.tableView.backgroundView = self.messageLabel
                    self.tableView.separatorStyle = .none
                } else {
                    self.tableView.backgroundView = nil
                    self.tableView.separatorStyle = .singleLine
                }
        }.disposed(by: disposeBag)
        
        myWalletButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                self.rightButton.isHidden = true
                self.addressBookButton.titleLabel?.size14(text: "AddressBook.Button.AddressBook".localized, color: .gray77, weight: .regular, align: .center)
                self.myWalletButton.titleLabel?.size14(text: "AddressBook.Button.MyWallet".localized, color: .gray77, weight: .bold, align: .center)
                
                self.selected = 1
                self.footerView.isHidden = true
                self.addressBookLine.isHidden = true
                self.myWalletLine.isHidden = false
                self.tableView.reloadData()
                
                if self.myWalletList.isEmpty {
                    self.tableView.backgroundView = self.messageLabel
                    self.tableView.separatorStyle = .none
                } else {
                    self.tableView.backgroundView = nil
                    self.tableView.separatorStyle = .singleLine
                }
            }.disposed(by: disposeBag)
        
        dismissButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                self.dismiss(animated: true, completion: nil)
        }.disposed(by: disposeBag)
        
        cancelButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                self.dismiss(animated: true, completion: nil)
        }.disposed(by: disposeBag)
        
        footerRightButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                if self.isEditMode {
                    
                } else {
                    // Add Address
                    Alert.addAddress(confirmAction: {
                        self.tableView.separatorStyle = .singleLine
                        self.tableView.backgroundView = nil
                        self.addressBookList = try! DB.addressBookList(by: self.isICX ? "icx" : "eth")
                        self.tableView.reloadData()
                    }).show()
                }
        }.disposed(by: disposeBag)
    }
}

extension AddressBookViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.selected == 0 {
            return addressBookList.count
        } else {
            return myWalletList.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if self.selected == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "addressBookCell") as! AddressBookTableViewCell
            
            let item = self.addressBookList[indexPath.row]
            cell.nameLabel.size14(text: item.name, color: .gray77, weight: .semibold)
            cell.addressLabel.size12(text: item.address, color: .gray77)
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "myWalletCell") as! MyWalletTableViewCell
            
            let item = self.myWalletList[indexPath.row]
            cell.nameLabel.size14(text: item.name, color: .gray77, weight: .semibold)
            
            if let token = self.token {
                cell.balanceLabel.size12(text: "TODO", color: .gray77, weight: .bold)
                cell.symbolLabel.size12(text: token.symbol, color: .gray77, weight: .bold)
            } else {
                cell.balanceLabel.size12(text: item.balance?.toString(decimal: 18) ?? "0", color: .gray77, weight: .bold)
                cell.symbolLabel.size12(text: self.isICX ? CoinType.icx.symbol : CoinType.eth.symbol, color: .gray77, weight: .bold)
            }
            
            return cell
        }
    }
}

extension AddressBookViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if self.selected == 0 {
            return 80
        } else {
            return 60
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        
        self.dismiss(animated: true) {
            if let handler = self.selectedHandler {
                if self.selected == 0 {
                    let address = self.addressBookList[indexPath.row].address
                    handler(address)
                } else {
                    let address = self.myWalletList[indexPath.row].address
                    handler(address)
                }
            }
        }
    }
}

extension AddressBookViewController: PanModalPresentable {
    var panScrollable: UIScrollView? {
        return nil
    }
    
    var showDragIndicator: Bool {
        return false
    }
    
    func shouldRespond(to panModalGestureRecognizer: UIPanGestureRecognizer) -> Bool {
        return false
    }
    
    var isHapticFeedbackEnabled: Bool {
        return false
    }
    
    var topOffset: CGFloat {
        return app.window!.safeAreaInsets.top
    }
    
    var backgroundAlpha: CGFloat {
        return 0.4
    }
    
    var cornerRadius: CGFloat {
        return 18.0
    }
}