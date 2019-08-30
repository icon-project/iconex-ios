//
//  PRepsViewController.swift
//  iconex_ios
//
//  Created by a1ahn on 23/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import PanModal

class PRepsViewController: BaseViewController, Floatable {
    @IBOutlet weak var firstItem: UIButton!
    @IBOutlet weak var secondItem: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    var delegate: VoteMainDelegate!
    
    var floater: Floater = {
        return Floater(type: .search)
    }()
    
    private var refreshControl: UIRefreshControl? = UIRefreshControl()
    private var preps: PRepListResponse?
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        
        firstItem.setTitle("My Votes", for: .normal)
        firstItem.setTitleColor(.gray77, for: .normal)
        firstItem.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        secondItem.size14(text: "P-Reps", color: .gray77, weight: .bold, align: .center)
        
        firstItem.rx.tap.subscribe(onNext: { [weak self] in
            self?.delegate.headerSelected(index: 0)
        }).disposed(by: disposeBag)
        
        tableView.tableFooterView = UIView()
        tableView.delegate = self
        tableView.dataSource = self
        
        floater.button.rx.tap.subscribe(onNext: { [unowned self] in
            let search = UIStoryboard(name: "Vote", bundle: nil).instantiateViewController(withIdentifier: "PRepSearchView") as! PRepSearchViewController
            search.delegate = self
            search.pop(self)
        }).disposed(by: disposeBag)
    }
    
    override func refresh() {
        super.refresh()
        
        loadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.view.bringSubviewToFront(floater.contentView)
        attach()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        detach()
    }
}

extension PRepsViewController {
    func loadData() {
        guard self.refreshControl != nil else { return }
        
        tableView.refreshControl = self.refreshControl
        self.refreshControl?.beginRefreshing()
        DispatchQueue.global().async {
            guard let preps = Manager.icon.getPreps(from: self.delegate.wallet, start: nil, end: nil) else {
                DispatchQueue.main.async {
                    self.refreshControl?.endRefreshing()
                    self.tableView.refreshControl = nil
                    self.refreshControl = nil
                }
                return
            }
            self.preps = preps
            DispatchQueue.main.async {
                self.refreshControl?.endRefreshing()
                self.tableView.refreshControl = nil
                self.refreshControl = nil
                self.tableView.reloadData()
            }
        }
        
    }
}

extension PRepsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let list = preps?.preps {
            return list.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PRepViewCell", for: indexPath) as! PRepViewCell
        
        let prep = preps!.preps[indexPath.row]
        cell.prepNameLabel.size12(text: prep.name, color: .gray77, weight: .semibold, align: .left)
        cell.totalVoteValue.size12(text: prep.delegated.toString(decimal: 18, 4, false), color: .gray77, weight: .semibold, align: .right)
        cell.active = true
        
        return cell
    }
}

extension PRepsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 36
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionHeader = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 36))
        sectionHeader.backgroundColor = .gray250
        let orderButton = UIButton(type: .custom)
        orderButton.setTitle("Rank ↓ / Name", for: .normal)
        orderButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .light)
        orderButton.setTitleColor(.gray77, for: .normal)
        orderButton.translatesAutoresizingMaskIntoConstraints = false
        sectionHeader.addSubview(orderButton)
        orderButton.leadingAnchor.constraint(equalTo: sectionHeader.leadingAnchor, constant: 20).isActive = true
        orderButton.centerYAnchor.constraint(equalTo: sectionHeader.centerYAnchor, constant: 0).isActive = true
        
        let resetButton = UIButton(type: .custom)
        resetButton.setTitle("Total Votes", for: .normal)
        resetButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .light)
        resetButton.setTitleColor(.gray128, for: .normal)
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        sectionHeader.addSubview(resetButton)
        resetButton.trailingAnchor.constraint(equalTo: sectionHeader.trailingAnchor, constant: -20).isActive = true
        resetButton.centerYAnchor.constraint(equalTo: sectionHeader.centerYAnchor).isActive = true
        
        
        let upperLine = UIView()
        upperLine.backgroundColor = .gray230
        upperLine.translatesAutoresizingMaskIntoConstraints = false
        sectionHeader.addSubview(upperLine)
        upperLine.leadingAnchor.constraint(equalTo: sectionHeader.leadingAnchor).isActive = true
        upperLine.trailingAnchor.constraint(equalTo: sectionHeader.trailingAnchor).isActive = true
        upperLine.topAnchor.constraint(equalTo: sectionHeader.topAnchor).isActive = true
        upperLine.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        let underLine = UIView()
        underLine.backgroundColor = .gray230
        underLine.translatesAutoresizingMaskIntoConstraints = false
        sectionHeader.addSubview(underLine)
        underLine.leadingAnchor.constraint(equalTo: sectionHeader.leadingAnchor).isActive = true
        underLine.trailingAnchor.constraint(equalTo: sectionHeader.trailingAnchor).isActive = true
        underLine.bottomAnchor.constraint(equalTo: sectionHeader.bottomAnchor).isActive = true
        underLine.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        
        
        return sectionHeader
    }
}

extension PRepsViewController: PRepSearchDelegate {
    var prepList: [PRepListResponse.PReps] {
        if let list = preps?.preps {
            return list
        }
        
        return []
    }
}
