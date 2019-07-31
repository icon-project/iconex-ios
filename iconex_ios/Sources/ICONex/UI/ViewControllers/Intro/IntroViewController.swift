//
//  IntroViewController.swift
//  iconex_ios
//
//  Created by a1ahn on 29/07/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import Alamofire

class IntroViewController: BaseViewController {
    @IBOutlet weak var iconImage: UIImageView!
    @IBOutlet weak var satellite: UIImageView!
    @IBOutlet weak var logoLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        iconImage.alpha = 0.0
        satellite.alpha = 0.0
        logoLabel.alpha = 0.0
    }
    
    override func refresh() {
        super.refresh()
        view.backgroundColor = .mint1
        iconImage.image = #imageLiteral(resourceName: "imgLogoIcon0256W")
        satellite.image = #imageLiteral(resourceName: "imgLogoIcon0170W")
        logoLabel.size12(text: "@2019 ICON Foundation", color: UIColor(255, 255, 255, 0.5))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        startAlpha()
    }
    
    func startAlpha() {
        UIView.animate(withDuration: 0.45, delay: 0.5, options: .curveLinear, animations: {
            self.iconImage.alpha = 1.0
            self.satellite.alpha = 1.0
            self.logoLabel.alpha = 1.0
        }, completion: { _ in
            self.startRotate()
        })
    }
    
    func startRotate() {
        UIView.animate(withDuration: 0.65, delay: 0.5, usingSpringWithDamping: 0.75, initialSpringVelocity: 0.0, options: .curveEaseIn, animations: {
            self.iconImage.transform = CGAffineTransform(rotationAngle: .pi)
            self.satellite.transform = CGAffineTransform(rotationAngle: -3.14159256)
        }, completion : { _ in
            self.startHide()
        })
    }
    
    func startHide() {
        UIView.animate(withDuration: 0.4, delay: 0.5, animations: {
            self.iconImage.alpha = 0.0
            self.satellite.alpha = 0.0
            self.logoLabel.alpha = 0.0
        }, completion: { _ in
            self.iconImage.transform = .identity
            self.satellite.transform = .identity
            if !UserDefaults.standard.bool(forKey: "permission") {
                let perm = UIStoryboard(name: "Intro", bundle: nil).instantiateViewController(withIdentifier: "PermissionView") as! PermissionViewController
                perm.action = {
                    
                }
                perm.pop()
            }
        })
    }
    
    func checkVersion(_ completion: (() -> Void)? = nil) {
        var tracker: Tracker {
            switch Config.host {
            case .main:
                return Tracker.main()
                
            case .testnet:
                return Tracker.dev()
                
            case .yeouido:
                return Tracker.local()
            }
        }
        let versionURL = URL(string: tracker.provider)!.appendingPathComponent("app/ios.json")
        let request = URLRequest(url: versionURL, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 30)
        Alamofire.request(request).responseJSON(queue: DispatchQueue.global(qos: .utility)) { (dataResponse) in
            
            DispatchQueue.main.async {
                switch dataResponse.result {
                case .success:
                    guard case let json as [String: Any] = dataResponse.result.value, let result = json["result"] as? String else {
                        #warning("retry 구현")
                        return
                    }
                    Log("Version: \(json)")
                    if result == "OK" {
                        let data = json["data"] as! [String: String]
                        app.all = data["all"]
                        app.necessary = data["necessary"]
                    }
                    self.retry()
                    
                case .failure(let error):
                    Log("Error \(error)")
                    if let comp = completion {
                        comp()
                        return
                    } else {
                        #warning("retry 구현")
                        return
                    }
                }
            }
        }
    }
    
    private func go() {
        Manager.exchange.getExchangeList()
        Manager.balance.getAllBalances()
        
        let list = Manager.wallet.walletList
        
    }
    
    private func retry() {
        if let version = app.necessary {
            let myVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
            
            if version > myVersion {
                let message = "Version.Message".localized
//                    Alert.Confirm(message: message, cancel: "Common.Cancel".localized, confirm: "Version.Update".localized, handler: {
//                        UIApplication.shared.open(URL(string: "itms-apps://itunes.apple.com/app/iconex-icon-wallet/id1368441529?mt=8")!, options: [:], completionHandler: { _ in
//                            exit(0)
//                        })
//                    }, {
//                        exit(0)
//                    }).show(self.window!.rootViewController!)
            } else {
                
                go()
                
            }
        } else {
            
        }
    }
    
}