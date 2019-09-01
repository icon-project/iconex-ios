//
//  MainViewModel.swift
//  iconex_ios
//
//  Created by sy.lee-1 on 20/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import BigInt
import ICONKit
import Web3swift

class MainViewModel {
    static let shared = MainViewModel()
    
    var currencyUnit: BehaviorSubject<BalanceUnit>
    var currencyPrice: BehaviorSubject<String>
    var totalICXBalance: BehaviorSubject<BigUInt>
    var totalBalance: PublishSubject<String>
    var reload: PublishSubject<Bool>
    
    var isBigCard: BehaviorSubject<Bool>
    
    var disposeBag = DisposeBag()
    
    init() {
        self.currencyUnit = BehaviorSubject<BalanceUnit>(value: .USD)
        
        // BTC, ETH, USD
        let exchangeUnit = try? self.currencyUnit.value().symbol
        
        self.currencyPrice = BehaviorSubject<String>(value: Manager.exchange.exchangeInfoList["icx\(exchangeUnit ?? "")"]?.price ?? "")
        // ICX Balance
        self.totalICXBalance = BehaviorSubject<BigUInt>(value: Manager.balance.getTotalBalance())
        
        self.reload = PublishSubject<Bool>()
        
        // exchanged price
        self.totalBalance = PublishSubject<String>()
        
        self.isBigCard = BehaviorSubject<Bool>(value: false)
        
        // reload
        
        Observable.combineLatest(self.reload, self.currencyPrice, self.totalICXBalance).flatMapLatest { (_, currencyPrice, totalBalance) -> Observable<String> in
            let price = BigUInt(currencyPrice) ?? 0
            let totalPrice: BigUInt = price*totalBalance
            return Observable.just(totalPrice.toString(decimal: 18, 4).currencySeparated())
        }.bind(to: self.totalBalance)
        .disposed(by: disposeBag)
    }
}

let mainViewModel = MainViewModel.shared