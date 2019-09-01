//
//  MainCollectionViewCell.swift
//  iconex_ios
//
//  Created by sy.lee-1 on 20/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import BigInt

class MainCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var cardView: UIView!
    
    @IBOutlet weak var nicknameLabel: UILabel!
    
    @IBOutlet weak var buttonStack: UIStackView!
    @IBOutlet weak var scanButton: UIButton!
    @IBOutlet weak var qrcodeButton: UIButton!
    @IBOutlet weak var infoButton: UIButton!
    
    @IBOutlet weak var tableview: UITableView!
    
    var handler: (() -> Void)?
    
    var info: BaseWalletConvertible? = nil {
        willSet {
            isWalletMode = true
        }
        didSet {
            tableview.reloadData()
        }
    }
    
    var symbol: String = ""
    var fullName: String = ""
    var coinTokens: [BaseWalletConvertible]? = nil {
        willSet {
            isWalletMode = false
        }
        didSet {
            tableview.reloadData()
        }
    }
    var contractAddress: String = ""
    
    var isWalletMode: Bool = true
    
    let colorList: [SymbolColor] = [.A, .B, .C, .D, .E, .F, .G, .H, .I, .J, .K, .L]
    
    var disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let nibName = UINib(nibName: "WalletTableViewCell", bundle: nil)
        self.tableview.register(nibName, forCellReuseIdentifier: "walletCell")
        
        cardView.corner(18)
        
        mainViewModel.isBigCard.subscribe(onNext: { (value) in
            self.tableview.isScrollEnabled = value
        }).disposed(by: disposeBag)
        
        mainViewModel.currencyUnit.subscribe { (_) in
            self.tableview.reloadData()
        }.disposed(by: disposeBag)
        
        scanButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                guard let wallet = self.info else { return }
                
                Alert.password(wallet: wallet, returnAction: { (_) in
                    let scanVC = UIStoryboard.init(name: "Camera", bundle: nil).instantiateInitialViewController() as! QRReaderViewController
                    app.topViewController()?.present(scanVC, animated: true, completion: nil)
                }).show()
                
            }.disposed(by: disposeBag)
        
        qrcodeButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                let qrVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "QRCode") as! MainQRCodeViewController
                qrVC.wallet = self.info
                qrVC.modalPresentationStyle = .overFullScreen
                qrVC.modalTransitionStyle = .flipHorizontal
                
                app.topViewController()?.present(qrVC, animated: true, completion: nil)

                
            }.disposed(by: disposeBag)
        
        infoButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                let manageVC = UIStoryboard(name: "ManageWallet", bundle: nil).instantiateViewController(withIdentifier: "Manage") as! ManageWalletViewController
                manageVC.walletInfo = self.info
                manageVC.modalPresentationStyle = .overFullScreen
                manageVC.modalTransitionStyle = .crossDissolve
                manageVC.handler = self.handler
                app.topViewController()?.present(manageVC, animated: true, completion: nil)

            }.disposed(by: disposeBag)
    }
    
}

