//
//  InputDataViewController.swift
//  iconex_ios
//
//  Created by Seungyeon Lee on 2019/09/01.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import PanModal

enum InputType {
    case utf8, hex
}

class InputDataViewController: BaseViewController {
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var confirmButton: UIButton!
    
    @IBOutlet weak var placeholderLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    
    var type: InputType = .utf8
    var data: String = ""
    
    var isEditMode: Bool = false
    var isEditingMode: Bool = false
    
    var completeHandler: ((_ data: String, _ dataType: InputType) -> Void)?
    
    var delegate: SendDelegate!
    
    let toolBar: IXKeyboardToolBar = IXKeyboardToolBar(frame: CGRect(x: 0, y: 0, width: .max, height: 102))

    override func viewDidLoad() {
        super.viewDidLoad()
        
        toolBar.dataType = self.type
        self.textView.inputAccessoryView = toolBar
        
        if !self.data.isEmpty {
            self.textView.text = self.data
        }
        
        if self.isEditMode {
            self.textView.isUserInteractionEnabled = false
        }
        
        setupUI()
        setupBind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.data.isEmpty {
            textView.becomeFirstResponder()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        textView.endEditing(true)
    }
    
    private func setupUI() {
        titleLabel.size18(text: "Send.DataType.Title".localized, color: .gray77, weight: .medium, align: .center)
        
        confirmButton.isHidden = data.isEmpty
        confirmButton.setTitle("Common.Change".localized, for: .normal)
        
        if self.type == .utf8 {
            self.placeholderLabel.text = "Hello ICON"
        } else {
            self.placeholderLabel.text = "0x1234…"
        }
    }
    
    private func setupBind() {
        closeButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                if self.textView.text.isEmpty {
                   self.dismiss(animated: true, completion: nil)
                } else {
                    Alert.basic(title: "Send.InputData.Alert.Cancel".localized, isOnlyOneButton: false, confirmAction: {
                        self.dismiss(animated: true, completion: nil)
                    }).show()
                }
        }.disposed(by: disposeBag)
        
        let textViewShare = textView.rx.text.orEmpty.share(replay: 1)
        
        textViewShare
            .subscribe(onNext: { (text) in
                self.placeholderLabel.isHidden = !text.isEmpty
                let textLength = text.utf8.count
                self.toolBar.kbLabel.text = "\(textLength)"
                
                if textLength >= 512 {
                    self.textView.text = String(text.utf8.prefix(513))
                }
                
            }).disposed(by: disposeBag)
        
        textViewShare.map { !$0.isEmpty }
            .bind(to: self.toolBar.completeButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        toolBar.completeButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                let text = self.textView.text ?? ""
                if let handler = self.completeHandler {
                    handler(text, self.type)
                }
                self.dismiss(animated: true, completion: nil)
            }.disposed(by: disposeBag)
        
        confirmButton.rx.tap.asControlEvent()
            .subscribe { (_) in
                if self.isEditingMode {
                    self.textView.text = ""
                }
                self.textView.isUserInteractionEnabled = true
                self.textView.becomeFirstResponder()
                self.isEditingMode = true
                self.confirmButton.setTitle("Common.Remove".localized, for: .normal)
                
        }.disposed(by: disposeBag)
    }
}

extension InputDataViewController: PanModalPresentable {
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
