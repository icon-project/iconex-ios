//
//  MainViewController.swift
//  iconex_ios
//
//  Created by a1ahn on 02/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class MainViewController: BaseViewController {
    @IBOutlet weak var testButton: UIButton!
    @IBOutlet weak var navBar: IXNavigationView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        
        testButton.rx.tap.subscribe(onNext: {
            let main = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MainView")
            self.navigationController?.pushViewController(main, animated: true)
        }).disposed(by: disposeBag)
    }
    
    override func refresh() {
        super.refresh()
        
        navBar.setTitle("타이틀")
        
    }
}