extension MainCollectionViewCell: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            if isWalletMode {
                return self.info?.tokens?.count ?? 0
            } else {
                return self.coinTokens?.count ?? 0
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // cell
        let coinCell: CoinTableViewCell = {
            let cell = tableView.dequeueReusableCell(withIdentifier: "coinCell") as! CoinTableViewCell
            cell.corner(8)
            cell.border(0.5, .gray230)
            cell.basicView.backgroundColor = .gray252
//            cell.selectionStyle = .none
            return cell
        }()
        
        let tokenCell: TokenTableViewCell = {
            let cell = tableView.dequeueReusableCell(withIdentifier: "tokenCell") as! TokenTableViewCell
            cell.corner(8)
//            cell.selectionStyle = .none
            return cell
        }()
        
        let walletCell: WalletTableViewCell = {
            let cell = tableView.dequeueReusableCell(withIdentifier: "walletCell") as! WalletTableViewCell
            cell.corner(8)
//            cell.selectionStyle = .none
            return cell
        }()
        
        let currency = try! mainViewModel.currencyUnit.value()
        
        if indexPath.section == 0 {
            if isWalletMode {
                coinCell.unitLabel.size12(text: currency.symbol, color: .gray179, align: .right)
                
                if let icx = info as? ICXWallet {
                    let currencySymbol = "icx\(currency.symbol.lowercased())"
                    coinCell.logoImageView.image = #imageLiteral(resourceName: "imgLogoIconSel")
                    coinCell.symbolLabel.size16(text: CoinType.icx.symbol, color: .gray77, weight: .semibold)
                    coinCell.fullNameLabel.size12(text: CoinType.icx.fullName, color: .gray179, weight: .light)
                    
                    let balance = icx.balance?.toString(decimal: 18, 4)
                    coinCell.balanceLabel.size16(text: balance ?? "-", color: .gray77, weight: .bold, align: .right)
                    
                    
                    let price = Tool.calculatePrice(decimal: 18, currency: currencySymbol, balance: icx.balance ?? 0)
                    coinCell.unitBalanceLabel.size12(text: price, color: .gray179, align: .right)
                    
                } else if let eth = info as? ETHWallet {
                    let currencySymbol = "eth\(currency.symbol.lowercased())"
                    coinCell.logoImageView.image = #imageLiteral(resourceName: "imgLogoEthereumNor")
                    coinCell.symbolLabel.size16(text: CoinType.eth.symbol, color: .gray77, weight: .semibold)
                    coinCell.fullNameLabel.size12(text: CoinType.eth.fullName, color: .gray179, weight: .light)
                    
                    let balance = eth.balance?.toString(decimal: 18, 4)
                    coinCell.balanceLabel.size16(text: balance ?? "-", color: .gray77, weight: .bold, align: .right)
                    
                    let price = Tool.calculatePrice(decimal: 18, currency: currencySymbol, balance: eth.balance ?? 0)
                    coinCell.unitBalanceLabel.size12(text: price, color: .gray179, align: .right)
                }
                return coinCell
                
            } else { // total coin token info
                let currencySymbol = "\(symbol.lowercased())\(currency.symbol.lowercased())"
                switch symbol {
                case "icx":
                    coinCell.unitLabel.size12(text: currency.symbol, color: .gray179, align: .right)
                    
                    coinCell.logoImageView.image = #imageLiteral(resourceName: "imgLogoIconSel")
                    coinCell.symbolLabel.size16(text: CoinType.icx.symbol, color: .gray77, weight: .semibold)
                    coinCell.fullNameLabel.size12(text: CoinType.icx.fullName, color: .gray179, weight: .light)
                    
                    guard let list = self.coinTokens else { return coinCell }
                    
                    var totalBalance: BigUInt = 0
                    for i in list {
                        totalBalance += i.balance ?? 0
                    }
                    let balance = totalBalance.toString(decimal: 18, 4, false)
                    
                    coinCell.balanceLabel.size16(text: balance, color: .gray77, weight: .bold, align: .right)
                    
                    let price = Tool.calculatePrice(decimal: 18, currency: currencySymbol , balance: totalBalance)
                    coinCell.unitBalanceLabel.size12(text: price, color: .gray179, weight: .light)
                    
                    return coinCell
                    
                case "eth":
                    coinCell.unitLabel.size12(text: currency.symbol, color: .gray179, align: .right)
                    
                    coinCell.logoImageView.image = #imageLiteral(resourceName: "imgLogoEthereumNor")
                    coinCell.symbolLabel.size16(text: CoinType.eth.symbol, color: .gray77, weight: .semibold)
                    coinCell.fullNameLabel.size12(text: CoinType.eth.fullName, color: .gray179, weight: .light)
                    
                    guard let list = self.coinTokens else { return coinCell }
                    
                    var totalBalance: BigUInt = 0
                    for i in list {
                        totalBalance += i.balance ?? 0
                    }
                    
                    coinCell.balanceLabel.size16(text: String(totalBalance), color: .gray77, weight: .bold, align: .right)
                    
                    let price = Tool.calculatePrice(decimal: 18, currency: currencySymbol , balance: totalBalance)
                    coinCell.unitBalanceLabel.size12(text: price, color: .gray179, weight: .light)
                    
                    return coinCell
                    
                default:
                    tokenCell.corner(8)
                    tokenCell.border(0.5, .gray230)
                    tokenCell.contentView.backgroundColor = .gray252
                    
                    guard let list = self.coinTokens else { return tokenCell }
                    
                    var totalBalance: BigUInt = 0
                    
                    for i in list {
                        totalBalance += Manager.balance.getTokenBalance(address: i.address, contract: contractAddress)
                    }
                    
                    guard let nickName = symbol.first?.uppercased() else { return tokenCell }
                    tokenCell.symbolNicknameLabel.size16(text: nickName , color: .white, weight: .medium, align: .center)
                    tokenCell.symbolView.backgroundColor = colorList[indexPath.row%12].background // 임시
                    tokenCell.symbolLabel.size16(text: symbol, color: .gray77, weight: .semibold)
                    tokenCell.fullnameLabel.size12(text: fullName, color: .gray179, weight: .light)
                    
                    tokenCell.balanceLabel.size16(text: String(totalBalance) , color: .gray77, weight: .bold, align: .right)
                    
                    let decimal = DB.tokenListBy(symbol: symbol).first?.decimal ?? 0
                    let price = Tool.calculatePrice(decimal: decimal, currency: currencySymbol, balance: totalBalance)
                    tokenCell.unitBalanceLabel.size12(text: price, color: .gray179, align: .right)
                    
                    tokenCell.unitLabel.size12(text: currency.symbol, color: .gray179, align: .right)
                    return tokenCell
                }
            }
            
        } else {
            if isWalletMode { // token
                guard let token = info?.tokens?[indexPath.row] else { return tokenCell }
                
                let currencySymbol = "\(symbol.lowercased())\(currency.symbol.lowercased())"
                
                tokenCell.symbolNicknameLabel.size16(text: "\(token.name.first?.uppercased() ?? "")" , color: .white, weight: .medium, align: .center)
                tokenCell.symbolView.backgroundColor = colorList[indexPath.row%12].background
                tokenCell.symbolLabel.size16(text: token.symbol, color: .gray77, weight: .semibold)
                tokenCell.fullnameLabel.size12(text: token.name, color: .gray179, weight: .light)
                
//                let tokenBalance = Manager.balance.getTokenBalance(address: token.parent, contract: token.contract)
                let tokenBalance = Manager.icon.getIRCTokenBalance(tokenInfo: token) ?? 0
                tokenCell.balanceLabel.size16(text: tokenBalance.toString(decimal: token.decimal, 4).currencySeparated(), color: .gray77, weight: .bold, align: .right)
                let price = Tool.calculatePrice(decimal: token.decimal, currency: currencySymbol, balance: tokenBalance)
                tokenCell.unitBalanceLabel.size12(text: price, color: .gray179, weight: .light, align: .right)
                
                tokenCell.unitLabel.size12(text: currency.symbol, color: .gray179, weight: .light, align: .right)
                
                return tokenCell
                
            } else {
                guard let val = self.coinTokens?[indexPath.row] else { return walletCell }
                // icx eth 구분
                let walletTypeCount = DB.walletTypes().count
                
                if indexPath.row < walletTypeCount { // coin
                    let currenySymbol = "\(symbol.lowercased())\(currency.symbol.lowercased())"
                    walletCell.nicknameLabel.size16(text: val.name, color: .gray77, weight: .semibold)
                    walletCell.addressLabel.size12(text: val.address, color: .gray179, weight: .light)
                    walletCell.balanceLabel.size16(text: val.balance?.toString(decimal: 18, 4).currencySeparated() ?? "0", color: .gray77, weight: .bold, align: .right)
                    
                    let price = Tool.calculatePrice(decimal: 18, currency: currenySymbol, balance: val.balance ?? 0)
                    walletCell.currencyLabel.size12(text: price, color: .gray179, weight: .light, align: .right)
                    walletCell.currencyUnitLabel.size12(text: currency.symbol, color: .gray179, align: .right)
                    
                } else { // token
                    let currenySymbol = "\(symbol.lowercased())\(currency.symbol.lowercased())"
                    print("우왓")
                    print(DB.tokenListBy(symbol: symbol))
                    
                    guard let decimal = DB.tokenListBy(symbol: symbol).first?.decimal else { return walletCell }
                    
                    
                    walletCell.nicknameLabel.size16(text: val.name, color: .gray77, weight: .semibold)
                    walletCell.addressLabel.size12(text: val.address, color: .gray179, weight: .light)
//                    walletCell.balanceLabel.size16(text: val.balance?.toString(decimal: decimal, 4).currencySeparated() ?? "0", color: .gray77, weight: .bold, align: .right)
                    let tokenBalance = Manager.balance.getTokenBalance(address: val.address, contract: self.contractAddress)
                    print("ㅇㅣ게 맞나 아닌거 같다 \(tokenBalance)")
                    
                    let price = Tool.calculatePrice(decimal: decimal, currency: currenySymbol, balance: tokenBalance)
                    walletCell.currencyLabel.size12(text: price, color: .gray179, weight: .light, align: .right)
                    walletCell.currencyUnitLabel.size12(text: currency.symbol, color: .gray179, align: .right)
                }
                return walletCell
            }
        }
    }
}

extension MainCollectionViewCell: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 82
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableview.deselectRow(at: indexPath, animated: true)
        
        guard let wallet = self.info else { return }
        let detailVC = UIStoryboard.init(name: "Detail", bundle: nil).instantiateInitialViewController() as! DetailViewController
        detailVC.walletInfo = wallet
        
        if indexPath.section == 0 {
            guard isWalletMode else { return }
//            self.performSegue(withIdentifier: "coinSegue", sender: self)
            
            if let _ = wallet as? ICXWallet {
                detailViewModel.symbol.onNext(CoinType.icx.symbol)
                detailVC.detailType = .icx
            } else {
                detailViewModel.symbol.onNext(CoinType.eth.symbol)
                detailVC.detailType = .eth
            }
            detailViewModel.wallet.onNext(wallet)
            
        } else {
            if isWalletMode {
                guard let token = wallet.tokens?[indexPath.row] else { return }
                detailViewModel.wallet.onNext(wallet)
                detailViewModel.token.onNext(token)
                detailViewModel.symbol.onNext(token.symbol)
                detailVC.tokenInfo = token
                
                if let _ = wallet as? ICXWallet {
                    detailVC.detailType = .irc
                } else {
                    detailVC.detailType = .erc
                }
            } else {
                guard let selectedWallet = self.coinTokens?[indexPath.row] else { return }
                detailViewModel.wallet.onNext(selectedWallet)
                detailViewModel.symbol.onNext(symbol)
                
                if symbol != "" {
                    guard let tokenList = selectedWallet.tokens else { return }
                    
                    for token in tokenList {
                        if token.symbol == symbol {
                            detailVC.tokenInfo = token
                            detailViewModel.token.onNext(token)
                            break
                        }
                    }
                    if let _ = wallet as? ICXWallet {
                        detailVC.detailType = .irc
                    } else {
                        detailVC.detailType = .erc
                    }
                } else {
                    if let _ = wallet as? ICXWallet {
                        detailVC.detailType = .icx
                    } else {
                        detailVC.detailType = .eth
                    }
                }
            }
        }
        
        // swipe 안됨
//        if let navVC: UINavigationController = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController {
//            navVC.pushViewController(detailVC, animated: true)
//        } else {
//            print("불가해요?ㅠ")
//        }
        if let navVC: UINavigationController = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController {
            navVC.pushViewController(detailVC, animated: true)
        } else {
            print("불가해요?ㅠ")
        }
    }
    
//    override func preparefor
}